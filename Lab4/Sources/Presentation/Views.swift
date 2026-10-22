import SwiftUI
struct RootView: View {
    @ObservedObject var model: NotesViewModel
    var body: some View {
        TabView {
            NavigationStack { NotesListView(model: model) }
                .tabItem { Label("Заметки", systemImage: "note.text") }


            NavigationStack { SettingsView() }.tabItem { Label("Настройки", systemImage: "gearshape") }
        }.tint(.indigo)
    }
}
struct NotesListView: View {
    @ObservedObject var model: NotesViewModel
    @EnvironmentObject private var settings: SettingsStore
    @State private var adding = false
    var ordered: [Note] { settings.newestFirst ? model.notes : Array(model.notes.reversed()) }
    var body: some View {
        List {
            if model.notes.isEmpty {
                ContentUnavailableView("Пока нет заметок", systemImage: "note.text.badge.plus",
                    description: Text("Нажми +, чтобы добавить первую заметку."))
            }
            ForEach(ordered) { note in
                NavigationLink { NoteDetailView(model: model, id: note.id) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(note.title).font(.headline)
                        Text(note.body).lineLimit(2).foregroundStyle(.secondary)
                        Text(note.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                }.swipeActions { Button("Удалить", role: .destructive) { model.delete(note) } }
            }
        }.navigationTitle("StudyNotes")
        .toolbar { Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Добавить заметку") }
        .sheet(isPresented: $adding) { NavigationStack { NoteEditorView(model: model, note: nil) } }
        .alert("Не удалось выполнить действие", isPresented: Binding(get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } })) { Button("OK") { model.errorMessage = nil } }
            message: { Text(model.errorMessage ?? "") }
    }
}
struct NoteDetailView: View {
    @ObservedObject var model: NotesViewModel
    let id: UUID
    @State private var editing = false
    var body: some View {
        Group {
            if let note = model.notes.first(where: { $0.id == id }) {
                ScrollView { VStack(alignment: .leading, spacing: 18) {
                    Text(note.title).font(.largeTitle.bold())
                    Text(note.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                    Text(note.body).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                }.padding() }
                .toolbar { Button("Изменить") { editing = true } }
                .sheet(isPresented: $editing) { NavigationStack { NoteEditorView(model: model, note: note) } }
            } else { ContentUnavailableView("Заметка удалена", systemImage: "trash") }
        }.navigationTitle("Заметка").navigationBarTitleDisplayMode(.inline)
    }
}
struct NoteEditorView: View {
    @ObservedObject var model: NotesViewModel
    let note: Note?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var bodyText: String
    @State private var failure: String?
    init(model: NotesViewModel, note: Note?) {
        self.model = model; self.note = note
        _title = State(initialValue: note?.title ?? "")
        _bodyText = State(initialValue: note?.body ?? "")
    }
    var body: some View {
        Form {
            TextField("Название", text: $title).accessibilityIdentifier("noteTitle")
            Section("Текст") { TextEditor(text: $bodyText).frame(minHeight: 220).accessibilityIdentifier("noteBody") }
            if let failure { Text(failure).foregroundStyle(.red) }
        }.navigationTitle(note == nil ? "Новая заметка" : "Редактирование")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Сохранить") {
                if model.save(id: note?.id, title: title, body: bodyText) { dismiss() }
                else { failure = model.errorMessage; model.errorMessage = nil }
            } }
        }
    }
}
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    var body: some View {
        Form {
            Toggle("Сначала новые", isOn: $settings.newestFirst)
            Section("О приложении") {
                Text("StudyNotes · Лабораторная 4")
                Text("SwiftUI · MVVM · Repository · Dependency Injection")
                Text("Заметки хранятся в SwiftData, порядок сортировки — в UserDefaults. ")
            }
        }.navigationTitle("Настройки")
    }
}
