# Lab 8 — Ignatev Alexey — K4140

SwiftLint установлен и запускается на macOS. База приложения — «СериалПолка» из лабораторной 7. Проверяются все Swift-файлы в Sources, Tests и UITests, включая три unit-теста и два UI-теста.

## Запуск на Mac

```bash
brew install swiftlint xcodegen
cd SerialShelf/Lab8
bash Scripts/lint.sh
```

Для просмотра JSON-отчёта: `bash Scripts/lint.sh --reporter json`. Ключ `--strict` уже включён: предупреждения тоже приводят к неуспешному завершению. `--no-cache` обеспечивает полную проверку.

Обычные правила SwiftLint включены. Дополнительно включены `empty_count` и `sorted_imports`. Порог длины строки настроен на 140/180 символов для SwiftUI и XCTest; комментарии, URL и интерполированные строки не оцениваются по этому правилу. Исключений для собственных исходников и комментариев `swiftlint:disable` нет.

SwiftFormat использован для первоначального форматирования. Он не заменяет SwiftLint. Настройка форматтера находится в `.swiftformat`. Для повторного форматирования при необходимости: `brew install swiftformat`, затем `swiftformat Sources Tests UITests`. Исправляемые SwiftLint нарушения можно обработать командой `swiftlint lint --fix`, после неё обязательно повторить обычную проверку.

## Xcode и CI

`xcodegen generate` создаёт SerialShelf.xcodeproj. В приложении настроен шаг SwiftLint перед сборкой. Если инструмент не установлен, сборка выдаст явную ошибку с командой установки. На симуляторе: схема SerialShelf, Cmd+R — запуск, Cmd+U — тесты.

Workflow `.github/workflows/serial-shelf-lint.yml` устанавливает инструменты на Mac, запускает строгую проверку и XCTest. При ручном запуске параметр fix по умолчанию выключен: проверка не исправляет исходники незаметно.

На Windows можно открыть проект и отчёты в PyCharm. Проверка и сборка iOS выполнены на Mac через GitHub Actions. Сам PyCharm не заменяет Xcode и SwiftLint.

Источник инструкции установки и настройки: https://github.com/realm/SwiftLint
