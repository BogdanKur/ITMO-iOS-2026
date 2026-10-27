# Защита лабы 2: Два экрана и случайная рекомендация

**Ignatev Alexey · K4140**

## Начало рассказа

> «На первом экране есть текст и две кнопки. Генератор выдаёт число от 1 до 100, а вторая кнопка открывает карточку сериала из локального каталога. Число определяет индекс рекомендации.»

Сначала покажи дерево проекта. Во время показа каждого файла говори по разделам ниже: назначение → ключевые методы → почему такое решение. Для подробного рассказа ставь видео на паузу. Нижних титров в ролике нет.

## Что показать в приложении

Сгенерировать число несколько раз, показать изменение текста, открыть рекомендацию и прокрутить описание. Вернуться системной кнопкой. Объяснить, что индекс выбирается по модулю длины локального каталога.

## Файл `project.yml` — Конфигурация сборки

### Что говорить

> «XcodeGen создаёт проект из декларативного описания. targets задают приложение и отдельные модули тестов; scheme определяет сборку и запуск XCTest. Sources и Resources включены в приложение; JSON и постеры копируются в bundle. CODE_SIGNING_ALLOWED=NO нужен для симулятора. Для физического iPhone потребуется настроить подпись своим Team. В 6–7 Alamofire подключён через Swift Package Manager и закреплён на версии 5.10.2.»

### Почему так / ответ на вопрос

Почему project.yml? Проект можно воспроизводимо сгенерировать на другом Mac. Готовый .xcodeproj будет также приложен после облачной сборки.


## Файл `Sources/Data/LocalCatalog.swift` — Локальные данные

### Что говорить

> «Ищет catalog.json в Bundle.main и декодирует массив Show через JSONDecoder. Если ресурс отсутствует или повреждён, ошибка передаётся в точку входа и показывается отдельный экран.»

### Почему так / ответ на вопрос

В 2–5 это штатный источник каталога. В 6–7 он используется только при явном --ui-testing, чтобы UI-тесты были независимыми от внешнего API. В обычном запуске 6–7 каталог сетевой.


## Файл `Sources/Domain/Show.swift` — Предметные модели и правила

### Что говорить

> «Show — снимок сериала: id TVmaze, название, год, жанры, описание, длительность серии, рейтинг и источники. Codable нужен для локального JSON и сохранения, Equatable — для сравнений и task(id:), Sendable — для передачи снимков конкурентным задачам. В лабах 3+ LibraryEntry хранит личные данные отдельно от данных каталога. Его id равен show.id, поэтому один сериал соответствует одной записи. WatchStatus — enum допустимых статусов. EntryValidator проверяет оценку 0…10, серии 0…10000, комментарий до 2000 символов.»

### Почему так / ответ на вопрос

Оценка 0 означает «не выставлена» и не входит в среднее. Каталожный rating и personalRating различаются. addedAt сохраняется при редактировании, updatedAt обновляется. Статус «Просмотрено» выбирает пользователь; приложение не знает точное число выпущенных серий.


## Файл `Sources/Presentation/Components.swift` — Общие элементы интерфейса

### Что говорить

> «ShelfStyle задаёт акцентный цвет. PosterView сначала ищет локальный постер в asset catalogue, затем использует AsyncImage для сетевой картинки; при отсутствии показывает нейтральный placeholder. GeometryReader подстраивает изображение под размер, scaledToFill заполняет область, clipped обрезает выход за границы. ShowCard объединяет постер, название, год, жанр и рейтинг.»

### Почему так / ответ на вопрос

Отдельный компонент устраняет дублирование верстки. Рейтинг форматируется до одного знака. Изображение скрыто от accessibility, а карточка объединяет текст, чтобы не повторять голосом декоративные детали.


## Файл `Sources/Presentation/SerialShelfApp.swift` — Точка входа и создание зависимостей

### Что говорить

> «В лабе 2 WindowGroup создаёт RecommendationView. @State number хранит optional-число; Text выводит число или начальную подсказку. NavigationLink передаёт выбранный сериал. Индекс (number-1)%count остаётся в границах массива, пустой каталог проверяется отдельно. В 3+ точка входа создаёт SettingsStore и LibraryViewModel через @StateObject, загружает локальные ресурсы и выбирает репозиторий. RootView организует вкладки через TabView и отдельные NavigationStack.»

### Почему так / ответ на вопрос

StateObject владеет объектом для данной идентичности SwiftUI-представления. Ошибка открытия ресурсов/базы показывает экран ошибки, а не выдаётся за успешно сохранённые данные. В 3 память, в 4+ SwiftData и UserDefaults. В 6+ обычный каталог RemoteCatalogView; --ui-testing явно выбирает LocalCatalog.


## Файл `Tests/RecommendationTests.swift` — Проверки второй лабы

### Что говорить

> «Проверка диапазона генератора на 1000 значениях и Codable round-trip модели Show.»

### Почему так / ответ на вопрос

Проверка диапазона не доказывает равномерность случайного распределения. Round-trip проверяет сохранение optional-полей при encode/decode.


## Частые вопросы по всей работе

- **Где минимум четыре экрана?** Каталог, карточка сериала, моя полка, детали записи, редактор и настройки; с лабы 5 — статистика.
- **Какие паттерны?** MVVM, Repository, Dependency Injection. Создание зависимостей — в SerialShelfApp.
- **Почему struct для данных, class для ViewModel?** Данные передаются значениями; экраны наблюдают один объект состояния.
- **Почему @StateObject и @ObservedObject?** Первый используется в месте создания владельца, второй — для уже переданного объекта.
- **Где два хранилища?** SwiftData для коллекции и UserDefaults для настройки сортировки/темы.
- **Где две фоновые операции?** AnalysisViewModel.search и calculate.
- **Где GET и POST?** CatalogAPI.shows отправляет GET в TVmaze; sendReview — POST в JSONPlaceholder.
- **Платные ключи нужны?** Нет. Оба сервиса доступны без API-ключа.
- **Где unit и UI?** Tests содержит изолированные проверки; UITests в лабе 7 — два сценария настоящего приложения.
- **На Windows можно запустить SwiftUI iPhone-приложение?** Нет, здесь можно читать исходники и смотреть видео. Сборка/Simulator выполняются на Mac. Облачные артефакты содержат готовый Xcode-проект и приложение для симулятора.
- **Зелёные тесты гарантируют отсутствие любых ошибок?** Нет, они подтверждают конкретные проверенные сценарии.

## Приложение: весь код для подготовки

### project.yml

```yaml
name: SerialShelf
options:
  bundleIdPrefix: edu.itmo.ignatev.lab2
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    SWIFT_VERSION: "5.0"
    CODE_SIGNING_ALLOWED: NO
    GENERATE_INFOPLIST_FILE: YES
    TARGETED_DEVICE_FAMILY: "1,2"
    INFOPLIST_KEY_UILaunchScreen_Generation: YES
    INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
targets:
  SerialShelf:
    type: application
    platform: iOS
    sources: [Sources, Resources]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: edu.itmo.ignatev.lab2.SerialShelf
      INFOPLIST_KEY_CFBundleDisplayName: СериалПолка 2
  SerialShelfTests:
    type: bundle.unit-test
    platform: iOS
    sources: [Tests]
    dependencies: [{target: SerialShelf}]
schemes:
  SerialShelf:
    build:
      targets:
        SerialShelf: all
    test:
      gatherCoverageData: true
      targets: [SerialShelfTests]
```

### Sources/Data/LocalCatalog.swift

```swift
import Foundation

enum LocalCatalog {
    static func load(bundle: Bundle = .main) throws -> [Show] {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Show].self, from: Data(contentsOf: url))
    }
}
```

### Sources/Domain/Show.swift

```swift
import Foundation

struct Show: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let year: String
    let genres: [String]
    let summary: String
    let runtime: Int
    let rating: Double?
    let imageURL: String?
    let sourceURL: String
}
```

### Sources/Presentation/Components.swift

```swift
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
```

### Sources/Presentation/SerialShelfApp.swift

```swift
import SwiftUI

@main struct SerialShelfApp: App {
    var body: some Scene { WindowGroup { RecommendationView().preferredColorScheme(.dark).tint(ShelfStyle.accent) } }
}

struct RecommendationView: View {
    @State private var number: Int?
    private let shows = (try? LocalCatalog.load()) ?? []
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "popcorn.fill").font(.system(size: 74)).foregroundStyle(ShelfStyle.accent)
                Text("Что посмотрим\nсегодня?").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text(number.map { "Твой номер: \($0)" } ?? "Выбери случайную рекомендацию")
                    .foregroundStyle(.secondary).accessibilityIdentifier("numberLabel")
                Button("Случайное число") { number = NumberGenerator.generate() }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("generateButton")
                NavigationLink("Открыть рекомендацию") {
                    RecommendationDetail(show: shows.isEmpty ? nil : shows[((number ?? 1)-1) % shows.count])
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

enum NumberGenerator { static func generate() -> Int { Int.random(in: 1...100) } }
```

### Tests/RecommendationTests.swift

```swift
import XCTest
@testable import SerialShelf
final class RecommendationTests: XCTestCase {
    func testRandomNumberRange() { for _ in 0..<1000 { XCTAssertTrue((1...100).contains(NumberGenerator.generate())) } }
    func testShowRoundTrip() throws {
        let value = Show(id: 1, name: "Test", year: "2020", genres: [], summary: "", runtime: 45,
            rating: nil, imageURL: nil, sourceURL: "https://www.tvmaze.com")
        XCTAssertEqual(try JSONDecoder().decode(Show.self, from: JSONEncoder().encode(value)), value)
    }

}
```

