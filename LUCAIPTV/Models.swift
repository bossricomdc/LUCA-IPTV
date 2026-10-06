import Foundation

enum ContentKind: String, CaseIterable, Identifiable {
    case home = "Início"
    case movies = "Filmes"
    case series = "Séries"
    case sports = "Esportes"
    case channels = "Canais"
    case search = "Busca"
    var id: String { rawValue }
}

struct IPTVData: Codable {
    let id: Int
    let userXtream: String
    let passXtream: String
    let expiracao: String?
    let status: Int
    let planoNome: String?
    let dias: Int?
    let conexoes: Int?
    let mac: String?

    enum CodingKeys: String, CodingKey {
        case id, expiracao, status, dias, conexoes, mac
        case userXtream = "user_xtream"
        case passXtream = "pass_xtream"
        case planoNome = "plano_nome"
    }
}

struct LoginResponse: Codable {
    let sucesso: Bool
    let mensagem: String
    let token: String?
    let id: Int?
    let usuario: String?
    let tipo: Int?
    let iptv: IPTVData?
}

struct VerifyResponse: Codable {
    let sucesso: Bool
    let mensagem: String?
    let id: Int?
    let usuario: String?
    let tipo: Int?
    let iptv: IPTVData?
}

struct ListaResponse: Codable {
    let sucesso: Bool
    let mensagem: String?
    let m3uUrl: String?
    let servidor: String?
    let usuario: String?
    let senha: String?

    enum CodingKeys: String, CodingKey {
        case sucesso, mensagem, servidor, usuario, senha
        case m3uUrl = "m3u_url"
    }
}

struct XtreamUserInfo: Codable {
    let username: String?
    let password: String?
    let auth: Int?
    let status: String?
    let expDate: String?
    let maxConnections: String?
    enum CodingKeys: String, CodingKey {
        case username, password, auth, status
        case expDate = "exp_date"
        case maxConnections = "max_connections"
    }
}

struct XtreamServerInfo: Codable {
    let url: String?
    let port: String?
    let httpsPort: String?
    enum CodingKeys: String, CodingKey {
        case url, port
        case httpsPort = "https_port"
    }
}

struct XtreamAuth: Codable {
    let userInfo: XtreamUserInfo?
    let serverInfo: XtreamServerInfo?
    enum CodingKeys: String, CodingKey {
        case userInfo = "user_info"
        case serverInfo = "server_info"
    }
}

struct XtreamCategory: Codable, Hashable, Identifiable {
    let categoryId: String
    let categoryName: String
    var id: String { categoryId }
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
    }
}

struct XtreamStream: Codable, Identifiable {
    let streamId: Int
    let name: String
    let streamIcon: String?
    let categoryId: String?
    let streamType: String?
    var id: Int { streamId }
    enum CodingKeys: String, CodingKey {
        case name
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        case streamType = "stream_type"
    }
}

struct XtreamVod: Codable, Identifiable {
    let streamId: Int
    let name: String
    let streamIcon: String?
    let categoryId: String?
    let rating: String?
    let containerExtension: String?
    var id: Int { streamId }
    enum CodingKeys: String, CodingKey {
        case name, rating
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        case containerExtension = "container_extension"
    }
}

struct XtreamSeries: Codable, Identifiable {
    let seriesId: Int
    let name: String
    let cover: String?
    let categoryId: String?
    var id: Int { seriesId }
    enum CodingKeys: String, CodingKey {
        case name, cover
        case seriesId = "series_id"
        case categoryId = "category_id"
    }
}

struct SeriesInfoResponse: Codable {
    let info: SeriesInfo?
    let episodes: [String: [SeriesEpisode]]?
}

struct SeriesInfo: Codable {
    let name: String?
    let cover: String?
    let plot: String?
    let genre: String?
    let rating: String?
}

struct SeriesEpisode: Codable, Identifiable {
    let id: String
    let episodeNum: Int?
    let title: String?
    let containerExtension: String?
    let info: EpisodeInfo?
    enum CodingKeys: String, CodingKey {
        case id, title, info
        case episodeNum = "episode_num"
        case containerExtension = "container_extension"
    }
}

struct EpisodeInfo: Codable {
    let movieImage: String?
    let plot: String?
    let duration: String?
    enum CodingKeys: String, CodingKey {
        case plot, duration
        case movieImage = "movie_image"
    }
}

struct MediaEntry: Identifiable, Hashable {
    enum Kind: Hashable { case live, movie, series, episode }
    let id: String
    let title: String
    let imageURL: String?
    let streamURL: String?
    let kind: Kind
    let categoryName: String
    let seriesId: Int?

    static func == (lhs: MediaEntry, rhs: MediaEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
