import SwiftUI
@main struct StudyNotesApp: App {
    var body: some Scene { WindowGroup { HomeView() } }
}
struct HomeView: View {
    @State private var number: Int?
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "dice.fill").font(.system(size: 64)).foregroundStyle(.indigo)
                Text(number.map(String.init) ?? "Нажми кнопку")
                    .font(.largeTitle).accessibilityIdentifier("numberLabel")
                Button("Случайное число") { number = NumberGenerator.generate() }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("generateButton")
                NavigationLink("На второй экран") { SecondView(number: number) }
                    .buttonStyle(.bordered)
            }.padding().navigationTitle("Лабораторная 2")
        }
    }
}
enum NumberGenerator { static func generate() -> Int { Int.random(in: 1...100) } }
struct SecondView: View {
    let number: Int?
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(.green)
            Text("Второй экран").font(.title)
            Text(number.map { "Полученное число: \($0)" } ?? "Число ещё не сгенерировано")
            Text("Вернуться можно кнопкой «Назад» в верхнем левом углу.").foregroundStyle(.secondary)
        }.padding().navigationTitle("Результат")
    }
}
