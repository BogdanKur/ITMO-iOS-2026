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

## Повторный запуск на Windows

Docker Desktop и официальный образ `ghcr.io/realm/swiftlint:0.65.1` уже использованы на этом компьютере. С запущенным Docker Desktop из папки лабораторной выполните в PowerShell:

```powershell
.\Scripts\lint-windows.ps1
.\Scripts\lint-windows.ps1 -Json
```

В контейнер подключается только папка этой лабораторной, только для чтения. Проверка не меняет исходники. Версия SwiftLint закреплена. Это полноценный запуск SwiftLint в Linux-контейнере на Windows; PyCharm используется для просмотра и редактирования кода. Такой запуск не собирает iOS-приложение и не запускает iPhone Simulator.

Итог: 23 Swift-файла, 0 нарушений, код завершения 0. Первоначальный прогон на Mac нашёл 13 нарушений (7 statement_position и 6 sorted_imports); исправления сохранены в исходниках. Дополнительная сборка iOS и XCTest настроены в GitHub Actions, но пока ожидают Mac-исполнитель. Тесты прошлой версии не выдаются за новый прогон.

Источник инструкции установки и настройки: https://github.com/realm/SwiftLint
