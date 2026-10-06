import SwiftUI
import AVKit

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var error: String?
    func start(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { error = "URL de reprodução inválida."; return }
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
    }
    func stop() { player?.pause(); player = nil }
}

struct PlayerView: View {
    let entry: MediaEntry
    @StateObject private var vm = PlayerViewModel()
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                if let player = vm.player {
                    VideoPlayer(player: player).aspectRatio(16/9, contentMode: .fit)
                } else if let error = vm.error {
                    ContentUnavailableView("Não foi possível reproduzir", systemImage: "play.slash", description: Text(error))
                } else { ProgressView() }
                Text(entry.title).font(.headline).padding(.horizontal)
                Spacer()
            }
        }
        .navigationTitle(entry.title).navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.start(urlString: entry.streamURL) }
        .onDisappear { vm.stop() }
    }
}
