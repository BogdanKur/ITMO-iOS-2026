import SwiftUI

@main struct SerialShelfApp: App {
    var body: some Scene {
        WindowGroup {
            RecommendationView().preferredColorScheme(.dark).tint(ShelfStyle.accent)
        }
    }
}

struct RecommendationView: View {
    @State private var number: Int?
    private let shows = (try? LocalCatalog.load()) ?? []
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "popcorn.fill").font(.system(size: 74)).foregroundStyle(ShelfStyle.accent)
                Text("Что посмотрим\nсегодня?").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text(number.map {
                    "Твой номер: \($0)"
                } ?? "Выбери случайную рекомендацию")
                    .foregroundStyle(.secondary).accessibilityIdentifier("numberLabel")
                Button("Случайное число") {
                    number = NumberGenerator.generate()
                }
                .buttonStyle(.borderedProminent).accessibilityIdentifier("generateButton")
                NavigationLink("Открыть рекомендацию") {
                    RecommendationDetail(show: shows.isEmpty ? nil : shows[((number ?? 1) - 1) % shows.count])
                }.buttonStyle(.bordered).accessibilityIdentifier("recommendationLink")
            }.padding().navigationTitle("СериалПолка")
        }
    }
}

struct RecommendationDetail: View {
    let show: Show?
    var body: some View {
        ScrollView {
            if let show {
                VStack(alignment: .leading, spacing: 20) {
                    PosterView(show: show).frame(height: 340)
                    Text(show.name).font(.largeTitle.bold())
                    Text(show.year + " · " + show.genres.joined(separator: " / ")).foregroundStyle(ShelfStyle.accent)
                    Text(show.summary).foregroundStyle(.secondary)
                }.padding()
            } else { ContentUnavailableView("Каталог недоступен", systemImage: "tv") }
        }.navigationTitle("Рекомендация").navigationBarTitleDisplayMode(.inline)
    }
}

enum NumberGenerator { static func generate() -> Int {
    Int.random(in: 1 ... 100)
} }
