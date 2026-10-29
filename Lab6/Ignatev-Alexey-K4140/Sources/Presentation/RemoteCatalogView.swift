import SwiftUI

struct RemoteCatalogView: View {
    @ObservedObject var library: LibraryViewModel
    @StateObject private var model = RemoteCatalogViewModel()
    @State private var query = ""
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ОТКРОЙ НОВУЮ ИСТОРИЮ").font(.caption.bold()).foregroundStyle(ShelfStyle.accent)
                Text("Что посмотрим?").font(.largeTitle.bold())
                Text("Каталог TVmaze · без регистрации").foregroundStyle(.secondary)
                if model.loading {
                    ProgressView("Загружаем сериалы…").frame(maxWidth: .infinity)
                }
                if let error = model.error {
                    ContentUnavailableView("Не удалось загрузить каталог", systemImage: "wifi.exclamationmark",
                                           description: Text(error))
                    Button("Повторить GET") {
                        Task {
                            await model.load(query: query)
                        }
                    }
                    .buttonStyle(.bordered)
                    Text("Локальная коллекция доступна на вкладке «Моя полка».").font(.caption)
                }
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(model.shows) { show in
                        NavigationLink {
                            ShowDetailView(show: show, library: library)
                        }
                        label: {
                            ShowCard(show: show)
                        }.buttonStyle(.plain)
                        .accessibilityIdentifier("show-\(show.id)")
                    }
                }
                if model.loaded && !model.loading && model.error == nil && model.shows.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                Link("Данные и изображения: TVmaze · CC BY-SA", destination: URL(string: "https://www.tvmaze.com/api")!)
                    .font(.caption)
            }.padding()
        }.navigationTitle("СериалПолка")
            .searchable(text: $query, prompt: "Например, Breaking Bad")
            .task(id: query) {
                await model.load(query: query)
            }
            .refreshable {
                await model.load(query: query)
            }
    }
}

struct ReviewSendView: View {
    let show: Show
    @StateObject private var model = ReviewViewModel()
    @State private var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Отправить отзыв · POST").font(.title2.bold())
            Text(
                "Учебный сервер возвращает ответ, но не хранит отзыв. Личный комментарий сохраняется отдельно в коллекции."
            )
            .font(.caption).foregroundStyle(.secondary)
            TextField("Текст отзыва", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("networkReview")
            Button(model.sending ? "Отправка…" : "Отправить отзыв") {
                Task {
                    await model.send(show: show, text: text)
                }
            }.buttonStyle(.borderedProminent)
                .disabled(model.sending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text
                    .count > 2000)
                .accessibilityIdentifier("sendReview")
            if let receipt = model.receipt {
                Label("Ответ получен · id \(receipt.id)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green).accessibilityIdentifier("postReceipt")
            }
            if let error = model.error {
                Text(error).foregroundStyle(.red)
            }
        }
    }
}
