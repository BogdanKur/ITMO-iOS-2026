import SwiftUI

struct AnalysisView: View {
    let entries: [LibraryEntry]
    @StateObject private var model = AnalysisViewModel()
    @State private var query = ""
    private struct SearchInput: Equatable { let entries: [LibraryEntry]
        let query: String
    }

    var body: some View {
        List {
            Section("Твой просмотр") {
                if model.calculating {
                    ProgressView("Подсчёт…")
                }
                if let value = model.statistics {
                    LabeledContent("На полке", value: String(value.total))
                    LabeledContent("Завершено", value: String(value.finished))
                    LabeledContent("Просмотрено минут ≈", value: String(value.minutes))
                    LabeledContent(
                        "Средняя оценка",
                        value: value.average.map {
                            String(format: "%.1f", $0)
                        } ?? "Нет оценок"
                    )
                }
                Text("Время — оценка по числу просмотренных серий и средней длительности серии.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Поиск по моей коллекции") {
                if model.searching {
                    ProgressView()
                }
                ForEach(model.matches) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.show.name).font(.headline)
                        Text(entry.status.rawValue).foregroundStyle(.secondary)
                    }
                }
                if !model.searching, model.matches.isEmpty {
                    Text("Ничего не найдено")
                }
            }
        }.navigationTitle("Статистика")
            .searchable(text: $query, prompt: "Сериал или комментарий")
            .task(id: entries) {
                await model.calculate(entries)
            }
            .task(id: SearchInput(entries: entries, query: query)) {
                await model.search(entries, query: query)
            }
    }
}
