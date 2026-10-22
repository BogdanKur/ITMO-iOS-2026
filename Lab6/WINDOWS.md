# Просмотр с Windows

Исходники открываются в VS Code: File → Open Folder → Lab6. Xcode, SwiftUI и iOS Simulator локально на Windows недоступны. Установка Swift на Windows позволяет запускать консольную Lab1, но не SwiftUI-приложения.

1. Открой https://github.com/BogdanKur/ITMO-iOS-2026/actions и workflow **Lab 6**. Выбери запуск своей ветки с зелёным статусом.
2. Внизу в Artifacts скачай **Lab6-simulator**. Распакуй скачанный GitHub-архив один раз: внутри находится **StudyNotes-simulator.zip**. Этот внутренний zip содержит StudyNotes.app, его и загружай в Appetize.
3. Зарегистрируйся на https://appetize.io/ , открой раздел Apps / загрузку приложения и загрузи StudyNotes-simulator.zip. Выбери iOS, совместимую с deployment target iOS 17+ и SDK сборки; дождись обработки. Открой созданную ссылку приложения и нажми запуск. Это запуск нативной iOS-сборки в облачном симуляторе.

Appetize Free на момент подготовки: 30 минут в месяц, максимум 3 минуты на одну сессию. Проверяй актуальные ограничения: https://appetize.io/pricing . Для длинной защиты можно использовать удалённый Mac с Xcode через удалённый рабочий стол либо Mac в университете. Успех сборки в Actions не подтверждает успешный запуск на Appetize: после загрузки нужно отдельно проверить приложение.

Workflow также сохраняет **Lab6-project** с исходниками и сгенерированным Xcode-проектом (для лабораторных 2–6), лог сборки и XCTest `.xcresult`. Проект открывается на удалённом Mac. Подпись Apple Developer для запуска сборки в iOS Simulator/Appetize не требуется; это не IPA для установки на физический iPhone.

Если Actions отключены для форка: Actions → I understand my workflows, go ahead and enable them, затем повтори запуск. Логи тестов доступны в шаге Build and test. Проверяй, что выбран запуск нужной лабораторной и последнего коммита.

Официальные инструкции: https://docs.appetize.io/platform/app-management/uploading-apps/ios и https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job .

Артефакт **Lab6-preview** содержит Preview.png — снимок реально запущенного приложения после успешных тестов. Его можно открыть на Windows без Appetize. Это статичный снимок, интерактивный запуск доступен через Appetize.
