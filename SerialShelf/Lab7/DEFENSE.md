# Защита лабы 7: Три unit-теста и два UI-теста

**Ignatev Alexey · K4140**

## Начало рассказа

> «В отдельном unit-target три метода проверяют LibraryViewModel: CRUD, границы валидации, ошибки и восстановление. Два UI-теста проверяют коллекцию и настройки после настоящего перезапуска приложения. Интернет в UI-тестах заменён явным локальным каталогом через аргумент --ui-testing; сама коллекция остаётся настоящей SwiftData.»

Сначала покажи дерево проекта. Во время показа каждого файла говори по разделам ниже: назначение → ключевые методы → почему такое решение. Для подробного рассказа ставь видео на паузу. Нижних титров в ролике нет.

## Что показать в приложении

Показать код трёх unit-методов и двух UI-методов; в симуляторе — изменение комментария и сохранение после перезапуска. Открыть отчёт пяти тестов. Объяснить, какие зависимости в unit подменены, а какие настоящие в UI.

## Файл `project.yml` — Конфигурация сборки

### Что говорить

> «XcodeGen создаёт проект из декларативного описания. targets задают приложение и отдельные модули тестов; scheme определяет сборку и запуск XCTest. Sources и Resources включены в приложение; JSON и постеры копируются в bundle. CODE_SIGNING_ALLOWED=NO нужен для симулятора. Для физического iPhone потребуется настроить подпись своим Team. В 6–7 Alamofire подключён через Swift Package Manager и закреплён на версии 5.10.2.»

### Почему так / ответ на вопрос

Почему project.yml? Проект можно воспроизводимо сгенерировать на другом Mac. Готовый .xcodeproj будет также приложен после облачной сборки.


## Файл `Sources/Data/LibraryRepository.swift` — Repository и контракт

### Что говорить

> «LibraryRepository описывает fetch, save и delete; методы могут бросать ошибку. @MainActor сохраняет одну область изоляции. MemoryLibraryRepository реализует контракт словарём [Int: LibraryEntry]. save по существующему ключу заменяет запись, delete удаляет её.»

### Почему так / ответ на вопрос

Протокол позволяет подменить хранилище без изменения ViewModel. В тестах используется память или управляемая ошибка; в приложении с лабы 4 — SwiftData. Memory не сохраняется после завершения процесса.


## Файл `Sources/Data/LocalCatalog.swift` — Локальные данные

### Что говорить

> «Ищет catalog.json в Bundle.main и декодирует массив Show через JSONDecoder. Если ресурс отсутствует или повреждён, ошибка передаётся в точку входа и показывается отдельный экран.»

### Почему так / ответ на вопрос

В 2–5 это штатный источник каталога. В 6–7 он используется только при явном --ui-testing, чтобы UI-тесты были независимыми от внешнего API. В обычном запуске 6–7 каталог сетевой.


## Файл `Sources/Data/SettingsStore.swift` — Наблюдаемые настройки

### Что говорить

> «ObservableObject публикует newestFirst и darkMode. didSet пишет изменение в переданный UserDefaults. register задаёт значения по умолчанию, не перезаписывая сохранённые. С defaults:nil в лабе 3 всё остаётся в памяти; с .standard в 4+ настройки постоянные.»

### Почему так / ответ на вопрос

Один bool по ключу не требует базы. В тесте передаётся отдельный suiteName, который удаляется после проверки. Не использую synchronize: стандартный API управляет сохранением.


## Файл `Sources/Data/SwiftDataLibraryRepository.swift` — SwiftData и постоянный CRUD

### Что говорить

> «StoredEntry — @Model с уникальным showID и payload Data. Payload содержит Codable-снимок LibraryEntry; это сознательно небольшой документный формат, а не набор SQL-фильтруемых полей. ModelContainer настраивает базу, ModelContext выполняет операции. fetch декодирует записи, save ищет по id и вставляет либо обновляет, delete находит запись и удаляет. После изменения вызывается save, при ошибке rollback.»

### Почему так / ответ на вопрос

Почему payload? Он отделяет структуру предметной модели от механизмов SwiftData и сохраняет весь снимок каталога для офлайн-доступа. Цена — фильтрация выполняется после чтения; для большой коллекции лучше выделить поля и предикаты базы. Автосохранение отключено ради явной обработки ошибки операции. Контекст не передаётся в фон. Unit-тест inMemory проверяет CRUD, а UI-перезапуск — реальное сохранение.


## Файл `Sources/Domain/ShelfAnalysis.swift` — Чистые фоновые вычисления

### Что говорить

> «search получает массив значений, обрезает края запроса, ищет в названии/комментарии и сортирует по имени. statistics считает количество записей, завершённых сериалов, приблизительное число минут и среднюю личную оценку. Нулевая оценка пропускается. В циклах есть Task.checkCancellation.»

### Почему так / ответ на вопрос

Минуты считаются watchedEpisodes×runtime; это оценка, о чём написано в интерфейсе. String.count — число символов Swift, не байтов. Работа не обращается к ModelContext или SwiftUI.


## Файл `Sources/Domain/Show.swift` — Предметные модели и правила

### Что говорить

> «Show — снимок сериала: id TVmaze, название, год, жанры, описание, длительность серии, рейтинг и источники. Codable нужен для локального JSON и сохранения, Equatable — для сравнений и task(id:), Sendable — для передачи снимков конкурентным задачам. В лабах 3+ LibraryEntry хранит личные данные отдельно от данных каталога. Его id равен show.id, поэтому один сериал соответствует одной записи. WatchStatus — enum допустимых статусов. EntryValidator проверяет оценку 0…10, серии 0…10000, комментарий до 2000 символов.»

### Почему так / ответ на вопрос

Оценка 0 означает «не выставлена» и не входит в среднее. Каталожный rating и personalRating различаются. addedAt сохраняется при редактировании, updatedAt обновляется. Статус «Просмотрено» выбирает пользователь; приложение не знает точное число выпущенных серий.


## Файл `Sources/Network/CatalogAPI.swift` — Прикладные GET и POST

### Что говорить

> «CatalogAPI реализует два протокола. shows выбирает /shows?page=0 или /search/shows?q=..., URLComponents корректно кодирует запрос. Ответ декодируется, преобразуется, очищается от пустых названий и дубликатов, сортируется по рейтингу с устойчивым правилом id при равенстве. sendReview валидирует текст, JSONEncoder собирает тело, Content-Type указывает JSON, ответ читается в ReviewReceipt.»

### Почему так / ответ на вопрос

TVmaze используется только для GET. JSONPlaceholder используется только для учебного POST, так как публичный TVmaze не даёт бесплатной пользовательской записи. Личный комментарий хранится локально. Нет ключей, логина и платных сервисов. Текущий каталог — первая страница, бесконечная пагинация не реализована.


## Файл `Sources/Network/HTTPTransport.swift` — Alamofire и HTTP/JSON

### Что говорить

> «HTTPTransport абстрагирует отправку URLRequest. AlamofireTransport получает Data и HTTPURLResponse. Отсутствие ответа отличается от HTTP-ошибки. ResponseParser сначала проверяет 200..<300, затем непустое тело, затем JSONDecoder. APIError различает transport, invalidResponse, http, emptyData, decoding.»

### Почему так / ответ на вопрос

Успешный HTTP-код не гарантирует правильный JSON. Пустые успешные ответы разрешены на уровне Alamofire, чтобы собственный парсер мог явно выдать emptyData. Для endpoint с нормальным 204 потребовался бы другой контракт, здесь ожидается объект/массив.


## Файл `Sources/Network/RemoteModels.swift` — DTO и преобразование

### Что говорить

> «RemoteShow соответствует JSON TVmaze с вложенными image и rating и optional-полями. domain превращает сетевой DTO в Show: удаляет простые HTML-теги из summary, нормализует год и длительность. SearchHit отражает обёртку show в ответе поискового endpoint. ReviewRequest кодирует POST, ReviewReceipt декодирует ответ.»

### Почему так / ответ на вопрос

Сетевой формат не должен определять всю внутреннюю модель. Удаление тегов через регулярное выражение здесь — ограниченная очистка описания, а не универсальный HTML-парсер или механизм безопасности.


## Файл `Sources/Presentation/AnalysisView.swift` — Статистика и жизненный цикл задач

### Что говорить

> «Показывает четыре показателя, пояснение приблизительного времени и результаты поиска. .task(id: entries) запускает статистику при изменении коллекции. SearchInput объединяет entries и query; его изменение отменяет прежнюю SwiftUI-задачу и запускает поиск заново.»

### Почему так / ответ на вопрос

StateObject удерживает собственный AnalysisViewModel. Индикатор может быть почти незаметен на шести записях, но вычисление всё равно отделено от UI. Пустое среднее показывается как «Нет оценок», а не как деление на ноль.


## Файл `Sources/Presentation/AnalysisViewModel.swift` — Два worker и возврат в UI

### Что говорить

> «search запускает Task.detached с .userInitiated, calculate — с .utility. Снимки LibraryEntry соответствуют Sendable. withTaskCancellationHandler передаёт отмену detached-worker. После await проверяются отмена и generation. Только текущее поколение публикует результат и снимает флаг загрузки.»

### Почему так / ответ на вопрос

async не равен новому потоку. Task.detached выполняет работу вне изоляции MainActor, runtime распределяет потоки. Номер поколения закрывает гонку: более старый поиск не перепишет более новый. В catch ожидается отмена; вычисления могут бросить только CancellationError.


## Файл `Sources/Presentation/CatalogView.swift` — Локальный каталог

### Что говорить

> «@ObservedObject получает существующую LibraryViewModel. query — локальный @State. Фильтр ищет название без учёта регистра. LazyVGrid строит две колонки карточек, NavigationLink открывает ShowDetailView. searchable связывает строку поиска с query. При пустом результате появляется системная заглушка.»

### Почему так / ответ на вопрос

Lazy-контейнер создаёт представления по мере необходимости. Идентификатор show-<id> даёт стабильную точку для UI-теста. На маленьком локальном наборе синхронный фильтр допустим; отдельная фоновая обработка коллекции введена в лабе 5.


## Файл `Sources/Presentation/Components.swift` — Общие элементы интерфейса

### Что говорить

> «ShelfStyle задаёт акцентный цвет. PosterView сначала ищет локальный постер в asset catalogue, затем использует AsyncImage для сетевой картинки; при отсутствии показывает нейтральный placeholder. GeometryReader подстраивает изображение под размер, scaledToFill заполняет область, clipped обрезает выход за границы. ShowCard объединяет постер, название, год, жанр и рейтинг.»

### Почему так / ответ на вопрос

Отдельный компонент устраняет дублирование верстки. Рейтинг форматируется до одного знака. Изображение скрыто от accessibility, а карточка объединяет текст, чтобы не повторять голосом декоративные детали.


## Файл `Sources/Presentation/EntryEditorView.swift` — Черновик и проверка ввода

### Что говорить

> «В init копия записи помещается в @State draft. Picker выбирает статус, Stepper ограничивает рейтинг и серии, TextEditor редактирует комментарий. Binding $draft.review связывает ввод с черновиком. «Сохранить» вызывает model.update и закрывает sheet только при успехе; «Отмена» закрывает без записи.»

### Почему так / ответ на вопрос

Обработка валидации есть и в ViewModel, даже если Stepper ограничивает числа: другие вызовы тоже должны соблюдать правила. Локальная ошибка формы забирается из model.errorMessage, чтобы не открывать второй alert одновременно.


## Файл `Sources/Presentation/LibraryView.swift` — Список и детали личной записи

### Что говорить

> «LibraryView отображает entries с учётом настройки newestFirst. Свайп вызывает delete. NavigationLink передаёт id, а EntryDetailView ищет актуальную запись в модели: после редактирования детали обновляются. .sheet открывает редактор. savedReview используется UI-тестом для проверки точного сохранённого текста.»

### Почему так / ответ на вопрос

В деталях передаётся id, а не забытая копия записи. Экран явно обрабатывает удаление. Сортировка «сначала новые» означает дату добавления, а не последнего редактирования.


## Файл `Sources/Presentation/LibraryViewModel.swift` — MVVM и операции коллекции

### Что говорить

> «@Published private(set) entries доступен экранам для чтения. add проверяет дубликат; update находит исходную запись, сохраняет id/show/addedAt, переносит только редактируемые поля, обрезает пробелы комментария и обновляет updatedAt. persist валидирует и сохраняет; reload перечитывает и сортирует. delete вызывает репозиторий. Ошибка попадает в errorMessage.»

### Почему так / ответ на вопрос

Состояние UI находится на MainActor. Репозиторий внедряется через init(repository:). View не может произвольно перезаписать entries. После ошибки сохранения/удаления опубликованный список не заменяется выдуманным успешным результатом.


## Файл `Sources/Presentation/RemoteCatalogView.swift` — Сетевой каталог и форма POST

### Что говорить

> «RemoteCatalogView запускает загрузку через .task(id: query), поддерживает refreshable, ошибку и повтор GET. Карточки используют ту же модель и детальный экран. ReviewSendView находится в этом файле: TextField вводит текст, кнопка блокируется для пустого/слишком длинного отзыва и во время отправки; receipt показывает id.»

### Почему так / ответ на вопрос

Форма честно объясняет, что учебный сервер не хранит отзыв. Локальная коллекция доступна при сетевой ошибке на другой вкладке. Визуально интерфейс не выдаёт локальный fixture за онлайн-ответ.


## Файл `Sources/Presentation/RemoteViewModels.swift` — Сетевое состояние и отмена

### Что говорить

> «RemoteCatalogViewModel публикует shows/loading/loaded/error. Перед GET есть 350 мс debounce; новая задача отменяет старую. generation не позволяет устаревшему ответу переписать новый. ReviewViewModel защищает POST флагом sending, очищает прошлый receipt и показывает результат или ошибку. defer снимает флаги.»

### Почему так / ответ на вопрос

UI-состояние изолировано MainActor, а сеть не блокирует его на время ожидания. Отмена не показывается пользователю как ошибка. Загрузка каталога и отправка отзыва имеют независимые состояния.


## Файл `Sources/Presentation/SerialShelfApp.swift` — Точка входа и создание зависимостей

### Что говорить

> «В лабе 2 WindowGroup создаёт RecommendationView. @State number хранит optional-число; Text выводит число или начальную подсказку. NavigationLink передаёт выбранный сериал. Индекс (number-1)%count остаётся в границах массива, пустой каталог проверяется отдельно. В 3+ точка входа создаёт SettingsStore и LibraryViewModel через @StateObject, загружает локальные ресурсы и выбирает репозиторий. RootView организует вкладки через TabView и отдельные NavigationStack.»

### Почему так / ответ на вопрос

StateObject владеет объектом для данной идентичности SwiftUI-представления. Ошибка открытия ресурсов/базы показывает экран ошибки, а не выдаётся за успешно сохранённые данные. В 3 память, в 4+ SwiftData и UserDefaults. В 6+ обычный каталог RemoteCatalogView; --ui-testing явно выбирает LocalCatalog.


## Файл `Sources/Presentation/SettingsView.swift` — Настройки и источники

### Что говорить

> «Два Toggle меняют порядок и тему через EnvironmentObject. preferredColorScheme в приложении реагирует на darkMode. Раздел «Источники» указывает лицензию и происхождение данных/изображений.»

### Почему так / ответ на вопрос

EnvironmentObject используется для общих настроек во всей иерархии, а не как глобальный singleton. Каталог не предоставляет воспроизведение серий — это органайзер просмотра.


## Файл `Sources/Presentation/ShowDetailView.swift` — Карточка сериала

### Что говорить

> «Показывает постер, описание, жанры, время серии и каталожный рейтинг. Кнопка add вызывает LibraryViewModel.add. После добавления она становится «В коллекции» и блокируется. Ссылка ведёт к источнику TVmaze. В 6+ ниже находится форма отправки учебного POST.»

### Почему так / ответ на вопрос

Пользовательские поля не записываются в сетевой Show — они лежат в LibraryEntry. Ссылка на источник обеспечивает атрибуцию. Чтобы увидеть POST, нужно прокрутить карточку вниз.


## Файл `Tests/LibraryTests.swift` — Три unit-теста модуля

### Что говорить

> «Первый проверяет CRUD, дубликат, идентичность, trimming и чтение через другой ViewModel. Второй проверяет неверные и граничные значения. Третий FaultRepository имитирует ошибки read/save/delete и восстановление. @testable import открывает internal API тестам. XCTUnwrap корректно извлекает optional или фиксирует провал.»

### Почему так / ответ на вопрос

В лабе 7 это ровно три test-метода; assertions внутри больше. Чтение через второй ViewModel не равно перезапуску процесса — это отдельно проверяется UI. Тестовый репозиторий не скрывает ошибки настоящей базы: тесты изолируют именно ViewModel.


## Файл `UITests/SerialShelfUITests.swift` — Два UI-теста

### Что говорить

> «Первый запускает приложение с --ui-testing, добавляет Breaking Bad, редактирует комментарий, завершает процесс, запускает заново, сравнивает текст и удаляет запись. Второй переключает newestFirst, уводит приложение на home, завершает/запускает, проверяет сохранение и возвращает настройку.»

### Почему так / ответ на вопрос

Локальный каталог делает тест независимым от интернета; SwiftData и UserDefaults остаются настоящими. Элементы ищутся по accessibilityIdentifier. waitForExistence и предикатное ожидание проверяют состояние вместо слепых sleep. Нажатие правого края Toggle использует относительные координаты самого accessibility-элемента.


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
  bundleIdPrefix: edu.itmo.ignatev.lab7
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
      PRODUCT_BUNDLE_IDENTIFIER: edu.itmo.ignatev.lab7.SerialShelf
      INFOPLIST_KEY_CFBundleDisplayName: СериалПолка 7
    dependencies: [{package: Alamofire}]
  SerialShelfTests:
    type: bundle.unit-test
    platform: iOS
    sources: [Tests]
    dependencies: [{target: SerialShelf}]
  SerialShelfUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [UITests]
    dependencies: [{target: SerialShelf}]
schemes:
  SerialShelf:
    build:
      targets:
        SerialShelf: all
    test:
      gatherCoverageData: true
      targets: [SerialShelfTests, SerialShelfUITests]
packages:
  Alamofire:
    url: https://github.com/Alamofire/Alamofire.git
    exactVersion: 5.10.2
```

### Sources/Data/LibraryRepository.swift

```swift
import Foundation

@MainActor protocol LibraryRepository {
    func fetch() throws -> [LibraryEntry]
    func save(_ entry: LibraryEntry) throws
    func delete(id: Int) throws
}

@MainActor final class MemoryLibraryRepository: LibraryRepository {
    private var entries: [Int: LibraryEntry] = [:]
    func fetch() throws -> [LibraryEntry] { Array(entries.values) }
    func save(_ entry: LibraryEntry) throws { entries[entry.id] = entry }
    func delete(id: Int) throws { entries[id] = nil }
}
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

### Sources/Data/SettingsStore.swift

```swift
import Foundation
import Combine

@MainActor final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults?
    @Published var newestFirst: Bool {
        didSet { defaults?.set(newestFirst, forKey: "library.newestFirst") }
    }
    @Published var darkMode: Bool {
        didSet { defaults?.set(darkMode, forKey: "appearance.darkMode") }
    }

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
        defaults?.register(defaults: ["library.newestFirst": true, "appearance.darkMode": true])
        newestFirst = defaults?.bool(forKey: "library.newestFirst") ?? true
        darkMode = defaults?.bool(forKey: "appearance.darkMode") ?? true
    }
}
```

### Sources/Data/SwiftDataLibraryRepository.swift

```swift
import Foundation
import SwiftData

@Model final class StoredEntry {
    @Attribute(.unique) var showID: Int
    var payload: Data
    init(entry: LibraryEntry) throws {
        showID = entry.id
        payload = try JSONEncoder().encode(entry)
    }
}

@MainActor final class SwiftDataLibraryRepository: LibraryRepository {
    let container: ModelContainer
    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: StoredEntry.self, configurations: config)
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func fetch() throws -> [LibraryEntry] {
        try context.fetch(FetchDescriptor<StoredEntry>()).map {
            try JSONDecoder().decode(LibraryEntry.self, from: $0.payload)
        }
    }

    func save(_ entry: LibraryEntry) throws {
        try EntryValidator.validate(entry)
        do {
            let id = entry.id
            let query = FetchDescriptor<StoredEntry>(predicate: #Predicate { $0.showID == id })
            if let stored = try context.fetch(query).first {
                stored.payload = try JSONEncoder().encode(entry)
            } else {
                context.insert(try StoredEntry(entry: entry))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(id: Int) throws {
        do {
            let query = FetchDescriptor<StoredEntry>(predicate: #Predicate { $0.showID == id })
            if let stored = try context.fetch(query).first { context.delete(stored) }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
```

### Sources/Domain/ShelfAnalysis.swift

```swift
import Foundation

struct ShelfStatistics: Equatable, Sendable {
    let total: Int
    let finished: Int
    let minutes: Int
    let average: Double?
}

enum ShelfAnalysis {
    static func search(_ entries: [LibraryEntry], query: String) throws -> [LibraryEntry] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return try entries.filter {
            try Task.checkCancellation()
            return query.isEmpty || $0.show.name.localizedCaseInsensitiveContains(query) ||
                $0.review.localizedCaseInsensitiveContains(query)
        }.sorted { $0.show.name.localizedStandardCompare($1.show.name) == .orderedAscending }
    }

    static func statistics(_ entries: [LibraryEntry]) throws -> ShelfStatistics {
        var finished = 0, minutes = 0, sum = 0, rated = 0
        for entry in entries {
            try Task.checkCancellation()
            if entry.status == .finished { finished += 1 }
            minutes += entry.watchedEpisodes * entry.show.runtime
            if entry.personalRating > 0 { sum += entry.personalRating; rated += 1 }
        }
        return ShelfStatistics(total: entries.count, finished: finished, minutes: minutes,
            average: rated == 0 ? nil : Double(sum) / Double(rated))
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

enum WatchStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case planned = "Хочу посмотреть"
    case watching = "Смотрю"
    case finished = "Просмотрено"
    var id: String { rawValue }
}

struct LibraryEntry: Identifiable, Codable, Equatable, Sendable {
    var id: Int { show.id }
    let show: Show
    var status: WatchStatus = .planned
    var personalRating: Int = 0
    var watchedEpisodes: Int = 0
    var review: String = ""
    let addedAt: Date
    var updatedAt: Date

    init(show: Show, now: Date = Date()) {
        self.show = show
        addedAt = now
        updatedAt = now
    }
}

enum LibraryError: LocalizedError {
    case duplicate, missing, invalidRating, invalidEpisodes, longReview, invalidReview
    var errorDescription: String? {
        switch self {
        case .duplicate: return "Этот сериал уже есть в коллекции."
        case .missing: return "Запись больше не существует."
        case .invalidRating: return "Оценка должна быть от 0 до 10."
        case .invalidEpisodes: return "Число серий должно быть от 0 до 10000."
        case .longReview: return "Комментарий должен быть не длиннее 2000 символов."
        case .invalidReview: return "Отзыв должен содержать от 1 до 2000 символов."
        }
    }
}

enum EntryValidator {
    static func validate(_ entry: LibraryEntry) throws {
        guard (0...10).contains(entry.personalRating) else { throw LibraryError.invalidRating }
        guard (0...10000).contains(entry.watchedEpisodes) else { throw LibraryError.invalidEpisodes }
        guard entry.review.count <= 2000 else { throw LibraryError.longReview }
    }
}
```

### Sources/Network/CatalogAPI.swift

```swift
import Foundation

protocol CatalogService: Sendable {
    func shows(query: String) async throws -> [Show]
}

protocol ReviewService: Sendable {
    func sendReview(show: Show, text: String) async throws -> ReviewReceipt
}

struct CatalogAPI: CatalogService, ReviewService {
    let transport: any HTTPTransport
    init(transport: any HTTPTransport = AlamofireTransport()) { self.transport = transport }

    func shows(query: String) async throws -> [Show] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var url = URLComponents(string: "https://api.tvmaze.com" )!
        url.path = query.isEmpty ? "/shows" : "/search/shows"
        url.queryItems = [URLQueryItem(name: query.isEmpty ? "page" : "q", value: query.isEmpty ? "0" : query)]
        var request = URLRequest(url: url.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let payload = try await transport.send(request)
        let remote: [RemoteShow]
        if query.isEmpty { remote = try ResponseParser.decode([RemoteShow].self, from: payload) }
        else { remote = try ResponseParser.decode([SearchHit].self, from: payload).map(\.show) }
        var ids = Set<Int>()
        return remote.map { $0.domain() }.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && ids.insert($0.id).inserted
        }.sorted {
            ($0.rating ?? -1) == ($1.rating ?? -1) ? $0.id < $1.id : ($0.rating ?? -1) > ($1.rating ?? -1)
        }
    }

    func sendReview(show: Show, text: String) async throws -> ReviewReceipt {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && text.count <= 2000 else { throw LibraryError.invalidReview }
        var request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(ReviewRequest(title: show.name, body: text, userId: 1))
        return try ResponseParser.decode(ReviewReceipt.self, from: await transport.send(request))
    }
}
```

### Sources/Network/HTTPTransport.swift

```swift
import Foundation
import Alamofire

struct HTTPPayload: Sendable { let status: Int; let data: Data }

enum APIError: LocalizedError {
    case transport(String), invalidResponse, http(Int), emptyData, decoding
    var errorDescription: String? {
        switch self {
        case .transport(let message): return "Ошибка соединения: " + message
        case .invalidResponse: return "Сервер не вернул HTTP-ответ."
        case .http(let code): return "Ошибка HTTP \(code). Попробуй повторить запрос."
        case .emptyData: return "Сервер вернул пустое тело ответа."
        case .decoding: return "Не удалось прочитать JSON сервера."
        }
    }
}

protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPPayload
}

struct AlamofireTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> HTTPPayload {
        let response = await AF.request(request).serializingData(
            automaticallyCancelling: true, emptyResponseCodes: Set(200..<300)).response
        try Task.checkCancellation()
        guard let http = response.response else {
            if let error = response.error { throw APIError.transport(error.localizedDescription) }
            throw APIError.invalidResponse
        }
        if let error = response.error, (200..<300).contains(http.statusCode) {
            throw APIError.transport(error.localizedDescription)
        }
        return HTTPPayload(status: http.statusCode, data: response.data ?? Data())
    }
}

enum ResponseParser {
    static func decode<T: Decodable>(_ type: T.Type, from payload: HTTPPayload) throws -> T {
        guard (200..<300).contains(payload.status) else { throw APIError.http(payload.status) }
        guard !payload.data.isEmpty else { throw APIError.emptyData }
        do { return try JSONDecoder().decode(type, from: payload.data) }
        catch { throw APIError.decoding }
    }
}
```

### Sources/Network/RemoteModels.swift

```swift
import Foundation

struct RemoteShow: Decodable {
    struct Image: Decodable { let medium: String? }
    struct Rating: Decodable { let average: Double? }
    let id: Int
    let name: String
    let premiered: String?
    let genres: [String]
    let summary: String?
    let runtime: Int?
    let averageRuntime: Int?
    let rating: Rating
    let image: Image?
    let url: String

    func domain() -> Show {
        let text = (summary ?? "Описание пока отсутствует.")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return Show(id: id, name: name, year: String((premiered ?? "—").prefix(4)),
            genres: genres, summary: text, runtime: max(1, averageRuntime ?? runtime ?? 45),
            rating: rating.average, imageURL: image?.medium, sourceURL: url)
    }
}

struct SearchHit: Decodable { let show: RemoteShow }
struct ReviewRequest: Encodable { let title: String; let body: String; let userId: Int }
struct ReviewReceipt: Codable, Equatable, Sendable { let id: Int; let title: String; let body: String; let userId: Int }
```

### Sources/Presentation/AnalysisView.swift

```swift
import SwiftUI

struct AnalysisView: View {
    let entries: [LibraryEntry]
    @StateObject private var model = AnalysisViewModel()
    @State private var query = ""
    private struct SearchInput: Equatable { let entries: [LibraryEntry]; let query: String }
    var body: some View {
        List {
            Section("Твой просмотр") {
                if model.calculating { ProgressView("Подсчёт…") }
                if let value = model.statistics {
                    LabeledContent("На полке", value: String(value.total))
                    LabeledContent("Завершено", value: String(value.finished))
                    LabeledContent("Просмотрено минут ≈", value: String(value.minutes))
                    LabeledContent("Средняя оценка", value: value.average.map { String(format: "%.1f", $0) } ?? "Нет оценок")
                }
                Text("Время — оценка по числу просмотренных серий и средней длительности серии.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Поиск по моей коллекции") {
                if model.searching { ProgressView() }
                ForEach(model.matches) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.show.name).font(.headline)
                        Text(entry.status.rawValue).foregroundStyle(.secondary)
                    }
                }
                if !model.searching && model.matches.isEmpty { Text("Ничего не найдено") }
            }
        }.navigationTitle("Статистика")
        .searchable(text: $query, prompt: "Сериал или комментарий")
        .task(id: entries) { await model.calculate(entries) }
        .task(id: SearchInput(entries: entries, query: query)) { await model.search(entries, query: query) }
    }
}
```

### Sources/Presentation/AnalysisViewModel.swift

```swift
import Foundation
import Combine

@MainActor final class AnalysisViewModel: ObservableObject {
    @Published private(set) var matches: [LibraryEntry] = []
    @Published private(set) var statistics: ShelfStatistics?
    @Published private(set) var searching = false
    @Published private(set) var calculating = false
    private var searchGeneration = 0
    private var statisticsGeneration = 0

    func search(_ entries: [LibraryEntry], query: String) async {
        searchGeneration += 1
        let generation = searchGeneration
        searching = true
        let task = Task.detached(priority: .userInitiated) {
            try ShelfAnalysis.search(entries, query: query)
        }
        defer { if generation == searchGeneration { searching = false } }
        do {
            let result = try await withTaskCancellationHandler(operation: { try await task.value },
                onCancel: { task.cancel() })
            try Task.checkCancellation()
            guard generation == searchGeneration else { return }
            matches = result
        } catch { /* Cancellation keeps the last completed result. */ }
    }

    func calculate(_ entries: [LibraryEntry]) async {
        statisticsGeneration += 1
        let generation = statisticsGeneration
        calculating = true
        let task = Task.detached(priority: .utility) { try ShelfAnalysis.statistics(entries) }
        defer { if generation == statisticsGeneration { calculating = false } }
        do {
            let result = try await withTaskCancellationHandler(operation: { try await task.value },
                onCancel: { task.cancel() })
            try Task.checkCancellation()
            guard generation == statisticsGeneration else { return }
            statistics = result
        } catch { /* Both workers check cancellation inside their loops. */ }
    }
}
```

### Sources/Presentation/CatalogView.swift

```swift
import SwiftUI

struct CatalogView: View {
    @ObservedObject var library: LibraryViewModel
    let shows: [Show]
    @State private var query = ""
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private var filtered: [Show] {
        shows.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("НАЙДИ СВОЮ ИСТОРИЮ").font(.caption.bold()).foregroundStyle(ShelfStyle.accent)
                    Text("Хороший вечер\nначинается здесь").font(.largeTitle.bold())
                    Text("Сохраняй сериалы и следи за просмотром.").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(filtered) { show in
                        NavigationLink {
                            ShowDetailView(show: show, library: library)
                        } label: { ShowCard(show: show) }.buttonStyle(.plain)
                        .accessibilityIdentifier("show-\(show.id)")
                    }
                }
                if filtered.isEmpty { ContentUnavailableView.search(text: query) }
                Text("Данные: TVmaze · CC BY-SA").font(.caption).foregroundStyle(.secondary)
            }.padding()
        }
        .navigationTitle("СериалПолка")
        .searchable(text: $query, prompt: "Название сериала")
    }
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

struct ShowCard: View {
    let show: Show
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PosterView(show: show).frame(height: 224)
                .overlay(alignment: .topTrailing) {
                    if let rating = show.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.caption.bold()).padding(7).background(.black.opacity(0.8), in: Capsule()).padding(8)
                    }
                }
            Text(show.name).font(.headline).lineLimit(2).foregroundStyle(.primary)
            Text(show.year + " · " + (show.genres.first ?? "Сериал"))
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
```

### Sources/Presentation/EntryEditorView.swift

```swift
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
                    ForEach(WatchStatus.allCases) { Text($0.rawValue).tag($0) }
                }.accessibilityIdentifier("watchStatus")
                Stepper("Оценка: \(draft.personalRating)/10", value: $draft.personalRating, in: 0...10)
                    .accessibilityIdentifier("personalRating")
                Text("0 — оценка не выставлена").font(.caption).foregroundStyle(.secondary)
                Stepper("Серий: \(draft.watchedEpisodes)", value: $draft.watchedEpisodes, in: 0...10000)
                    .accessibilityIdentifier("watchedEpisodes")
            }
            Section("Комментарий") {
                TextEditor(text: $draft.review).frame(minHeight: 130)
                    .accessibilityIdentifier("reviewEditor")
                Text("\(draft.review.count)/2000").font(.caption).foregroundStyle(.secondary)
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("Редактирование").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    if model.update(draft) { dismiss() }
                    else { error = model.errorMessage; model.errorMessage = nil }
                }
            }
        }
    }
}
```

### Sources/Presentation/LibraryView.swift

```swift
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
                    Button("Удалить", role: .destructive) { model.delete(id: entry.id) }
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
            if let entry = model.entries.first(where: { $0.id == id }) {
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
                    Section { Text("Добавлено: " + entry.addedAt.formatted(date: .abbreviated, time: .omitted)) }
                }
                .toolbar { Button("Изменить") { editing = true } }
                .sheet(isPresented: $editing) { NavigationStack { EntryEditorView(entry: entry, model: model) } }
            } else { ContentUnavailableView("Запись удалена", systemImage: "trash") }
        }.navigationTitle("Мой сериал").navigationBarTitleDisplayMode(.inline)
    }
}
```

### Sources/Presentation/LibraryViewModel.swift

```swift
import Foundation
import Combine

@MainActor final class LibraryViewModel: ObservableObject {
    @Published private(set) var entries: [LibraryEntry] = []
    @Published var errorMessage: String?
    private let repository: any LibraryRepository

    init(repository: any LibraryRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            entries = try repository.fetch().sorted { $0.addedAt > $1.addedAt }
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func contains(_ show: Show) -> Bool { entries.contains { $0.id == show.id } }

    @discardableResult func add(_ show: Show) -> Bool {
        guard !contains(show) else { errorMessage = LibraryError.duplicate.localizedDescription; return false }
        return persist(LibraryEntry(show: show))
    }

    @discardableResult func update(_ draft: LibraryEntry) -> Bool {
        guard let original = entries.first(where: { $0.id == draft.id }) else {
            errorMessage = LibraryError.missing.localizedDescription
            return false
        }
        var entry = original
        entry.status = draft.status
        entry.personalRating = draft.personalRating
        entry.watchedEpisodes = draft.watchedEpisodes
        entry.review = draft.review.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.updatedAt = Date()
        return persist(entry)
    }

    private func persist(_ entry: LibraryEntry) -> Bool {
        do {
            try EntryValidator.validate(entry)
            try repository.save(entry)
            reload()
            return errorMessage == nil
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func delete(id: Int) {
        do { try repository.delete(id: id); reload() }
        catch { errorMessage = error.localizedDescription }
    }
}
```

### Sources/Presentation/RemoteCatalogView.swift

```swift
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
                if model.loading { ProgressView("Загружаем сериалы…").frame(maxWidth: .infinity) }
                if let error = model.error {
                    ContentUnavailableView("Не удалось загрузить каталог", systemImage: "wifi.exclamationmark",
                        description: Text(error))
                    Button("Повторить GET") { Task { await model.load(query: query) } }
                        .buttonStyle(.bordered)
                    Text("Локальная коллекция доступна на вкладке «Моя полка».").font(.caption)
                }
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(model.shows) { show in
                        NavigationLink { ShowDetailView(show: show, library: library) }
                        label: { ShowCard(show: show) }.buttonStyle(.plain)
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
        .task(id: query) { await model.load(query: query) }
        .refreshable { await model.load(query: query) }
    }
}

struct ReviewSendView: View {
    let show: Show
    @StateObject private var model = ReviewViewModel()
    @State private var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Отправить отзыв · POST").font(.title2.bold())
            Text("Учебный сервер возвращает ответ, но не хранит отзыв. Личный комментарий сохраняется отдельно в коллекции.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("Текст отзыва", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("networkReview")
            Button(model.sending ? "Отправка…" : "Отправить отзыв") {
                Task { await model.send(show: show, text: text) }
            }.buttonStyle(.borderedProminent)
                .disabled(model.sending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > 2000)
                .accessibilityIdentifier("sendReview")
            if let receipt = model.receipt {
                Label("Ответ получен · id \(receipt.id)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green).accessibilityIdentifier("postReceipt")
            }
            if let error = model.error { Text(error).foregroundStyle(.red) }
        }
    }
}
```

### Sources/Presentation/RemoteViewModels.swift

```swift
import Foundation
import Combine

@MainActor final class RemoteCatalogViewModel: ObservableObject {
    @Published private(set) var shows: [Show] = []
    @Published private(set) var loading = false
    @Published private(set) var loaded = false
    @Published private(set) var error: String?
    private let service: any CatalogService
    private var generation = 0
    init(service: any CatalogService = CatalogAPI()) { self.service = service }

    func load(query: String) async {
        generation += 1
        let current = generation
        loading = true; error = nil
        defer { if current == generation { loading = false } }
        do {
            try await Task.sleep(for: .milliseconds(350))
            let result = try await service.shows(query: query)
            try Task.checkCancellation()
            guard current == generation else { return }
            shows = result; loaded = true
        } catch is CancellationError { }
        catch { if current == generation { self.error = error.localizedDescription } }
    }
}

@MainActor final class ReviewViewModel: ObservableObject {
    @Published private(set) var sending = false
    @Published private(set) var receipt: ReviewReceipt?
    @Published private(set) var error: String?
    private let service: any ReviewService
    init(service: any ReviewService = CatalogAPI()) { self.service = service }
    func send(show: Show, text: String) async {
        guard !sending else { return }
        sending = true; error = nil; receipt = nil
        defer { sending = false }
        do { receipt = try await service.sendReview(show: show, text: text) }
        catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}
```

### Sources/Presentation/SerialShelfApp.swift

```swift
import SwiftUI

@main @MainActor struct SerialShelfApp: App {
    @StateObject private var settings: SettingsStore
    @StateObject private var library: LibraryViewModel
    private let shows: [Show]
    private let startupError: String?

    init() {
        _settings = StateObject(wrappedValue: SettingsStore(defaults: .standard))
        do {
            let loaded = try LocalCatalog.load()
            let repository = try SwiftDataLibraryRepository()
            shows = loaded
            _library = StateObject(wrappedValue: LibraryViewModel(repository: repository))
            startupError = nil
        } catch {
            shows = []
            _library = StateObject(wrappedValue: LibraryViewModel(repository: MemoryLibraryRepository()))
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let startupError {
                    ContentUnavailableView("Не удалось открыть данные", systemImage: "externaldrive.badge.exclamationmark",
                        description: Text(startupError + " Данные не удалены. Перезапусти приложение."))
                } else { RootView(library: library, shows: shows) }
            }
            .environmentObject(settings).tint(ShelfStyle.accent)
            .preferredColorScheme(settings.darkMode ? .dark : .light)
        }
    }
}

struct RootView: View {
    @ObservedObject var library: LibraryViewModel
    let shows: [Show]
    var body: some View {
        TabView {
            NavigationStack {
                if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                    CatalogView(library: library, shows: shows)
                } else { RemoteCatalogView(library: library) }
            }.tabItem { Label("Каталог", systemImage: "square.grid.2x2") }
            NavigationStack { LibraryView(model: library) }
                .tabItem { Label("Моя полка", systemImage: "bookmark") }
            NavigationStack { AnalysisView(entries: library.entries) }.tabItem { Label("Статистика", systemImage: "chart.bar") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Настройки", systemImage: "slider.horizontal.3") }
        }
        .alert("Не удалось выполнить действие", isPresented: Binding(get: { library.errorMessage != nil },
            set: { if !$0 { library.errorMessage = nil } })) {
                Button("OK") { library.errorMessage = nil }
            } message: { Text(library.errorMessage ?? "") }
    }
}
```

### Sources/Presentation/SettingsView.swift

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    var body: some View {
        Form {
            Section("Твоя коллекция") {
                Toggle("Сначала новые", isOn: $settings.newestFirst).accessibilityIdentifier("newestFirst")
                Toggle("Тёмное оформление", isOn: $settings.darkMode).accessibilityIdentifier("darkMode")
            }
            Section("СериалПолка") {
                Label("Лабораторная 7", systemImage: "graduationcap")
                Text("SwiftUI · MVVM · Repository · DI").font(.footnote)
                Text("Коллекция — SwiftData. Настройки — UserDefaults.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Источники") {
                Link("TVmaze · данные и изображения · CC BY-SA", destination: URL(string: "https://www.tvmaze.com/api")!)
                Text("Каталог не предоставляет просмотр видео и не распространяет серии.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Настройки")
    }
}
```

### Sources/Presentation/ShowDetailView.swift

```swift
import SwiftUI

struct ShowDetailView: View {
    let show: Show
    @ObservedObject var library: LibraryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PosterView(show: show).frame(height: 330)
                Text(show.name).font(.largeTitle.bold())
                Text(show.year + " · " + show.genres.joined(separator: " / "))
                    .foregroundStyle(.secondary)
                HStack(spacing: 24) {
                    Label("\(show.runtime) мин / серия", systemImage: "clock")
                    if let rating = show.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                    }
                }.font(.subheadline).foregroundStyle(ShelfStyle.accent)
                Button {
                    library.add(show)
                } label: {
                    Label(library.contains(show) ? "В коллекции" : "Буду смотреть",
                          systemImage: library.contains(show) ? "checkmark" : "plus")
                        .frame(maxWidth: .infinity).padding(7)
                }
                .buttonStyle(.borderedProminent).disabled(library.contains(show))
                .accessibilityIdentifier("addToLibrary")
                Text("О сериале").font(.title2.bold())
                Text(show.summary).foregroundStyle(.secondary).textSelection(.enabled)
                if let url = URL(string: show.sourceURL) {
                    Link("Информация на TVmaze ↗", destination: url).font(.footnote)
                }
                ReviewSendView(show: show)
            }.padding()
        }
        .navigationTitle("О сериале").navigationBarTitleDisplayMode(.inline)
    }
}
```

### Tests/LibraryTests.swift

```swift
import XCTest
@testable import SerialShelf

final class LibraryTests: XCTestCase {
    let show = Show(id: 1, name: "Test Show", year: "2020", genres: ["Drama"],
        summary: "Story", runtime: 45, rating: 8, imageURL: nil, sourceURL: "https://www.tvmaze.com")

    @MainActor func testCRUDAndDuplicateProtection() async throws {
        let repository = MemoryLibraryRepository()
        let model = LibraryViewModel(repository: repository)
        XCTAssertTrue(model.add(show))
        XCTAssertFalse(model.add(show))
        var draft = try XCTUnwrap(model.entries.first)
        let addedAt = draft.addedAt
        draft.status = .finished; draft.personalRating = 9
        draft.watchedEpisodes = 12; draft.review = "  Great story  "
        XCTAssertTrue(model.update(draft))
        let saved = try XCTUnwrap(model.entries.first)
        XCTAssertEqual(model.entries.count, 1)
        XCTAssertEqual(saved.id, show.id)
        XCTAssertEqual(saved.addedAt, addedAt)
        XCTAssertEqual(saved.review, "Great story")
        XCTAssertEqual(LibraryViewModel(repository: repository).entries, [saved])
        model.delete(id: show.id)
        XCTAssertTrue(try repository.fetch().isEmpty)
        XCTAssertTrue(model.entries.isEmpty)
    }

    @MainActor func testValidationBoundaries() async throws {
        let repository = MemoryLibraryRepository()
        let model = LibraryViewModel(repository: repository)
        XCTAssertTrue(model.add(show))
        var draft = try XCTUnwrap(model.entries.first)
        for value in [-1, 11] {
            draft.personalRating = value
            XCTAssertFalse(model.update(draft))
            XCTAssertEqual(model.entries.first?.personalRating, 0)
        }
        draft.personalRating = 10; draft.watchedEpisodes = -1
        XCTAssertFalse(model.update(draft))
        draft.watchedEpisodes = 10001
        XCTAssertFalse(model.update(draft))
        draft.watchedEpisodes = 10000; draft.review = String(repeating: "я", count: 2001)
        XCTAssertFalse(model.update(draft))
        draft.review = String(repeating: "я", count: 2000)
        XCTAssertTrue(model.update(draft))
        XCTAssertNil(model.errorMessage)
    }

    @MainActor func testRepositoryErrorsAndRecovery() async throws {
        let repository = FaultRepository()
        repository.failure = .read
        let model = LibraryViewModel(repository: repository)
        XCTAssertNotNil(model.errorMessage)
        repository.failure = nil; model.reload()
        XCTAssertNil(model.errorMessage)
        repository.failure = .save
        XCTAssertFalse(model.add(show)); XCTAssertTrue(model.entries.isEmpty)
        repository.failure = nil
        XCTAssertTrue(model.add(show))
        repository.failure = .delete
        model.delete(id: show.id)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.entries.count, 1)
        repository.failure = nil
        model.delete(id: show.id)
        XCTAssertTrue(model.entries.isEmpty)
        XCTAssertNil(model.errorMessage)
    }
}

@MainActor private final class FaultRepository: LibraryRepository {
    enum Operation { case read, save, delete }
    struct Failure: Error {}
    var failure: Operation?
    private var records: [Int: LibraryEntry] = [:]
    func fetch() throws -> [LibraryEntry] {
        if failure == .read { throw Failure() }; return Array(records.values)
    }
    func save(_ entry: LibraryEntry) throws {
        if failure == .save { throw Failure() }; records[entry.id] = entry
    }
    func delete(id: Int) throws {
        if failure == .delete { throw Failure() }; records[id] = nil
    }
}
```

### UITests/SerialShelfUITests.swift

```swift
import XCTest

final class SerialShelfUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testCollectionCRUDAndRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.tabBars.buttons["Каталог"].tap()
        let card = app.buttons["show-169"]
        XCTAssertTrue(card.waitForExistence(timeout: 15)); card.tap()
        let add = app.buttons["addToLibrary"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        if add.isEnabled { add.tap() }
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Моя полка"].tap()
        let row = app.buttons["entry-169"]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        app.buttons["Изменить"].tap()
        let editor = app.textViews["reviewEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5)); editor.tap()
        editor.typeText("Great story")
        app.buttons["Сохранить"].tap()
        let review = app.staticTexts["savedReview"]
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        let expected = review.label
        app.terminate(); app.launch()
        app.tabBars.buttons["Моя полка"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        XCTAssertEqual(review.label, expected)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        row.swipeLeft(); app.buttons["Удалить"].tap()
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: row)
        wait(for: [removed], timeout: 5)
    }

    @MainActor func testSettingsPersistAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch(); app.tabBars.buttons["Настройки"].tap()
        let control = app.switches["newestFirst"]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        let original = try XCTUnwrap(control.value as? String)
        let changed = original == "1" ? "0" : "1"
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", changed), object: control)
        wait(for: [expectation], timeout: 5)
        XCUIDevice.shared.press(.home); app.terminate(); app.launch()
        app.tabBars.buttons["Настройки"].tap()
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        XCTAssertEqual(control.value as? String, changed)
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }
}
```

