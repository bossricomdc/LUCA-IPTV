import Foundation
import UIKit

private struct AnyEncodable: Encodable {
    let encodeBlock: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { encodeBlock = value.encode }
    func encode(to encoder: Encoder) throws { try encodeBlock(encoder) }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida."
        case .invalidResponse: return "Resposta inválida do servidor."
        case .server(let message): return message
        case .decoding: return "Não foi possível interpretar a resposta do servidor."
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let panelBase = "https://lucaiptv.infinityfree.me/painel/"

    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1",
            "Accept": "application/json, text/plain, */*"
        ]
        return URLSession(configuration: config)
    }

    private func request<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = obj["mensagem"] as? String {
                throw APIError.server(msg)
            }
            throw APIError.server("Erro HTTP \(http.statusCode).")
        }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.decoding }
    }

    func login(user: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: panelBase + "api/app/login.php") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let device = UIDeviceIdentifier.current
        let form = ["usuario": user, "senha": password, "mac_address": device]
        req.httpBody = form.map { key, value in
            "\(key.urlEncoded)=\(value.urlEncoded)"
        }.joined(separator: "&").data(using: .utf8)
        return try await request(req, as: LoginResponse.self)
    }

    func verify() async throws -> VerifyResponse {
        let token = defaults.string(forKey: "auth_token") ?? ""
        var components = URLComponents(string: panelBase + "api/app/verify.php")!
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await request(req, as: VerifyResponse.self)
    }

    func fetchXtreamCredentials() async throws -> Bool {
        let token = defaults.string(forKey: "auth_token") ?? ""
        var components = URLComponents(string: panelBase + "api/app/lista.php")!
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let list = try await request(req, as: ListaResponse.self)
        guard list.sucesso, let server = list.servidor, let user = list.usuario else {
            throw APIError.server(list.mensagem ?? "Lista IPTV não configurada.")
        }
        defaults.set(cleanServer(server), forKey: "xtream_server")
        defaults.set(user, forKey: "xtream_user")
        defaults.set(list.senha ?? "", forKey: "xtream_pass")

        if let auth: XtreamAuth = try? await get(authURL(), as: XtreamAuth.self),
           let serverInfo = auth.serverInfo, let actual = serverInfo.url, !actual.isEmpty {
            let final = cleanServer(actual, port: serverInfo.port)
            defaults.set(final, forKey: "xtream_server")
        }
        return true
    }

    func categories(kind: MediaEntry.Kind) async throws -> [XtreamCategory] {
        let action: String
        switch kind {
        case .live: action = "get_live_categories"
        case .movie: action = "get_vod_categories"
        case .series: action = "get_series_categories"
        case .episode: return []
        }
        return try await get(apiURL(action: action), as: [XtreamCategory].self)
    }

    func live(categoryId: String) async throws -> [MediaEntry] {
        let rows: [XtreamStream] = try await get(apiURL(action: "get_live_streams", categoryId: categoryId), as: [XtreamStream].self)
        return rows.map { item in
            MediaEntry(id: "live-\(item.streamId)", title: item.name, imageURL: item.streamIcon, streamURL: liveStreamURL(item.streamId), kind: .live, categoryName: "", seriesId: nil)
        }
    }

    func movies(categoryId: String) async throws -> [MediaEntry] {
        let rows: [XtreamVod] = try await get(apiURL(action: "get_vod_streams", categoryId: categoryId), as: [XtreamVod].self)
        return rows.map { item in
            let ext = (item.containerExtension?.isEmpty == false ? item.containerExtension! : "mp4")
            return MediaEntry(id: "vod-\(item.streamId)", title: item.name, imageURL: item.streamIcon, streamURL: movieStreamURL(item.streamId, ext: ext), kind: .movie, categoryName: "", seriesId: nil)
        }
    }

    func series(categoryId: String) async throws -> [MediaEntry] {
        let rows: [XtreamSeries] = try await get(apiURL(action: "get_series"), as: [XtreamSeries].self)
        return rows.filter { $0.categoryId == categoryId }.map { item in
            MediaEntry(id: "series-\(item.seriesId)", title: item.name, imageURL: item.cover, streamURL: nil, kind: .series, categoryName: "", seriesId: item.seriesId)
        }
    }

    func seriesInfo(seriesId: Int) async throws -> SeriesInfoResponse {
        return try await get(apiURL(action: "get_series_info", seriesId: seriesId), as: SeriesInfoResponse.self)
    }

    func episodeURL(_ episode: SeriesEpisode) -> String {
        episodeStreamURL(episode.id, ext: episode.containerExtension ?? "mp4")
    }

    private func get<T: Decodable>(_ urlString: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        return try await request(URLRequest(url: url), as: type)
    }

    private var credentials: (server: String, user: String, pass: String) {
        (defaults.string(forKey: "xtream_server") ?? "http://voxplayer.shop",
         defaults.string(forKey: "xtream_user") ?? "",
         defaults.string(forKey: "xtream_pass") ?? "")
    }

    private func authURL() -> String { apiURL(action: nil) }

    private func apiURL(action: String?, categoryId: String? = nil, seriesId: Int? = nil) -> String {
        let c = credentials
        var comp = URLComponents(string: c.server + "/player_api.php")!
        var q = [URLQueryItem(name: "username", value: c.user), URLQueryItem(name: "password", value: c.pass)]
        if let action { q.append(URLQueryItem(name: "action", value: action)) }
        if let categoryId { q.append(URLQueryItem(name: "category_id", value: categoryId)) }
        if let seriesId { q.append(URLQueryItem(name: "series_id", value: String(seriesId))) }
        comp.queryItems = q
        return comp.url!.absoluteString
    }

    private func liveStreamURL(_ id: Int) -> String { let c = credentials; return "\(c.server)/live/\(c.user)/\(c.pass)/\(id).ts" }
    private func movieStreamURL(_ id: Int, ext: String) -> String { let c = credentials; return "\(c.server)/movie/\(c.user)/\(c.pass)/\(id).\(ext)" }
    private func episodeStreamURL(_ id: String, ext: String) -> String { let c = credentials; return "\(c.server)/series/\(c.user)/\(c.pass)/\(id).\(ext)" }

    private func cleanServer(_ raw: String, port: String? = nil) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !text.hasPrefix("http://") && !text.hasPrefix("https://") { text = "http://" + text }
        if let port, !port.isEmpty, port != "80", port != "443", !text.split(separator: ":").dropFirst(1).joined(separator: ":").contains(":") {
            text += ":\(port)"
        }
        return text
    }
}

private extension String {
    var urlEncoded: String { addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&=?"))) ?? self }
}

enum UIDeviceIdentifier {
    static var current: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
