# Просмотр с Windows

Исходники открываются в VS Code: File → Open Folder → Lab1. Xcode, SwiftUI и iOS Simulator локально на Windows недоступны. Установка Swift на Windows позволяет запускать консольную Lab1, но не SwiftUI-приложения.

1. Открой https://github.com/BogdanKur/ITMO-iOS-2026/actions и workflow **Lab 1**. Выбери запуск своей ветки с зелёным статусом.
2. Скачай артефакт Lab1-results: demo.txt содержит вывод, tests.txt — лог XCTest.
3. Для интерактивного приложения открой лабораторную 2–6 и её артефакт.

Appetize Free на момент подготовки: 30 минут в месяц, максимум 3 минуты на одну сессию. Проверяй актуальные ограничения: https://appetize.io/pricing . Для длинной защиты можно использовать удалённый Mac с Xcode через удалённый рабочий стол либо Mac в университете. Успех сборки в Actions не подтверждает успешный запуск на Appetize: после загрузки нужно отдельно проверить приложение.

Workflow также сохраняет **Lab1-project** с исходниками и сгенерированным Xcode-проектом (для лабораторных 2–6), лог сборки и XCTest `.xcresult`. Проект открывается на удалённом Mac. Подпись Apple Developer для запуска сборки в iOS Simulator/Appetize не требуется; это не IPA для установки на физический iPhone.

Если Actions отключены для форка: Actions → I understand my workflows, go ahead and enable them, затем повтори запуск. Логи тестов доступны в шаге Build and test. Проверяй, что выбран запуск нужной лабораторной и последнего коммита.

Официальные инструкции: https://docs.appetize.io/platform/app-management/uploading-apps/ios и https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job .
