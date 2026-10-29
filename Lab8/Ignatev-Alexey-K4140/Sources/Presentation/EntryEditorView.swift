import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: LibraryViewModel
    @State private var draft: LibraryEntry
    @State private var error: String?

    init(entry: LibraryEntry, model: LibraryViewModel) {
        self.model = model
        _draft = State(initialValue: entry)
    }

    var body: some View {
        Form {
            Section(draft.show.name) {
                Picker("Статус", selection: $draft.status) {
                    ForEach(WatchStatus.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }.accessibilityIdentifier("watchStatus")
                Stepper("Оценка: \(draft.personalRating)/10", value: $draft.personalRating, in: 0 ... 10)
                    .accessibilityIdentifier("personalRating")
                Text("0 — оценка не выставлена").font(.caption).foregroundStyle(.secondary)
                Stepper("Серий: \(draft.watchedEpisodes)", value: $draft.watchedEpisodes, in: 0 ... 10000)
                    .accessibilityIdentifier("watchedEpisodes")
            }
            Section("Комментарий") {
                TextEditor(text: $draft.review).frame(minHeight: 130)
                    .accessibilityIdentifier("reviewEditor")
                Text("\(draft.review.count)/2000").font(.caption).foregroundStyle(.secondary)
            }
            if let error {
                Text(error).foregroundStyle(.red)
            }
        }
        .navigationTitle("Редактирование").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    if model.update(draft) {
                        dismiss()
                    } else {
                        error = model.errorMessage
                        model.errorMessage = nil
                    }
                }
            }
        }
    }
}
