# ITMO iOS 2026 — Ignatev Alexey — K4140

Все семь работ собираются в основной ветке `main`. Работы сдаются отдельными PR в репозиторий преподавателя `skipperprivate/ITMO-iOS-2026`. Первые шесть идут из веток `lab-1`–`lab-6`, седьмая — из отдельной ветки `lab-7-submission`. Приложение — **StudyNotes**: сеть реализована в [Lab6](Lab6), версия с тремя unit-тестами и двумя UI-тестами находится в [Lab7](Lab7).

| Лаба | Решение | PR |
| --- | --- | --- |
| 1 | [Коллекции, геометрия, двоичная куча](Lab1) | [#58](https://github.com/skipperprivate/ITMO-iOS-2026/pull/58) |
| 2 | [Два экрана и случайное число](Lab2) | [#59](https://github.com/skipperprivate/ITMO-iOS-2026/pull/59) |
| 3 | [MVVM, Repository, Dependency Injection](Lab3) | [#60](https://github.com/skipperprivate/ITMO-iOS-2026/pull/60) |
| 4 | [SwiftData + UserDefaults, CRUD](Lab4) | [#61](https://github.com/skipperprivate/ITMO-iOS-2026/pull/61) |
| 5 | [Два фоновых вычисления](Lab5) | [#62](https://github.com/skipperprivate/ITMO-iOS-2026/pull/62) |
| 6 | [Alamofire, GET/POST, итоговое приложение](Lab6) | [#63](https://github.com/skipperprivate/ITMO-iOS-2026/pull/63) |
| 7 | [XCTest: 3 unit-теста и 2 UI-теста](Lab7) | [#64](https://github.com/skipperprivate/ITMO-iOS-2026/pull/64) |

## Открыть с Windows

Для лабораторной 7 **Appetize не нужен**: [workflow Lab 7](https://github.com/BogdanKur/ITMO-iOS-2026/actions/workflows/lab-7.yml) запускает все пять тестов на облачном Mac и выдаёт логи, отчёт покрытия и PNG из UI-сценариев. [Инструкция](Lab7/WINDOWS.md).

1. [Actions](https://github.com/BogdanKur/ITMO-iOS-2026/actions) → **Lab 6** → последний зелёный запуск своей ветки.
2. Artifacts → **Lab6-simulator**. Распакуй внешний архив GitHub; внутри **StudyNotes-simulator.zip**.
3. Зарегистрируйся на [Appetize](https://appetize.io), загрузи внутренний zip, запусти приложение в браузере. Это нативная SwiftUI-сборка в облачном iOS Simulator. Free: 30 минут в месяц, сессия до 3 минут; тариф нужно проверить перед защитой.
4. **Lab6-preview** — PNG первого экрана, **Lab6-screens** — снимки сценария защиты, **Lab6-project** — исходники и готовый Xcode-проект для удалённого Mac. XCTest-логи и `.xcresult` — в **Lab6-test-results**.

Подробнее: [инструкция для Windows](Lab6/WINDOWS.md). Сам Xcode и SwiftUI локально на Windows не запускаются. Для консольной первой лабораторной существует [Swift для Windows](https://www.swift.org/install/windows/).

## Подготовка к защите

Прочитай [сценарий и вопросы](DEFENSE.md), затем README каждой лабораторной. Запусти приложение в Appetize заранее и проверь CRUD, сохранение, поиск, GET и POST. Облачная сборка не является проверкой совместимости с конкретным устройством Appetize. Без аккаунта Appetize отдельная интерактивная ссылка не создаётся.

Задание лабораторной 8 пока не предоставлено, её исходная папка не изменена.
