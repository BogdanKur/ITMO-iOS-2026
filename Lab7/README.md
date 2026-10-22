# Лабораторная 7 — XCTest: 3 unit-теста и 2 UI-теста

Самостоятельная версия StudyNotes на основе лабораторной 6. Проект содержит ровно **3 unit-теста** в `StudyNotesTests` и **2 UI-теста** в `StudyNotesUITests`. Исходники приложения находятся в Sources, сценарии XCTest — отдельно в Tests и UITests. Тесты предыдущих лабораторных сохранены в их собственных проектах.

| Тип | Тест | Что проверяет |
| --- | --- | --- |
| Unit | `testCRUDPreservesIdentityAndReloadsSavedData` | Создание, чтение из другого ViewModel, изменение без дубликата с сохранением UUID и createdAt, удаление |
| Unit | `testValidationRejectsInvalidTitlesAndAcceptsBoundary` | Пустое название, 101 символ, допустимая граница 100 символов; неверные данные не попадают в хранилище |
| Unit | `testStorageErrorsAreReportedAndRecoveryKeepsDataConsistent` | Ошибки чтения, записи и удаления; отображение ошибки, сохранение данных и восстановление после ошибки |
| UI | `testNoteCRUDAndPersistenceAfterRelaunch` | Пользователь создаёт, открывает и редактирует заметку; текст сохраняется после перезапуска; заметка удаляется |
| UI | `testSortSettingPersistsAfterRelaunch` | Пользователь переключает сортировку; настройка сохраняется после перезапуска; затем восстанавливается исходное значение |

## Почему такие тесты

Три unit-теста покрывают модуль `NotesViewModel`: успешные действия, валидацию и ошибки зависимостей. Зависимость `NoteRepository` передаётся в init. В первом тесте используется MemoryNoteRepository, в третьем — управляемый тестовый репозиторий, который выбрасывает ошибку выбранной операции. SwiftUI, диск и интернет не нужны. Структура каждого сценария: Arrange → Act → Assert.

UI-тесты запускают настоящее приложение через XCUIApplication и взаимодействуют с доступными пользователю элементами. Здесь проверяется связь экранов, SwiftData и UserDefaults. Каждый тест запускает приложение самостоятельно; заметка имеет уникальное имя и удаляется в конце, настройка возвращается к исходному значению. Тесты не зависят друг от друга и от внешнего API.

Поиск элементов использует accessibilityIdentifier (`noteTitle`, `noteBody`, `detailBody`) и подписи кнопок. Ожидания `waitForExistence` и `XCTNSPredicateExpectation` дожидаются состояния интерфейса. Переключатель нажимается по правой части, поскольку SwiftUI объединяет подпись и сам контрол в один accessibility-элемент. Для перезапуска настройки сначала выполняется уход на домашний экран, как при обычном закрытии приложения.

## Запуск

На Mac: из Lab7 выполни `xcodegen generate`, открой StudyNotes.xcodeproj и выбери iPhone Simulator. Product → Test (Cmd+U) запускает оба test target. В Test Navigator можно запускать каждый из пяти тестов отдельно. Схема собирает данные покрытия кода.

Без Mac: [Actions](https://github.com/BogdanKur/ITMO-iOS-2026/actions) → **Lab 7** → запуск ветки `lab-7`. Шаг **Run XCTest** выводит количество unit/UI-тестов и результат. Артефакт **Lab7-test-results** содержит лог, `.xcresult` и отчёт покрытия; **Lab7-screens** — PNG из UI-тестов. Для чтения результатов и просмотра скриншотов Appetize не нужен. [Подробнее для Windows](WINDOWS.md).

## Что показать на защите

1. Два отдельных target в project.yml: bundle.unit-test и bundle.ui-testing.
2. Файлы Tests/NotesViewModelTests.swift и UITests/StudyNotesUITests.swift: три и два метода `test…` соответственно.
3. Внедрение репозитория в ViewModel и тестовую подмену с ошибками.
4. Отличие unit-теста (изолированная логика) от UI-теста (запуск приложения и действия пользователя).
5. Зелёный workflow Lab 7, строки `Executed 3 tests` и `Executed 2 tests`, PNG и отчёт покрытия.

Самостоятельный checkout: ветка `lab-7`. Язык Swift, интерфейс SwiftUI, iOS 17+, фреймворк тестирования XCTest.
