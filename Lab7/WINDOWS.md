# Лабораторная 7 с Windows

Для запуска XCTest и просмотра результата свой Mac и Appetize не нужны: тесты исполняются на облачном Mac GitHub Actions.

1. Открой https://github.com/BogdanKur/ITMO-iOS-2026/actions/workflows/lab-7.yml .
2. Выбери успешный запуск **Lab 7** ветки `lab-7` или основной ветки `main`.
3. Открой шаг **Run XCTest**: три unit-теста и два UI-теста должны завершиться без ошибок.
4. В Artifacts скачай **Lab7-screens**, распакуй архив и открой PNG в Windows. Эти снимки сделаны UI-тестами в настоящем iOS Simulator.
5. **Lab7-test-results** содержит tests.log и coverage.txt, которые читаются обычным текстовым редактором. Папка TestResults.xcresult открывается в Xcode на Mac.

Исходники открывай в VS Code. [README](README.md) содержит таблицу тестов и вопросы для защиты. **Lab7-project** содержит готовый Xcode-проект и исходники для Mac университета или удалённого Mac. **Lab7-simulator** содержит архив нативного приложения для iOS Simulator; он не запускается локально на Windows и не устанавливается на физический iPhone.

Для интерактивного использования приложения без Appetize нужен доступ к Mac с Xcode либо отдельная сборка IPA для настоящего iPhone/iPad. На Windows можно продемонстрировать исходники тестов, логи и скриншоты.
