import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        Group {
            if session.isLoggedIn { MainView() }
            else { LoginView() }
        }
        .task { await session.verifySession() }
    }
}

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State private var user = UserDefaults.standard.string(forKey: "saved_user") ?? ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                HStack(spacing: 0) {
                    Text("LUCA").foregroundStyle(.white)
                    Text("IPTV").foregroundStyle(.blue)
                }
                .font(.system(size: 38, weight: .black))
                Text("Entre com sua conta").foregroundStyle(.secondary)

                TextField("Usuário", text: $user)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .padding().background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                SecureField("Senha", text: $password)
                    .padding().background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                if let error = session.errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    UserDefaults.standard.set(user.trimmingCharacters(in: .whitespaces), forKey: "saved_user")
                    Task { await session.login(user: user, password: password) }
                } label: {
                    Group {
                        if session.isBusy { ProgressView().tint(.white) }
                        else { Text("Entrar").fontWeight(.bold) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                }
                .buttonStyle(.borderedProminent).disabled(user.isEmpty || password.isEmpty || session.isBusy)
                Spacer()
            }
            .padding(28)
            .frame(maxWidth: 520)
        }
    }
}
