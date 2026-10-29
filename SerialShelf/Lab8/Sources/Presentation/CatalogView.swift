import SwiftUI

struct CatalogView: View {
    @ObservedObject var library: LibraryViewModel
    let shows: [Show]
    @State private var query = ""
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private var filtered: [Show] {
        shows.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("НАЙДИ СВОЮ ИСТОРИЮ").font(.caption.bold()).foregroundStyle(ShelfStyle.accent)
                    Text("Хороший вечер\nначинается здесь").font(.largeTitle.bold())
                    Text("Сохраняй сериалы и следи за просмотром.").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(filtered) { show in
                        NavigationLink {
                            ShowDetailView(show: show, library: library)
                        } label: { ShowCard(show: show) }.buttonStyle(.plain)
                            .accessibilityIdentifier("show-\(show.id)")
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                Text("Данные: TVmaze · CC BY-SA").font(.caption).foregroundStyle(.secondary)
            }.padding()
        }
        .navigationTitle("СериалПолка")
        .searchable(text: $query, prompt: "Название сериала")
    }
}
