import SwiftUI

struct MainView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selection: ContentKind = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView().tabItem { Label("Início", systemImage: "house.fill") }.tag(ContentKind.home)
            CategoryBrowser(kind: .movie, title: "Filmes").tabItem { Label("Filmes", systemImage: "film.fill") }.tag(ContentKind.movies)
            CategoryBrowser(kind: .series, title: "Séries").tabItem { Label("Séries", systemImage: "tv.fill") }.tag(ContentKind.series)
            CategoryBrowser(kind: .live, title: "Canais").tabItem { Label("Canais", systemImage: "dot.radiowaves.left.and.right") }.tag(ContentKind.channels)
            SettingsView().tabItem { Label("Ajustes", systemImage: "gearshape.fill") }.tag(ContentKind.search)
        }
        .tint(.blue)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LUCA IPTV").font(.largeTitle.bold())
                        Text("Escolha uma categoria para começar.").foregroundStyle(.secondary)
                    }
                    NavigationLink { CategoryBrowser(kind: .movie, title: "Filmes") } label: { HomeTile(title: "Filmes", icon: "film.stack.fill") }
                    NavigationLink { CategoryBrowser(kind: .series, title: "Séries") } label: { HomeTile(title: "Séries", icon: "rectangle.stack.fill") }
                    NavigationLink { CategoryBrowser(kind: .live, title: "Canais") } label: { HomeTile(title: "TV ao vivo", icon: "play.tv.fill") }
                }.padding()
            }
            .background(Color.black)
        }
    }
}

private struct HomeTile: View {
    let title: String
    let icon: String
    var body: some View {
        HStack { Image(systemName: icon).font(.title2); Text(title).font(.title3.bold()); Spacer(); Image(systemName: "chevron.right") }
            .padding().frame(maxWidth: .infinity, minHeight: 74).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
    }
}

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        NavigationStack {
            Form {
                Section("Conta") { LabeledContent("Usuário", value: session.username) }
                Section { Button("Sair", role: .destructive) { session.logout() } }
                Section("Sobre") { LabeledContent("Aplicativo", value: "LUCA IPTV iOS"); LabeledContent("Player", value: "AVPlayer") }
            }
            .navigationTitle("Ajustes")
        }
    }
}
