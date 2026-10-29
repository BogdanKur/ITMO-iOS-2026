import SwiftUI

enum ShelfStyle {
    static let accent = Color(red: 1, green: 0.68, blue: 0.25)
    static let background = Color(red: 0.055, green: 0.065, blue: 0.095)
}

struct PosterView: View {
    let show: Show
    var body: some View {
        GeometryReader { size in
            Group {
                if let local = UIImage(named: "poster-\(show.id)") {
                    Image(uiImage: local).resizable().scaledToFill()
                } else if let address = show.imageURL, let url = URL(string: address) {
                    AsyncImage(url: url) { image in image.resizable().scaledToFill() }
                        placeholder: { placeholder }
                } else {
                    placeholder
                }
            }
            .frame(width: size.size.width, height: size.size.height).clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "tv").font(.largeTitle).foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct ShowCard: View {
    let show: Show
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PosterView(show: show).frame(height: 224)
                .overlay(alignment: .topTrailing) {
                    if let rating = show.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.caption.bold()).padding(7).background(.black.opacity(0.8), in: Capsule()).padding(8)
                    }
                }
            Text(show.name).font(.headline).lineLimit(2).foregroundStyle(.primary)
            Text(show.year + " · " + (show.genres.first ?? "Сериал"))
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
