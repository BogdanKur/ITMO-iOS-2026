import SwiftUI
import Combine
@MainActor final class PostsViewModel: ObservableObject {
    @Published private(set) var posts: [RemotePost] = []
    @Published private(set) var loading = false
    @Published private(set) var sending = false
    @Published var errorMessage: String?
    @Published var receipt: RemotePost?
    private let service: any PostsService
    init(service: any PostsService = APIClient()) { self.service = service }
    func load() async {
        guard !loading else { return }
        loading = true; errorMessage = nil
        defer { loading = false }
        do { posts = try await service.fetchPosts() }
        catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }
    func send(title: String, body: String) async {
        guard !sending else { return }
        sending = true; errorMessage = nil; receipt = nil
        defer { sending = false }
        do { receipt = try await service.createPost(title: title, body: body) }
        catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }
}
struct RemotePostsView: View {
    @StateObject private var model = PostsViewModel()
    @State private var title = ""
    @State private var bodyText = ""
    var body: some View {
        List {
            Section("Создать публикацию · POST") {
                Text("Учебный API возвращает результат POST, но не сохраняет публикации на сервере.")
                    .font(.caption).foregroundStyle(.secondary)
                TextField("Название", text: $title)
                TextField("Текст", text: $bodyText, axis: .vertical)
                Button(model.sending ? "Отправка…" : "Отправить") {
                    Task { await model.send(title: title, body: bodyText) }
                }.disabled(model.sending || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if let receipt = model.receipt {
                    Text("Получен ответ: id \(receipt.id), \(receipt.title)").foregroundStyle(.green)
                }
            }
            if let error = model.errorMessage {
                Section("Ошибка") { Text(error).foregroundStyle(.red); Button("Повторить GET") { Task { await model.load() } } }
            }
            Section("Публикации · GET") {
                if model.loading { ProgressView("Загрузка…") }
                ForEach(model.posts) { post in
                    NavigationLink {
                        ScrollView { VStack(alignment: .leading, spacing: 16) {
                            Text(post.title).font(.title.bold()); Text(post.body)
                        }.padding() }.navigationTitle("Публикация")
                    } label: { Text(post.title).lineLimit(2) }
                }
            }
        }.navigationTitle("Лента").task { await model.load() }
        .refreshable { await model.load() }
    }
}
