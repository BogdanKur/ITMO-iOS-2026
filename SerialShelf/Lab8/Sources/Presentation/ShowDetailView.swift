import SwiftUI

struct ShowDetailView: View {
    let show: Show
    @ObservedObject var library: LibraryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PosterView(show: show).frame(height: 330)
                Text(show.name).font(.largeTitle.bold())
                Text(show.year + " · " + show.genres.joined(separator: " / "))
                    .foregroundStyle(.secondary)
                HStack(spacing: 24) {
                    Label("\(show.runtime) мин / серия", systemImage: "clock")
                    if let rating = show.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                    }
                }.font(.subheadline).foregroundStyle(ShelfStyle.accent)
                Button {
                    library.add(show)
                } label: {
                    Label(
                        library.contains(show) ? "В коллекции" : "Буду смотреть",
                        systemImage: library.contains(show) ? "checkmark" : "plus"
                    )
                    .frame(maxWidth: .infinity).padding(7)
                }
                .buttonStyle(.borderedProminent).disabled(library.contains(show))
                .accessibilityIdentifier("addToLibrary")
                Text("О сериале").font(.title2.bold())
                Text(show.summary).foregroundStyle(.secondary).textSelection(.enabled)
                if let url = URL(string: show.sourceURL) {
                    Link("Информация на TVmaze ↗", destination: url).font(.footnote)
                }
                ReviewSendView(show: show)
            }.padding()
        }
        .navigationTitle("О сериале").navigationBarTitleDisplayMode(.inline)
    }
}
