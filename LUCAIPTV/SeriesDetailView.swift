import SwiftUI

@MainActor
final class SeriesViewModel: ObservableObject {
    @Published var response: SeriesInfoResponse?
    @Published var loading = false
    @Published var error: String?
    func load(id: Int) async {
        loading = true; defer { loading = false }
        do { response = try await APIClient.shared.seriesInfo(seriesId: id) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}

struct SeriesDetailView: View {
    let item: MediaEntry
    @StateObject private var vm = SeriesViewModel()
    var seasons: [(String, [SeriesEpisode])] {
        (vm.response?.episodes ?? [:]).sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(url: URL(string: vm.response?.info?.cover ?? item.imageURL ?? "")) { phase in
                        if case let .success(image) = phase { image.resizable().scaledToFill() } else { Color.white.opacity(0.08) }
                    }.frame(width: 130, height: 190).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.response?.info?.name ?? item.title).font(.title2.bold())
                        if let genre = vm.response?.info?.genre { Text(genre).foregroundStyle(.secondary) }
                        if let rating = vm.response?.info?.rating { Label(rating, systemImage: "star.fill") }
                    }
                }
                if let plot = vm.response?.info?.plot, !plot.isEmpty { Text(plot).foregroundStyle(.secondary) }
                if vm.loading { ProgressView("Carregando episódios…") }
                ForEach(seasons, id: \.0) { season, episodes in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Temporada \(season)").font(.title3.bold())
                        ForEach(episodes) { episode in
                            NavigationLink {
                                let e = MediaEntry(id: "ep-\(episode.id)", title: episode.title ?? "Episódio \(episode.episodeNum ?? 0)", imageURL: episode.info?.movieImage, streamURL: APIClient.shared.episodeURL(episode), kind: .episode, categoryName: item.title, seriesId: item.seriesId)
                                PlayerView(entry: e)
                            } label: {
                                HStack {
                                    Text("E\(episode.episodeNum ?? 0)").fontWeight(.bold).frame(width: 44, alignment: .leading)
                                    Text(episode.title ?? "Episódio").lineLimit(2)
                                    Spacer(); Image(systemName: "play.circle.fill")
                                }.padding(.vertical, 8).foregroundStyle(.white)
                            }
                            Divider()
                        }
                    }
                }
                if let error = vm.error { Text(error).foregroundStyle(.red) }
            }.padding()
        }
        .navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
        .task { if let id = item.seriesId { await vm.load(id: id) } }
    }
}
