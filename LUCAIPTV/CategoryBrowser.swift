import SwiftUI

@MainActor
final class CategoryViewModel: ObservableObject {
    @Published var categories: [XtreamCategory] = []
    @Published var loading = false
    @Published var error: String?
    let kind: MediaEntry.Kind
    init(kind: MediaEntry.Kind) { self.kind = kind }
    func load() async {
        loading = true; defer { loading = false }
        do { categories = try await APIClient.shared.categories(kind: kind) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}

struct CategoryBrowser: View {
    @StateObject private var vm: CategoryViewModel
    let title: String
    init(kind: MediaEntry.Kind, title: String) {
        _vm = StateObject(wrappedValue: CategoryViewModel(kind: kind)); self.title = title
    }
    var body: some View {
        NavigationStack {
            Group {
                if vm.loading && vm.categories.isEmpty { ProgressView("Carregando…") }
                else if let error = vm.error, vm.categories.isEmpty { ContentUnavailableView("Erro", systemImage: "wifi.exclamationmark", description: Text(error)) }
                else {
                    List(vm.categories) { category in
                        NavigationLink(category.categoryName) {
                            MediaGridView(kind: vm.kind, category: category)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .task { if vm.categories.isEmpty { await vm.load() } }
            .refreshable { await vm.load() }
        }
    }
}

@MainActor
final class MediaGridViewModel: ObservableObject {
    @Published var items: [MediaEntry] = []
    @Published var loading = false
    @Published var error: String?
    let kind: MediaEntry.Kind
    let category: XtreamCategory
    init(kind: MediaEntry.Kind, category: XtreamCategory) { self.kind = kind; self.category = category }
    func load() async {
        loading = true; defer { loading = false }
        do {
            switch kind {
            case .live: items = try await APIClient.shared.live(categoryId: category.categoryId)
            case .movie: items = try await APIClient.shared.movies(categoryId: category.categoryId)
            case .series: items = try await APIClient.shared.series(categoryId: category.categoryId)
            case .episode: items = []
            }
        } catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}

struct MediaGridView: View {
    @StateObject private var vm: MediaGridViewModel
    @State private var query = ""
    private let columns = [GridItem(.adaptive(minimum: 145), spacing: 14)]
    init(kind: MediaEntry.Kind, category: XtreamCategory) { _vm = StateObject(wrappedValue: MediaGridViewModel(kind: kind, category: category)) }
    var filtered: [MediaEntry] { query.isEmpty ? vm.items : vm.items.filter { $0.title.localizedCaseInsensitiveContains(query) } }
    var body: some View {
        Group {
            if vm.loading && vm.items.isEmpty { ProgressView("Carregando…") }
            else if let error = vm.error, vm.items.isEmpty { ContentUnavailableView("Erro", systemImage: "exclamationmark.triangle", description: Text(error)) }
            else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filtered) { item in
                            if item.kind == .series { NavigationLink { SeriesDetailView(item: item) } label: { MediaCard(item: item) } }
                            else { NavigationLink { PlayerView(entry: item) } label: { MediaCard(item: item) } }
                        }
                    }.padding()
                }
            }
        }
        .navigationTitle(vm.category.categoryName)
        .searchable(text: $query, prompt: "Buscar")
        .task { if vm.items.isEmpty { await vm.load() } }
        .refreshable { await vm.load() }
    }
}

struct MediaCard: View {
    let item: MediaEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: item.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: ZStack { Color.white.opacity(0.08); Image(systemName: item.kind == .live ? "play.tv" : "film") .font(.largeTitle).foregroundStyle(.secondary) }
                }
            }
            .frame(height: item.kind == .live ? 105 : 205).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
            Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(2)
        }
    }
}
