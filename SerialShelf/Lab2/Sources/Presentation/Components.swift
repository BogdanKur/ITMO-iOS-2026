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
                } else { placeholder }
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

