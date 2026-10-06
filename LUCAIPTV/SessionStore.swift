import Foundation
import UIKit

@MainActor
final class SessionStore: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var username = ""

    private let defaults = UserDefaults.standard
    private let api = APIClient.shared

    init() {
        username = defaults.string(forKey: "username") ?? ""
        isLoggedIn = !(defaults.string(forKey: "auth_token") ?? "").isEmpty
    }

    func login(user: String, password: String) async {
        guard !user.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let response = try await api.login(user: user.trimmingCharacters(in: .whitespaces), password: password)
            guard response.sucesso, let token = response.token else {
                throw APIError.server(response.mensagem)
            }
            defaults.set(token, forKey: "auth_token")
            defaults.set(response.id ?? -1, forKey: "user_id")
            defaults.set(response.usuario ?? user, forKey: "username")
            defaults.set(response.tipo ?? -1, forKey: "user_type")
            username = response.usuario ?? user
            _ = try await api.fetchXtreamCredentials()
            isLoggedIn = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Sem conexão com o servidor."
        }
    }

    func verifySession() async {
        guard isLoggedIn else { return }
        do {
            let result = try await api.verify()
            if !result.sucesso { logout() }
        } catch {
            // Mantém a sessão offline; a próxima chamada exibirá o erro de rede.
        }
    }

    func logout() {
        ["auth_token", "user_id", "username", "user_type", "xtream_server", "xtream_user", "xtream_pass"].forEach(defaults.removeObject)
        isLoggedIn = false
        username = ""
    }
}
