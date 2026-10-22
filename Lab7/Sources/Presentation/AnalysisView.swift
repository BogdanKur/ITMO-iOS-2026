import SwiftUI
struct AnalysisView: View {
    let notes: [Note]
    @State private var query = ""
    @StateObject private var model = AnalysisViewModel()
    private struct SearchInput: Equatable { let notes: [Note]; let query: String }
    var body: some View {
        List {
            Section("Статистика в фоне") {
                if model.calculating { ProgressView("Подсчёт…") }
                if let s = model.statistics {
                    LabeledContent("Заметок", value: String(s.noteCount))
                    LabeledContent("Слов", value: String(s.wordCount))
                    LabeledContent("Символов без разделителя", value: String(s.characterCount))
                }
            }
            Section("Поиск в фоне") {
                if model.searching { ProgressView() }
                ForEach(model.matches) { note in
                    VStack(alignment: .leading) { Text(note.title).font(.headline); Text(note.body).lineLimit(2) }
                }
                if !model.searching && model.matches.isEmpty { Text("Ничего не найдено") }
            }
            if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Анализ").searchable(text: $query, prompt: "Название или текст")
        .task(id: SearchInput(notes: notes, query: query)) { await model.search(notes: notes, query: query) }
        .task(id: notes) { await model.calculate(notes: notes) }
    }
}
