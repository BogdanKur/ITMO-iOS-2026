import SwiftUI

struct LibraryView: View {
    @ObservedObject var model: LibraryViewModel
    @EnvironmentObject private var settings: SettingsStore
    private var ordered: [LibraryEntry] {
        settings.newestFirst ? model.entries : Array(model.entries.reversed())
    }

    var body: some View {
        List {
            if model.entries.isEmpty {
                ContentUnavailableView("Твоя полка пока пуста", systemImage: "bookmark",
                                       description: Text("Открой каталог и выбери сериал на вечер."))
            }
            ForEach(ordered) { entry in
                NavigationLink {
                    EntryDetailView(id: entry.id, model: model)
                } label: {
                    HStack(spacing: 14) {
                        PosterView(show: entry.show).frame(width: 62, height: 90)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(entry.show.name).font(.headline)
                            Text(entry.status.rawValue).font(.subheadline).foregroundStyle(ShelfStyle.accent)
                            Text("Серий: \(entry.watchedEpisodes) · Оценка: \(entry.personalRating)/10")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 5)
                }.accessibilityIdentifier("entry-\(entry.id)")
                    .swipeActions {
                        Button("Удалить", role: .destructive) {
                            model.delete(id: entry.id)
                        }
                    }
            }
        }.navigationTitle("Моя полка")
    }
}

struct EntryDetailView: View {
    let id: Int
    @ObservedObject var model: LibraryViewModel
    @State private var editing = false
    var body: some View {
        Group {
            if let entry = model.entries.first(where: {
                $0.id == id
            }) {
                List {
                    Section {
                        Text(entry.show.name).font(.title.bold())
                        LabeledContent("Статус", value: entry.status.rawValue)
                        LabeledContent("Моя оценка", value: "\(entry.personalRating)/10")
                        LabeledContent("Просмотрено серий", value: String(entry.watchedEpisodes))
                    }
                    Section("Мой комментарий") {
                        Text(entry.review.isEmpty ? "Пока без комментария" : entry.review)
                            .accessibilityIdentifier("savedReview")
                    }
                    Section {
                        Text("Добавлено: " + entry.addedAt.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .toolbar {
                    Button("Изменить") {
                        editing = true
                    }
                }
                .sheet(isPresented: $editing) {
                    NavigationStack {
                        EntryEditorView(entry: entry, model: model)
                    }
                }
            } else { ContentUnavailableView("Запись удалена", systemImage: "trash") }
        }.navigationTitle("Мой сериал").navigationBarTitleDisplayMode(.inline)
    }
}
