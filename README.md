# ITMO iOS 2026 — лабораторные Богдана

Все шесть работ собираются в основной ветке `main`. Каждая лабораторная оформлена отдельным PR из ветки `lab-1`–`lab-6`. Итоговое приложение — **StudyNotes**, полный исходный код в [Lab6](Lab6).

| Лаба | Решение | PR |
| --- | --- | --- |
| 1 | [Коллекции, геометрия, двоичная куча](Lab1) | [#7](https://github.com/BogdanKur/ITMO-iOS-2026/pull/7) |
| 2 | [Два экрана и случайное число](Lab2) | [#8](https://github.com/BogdanKur/ITMO-iOS-2026/pull/8) |
| 3 | [MVVM, Repository, Dependency Injection](Lab3) | [#9](https://github.com/BogdanKur/ITMO-iOS-2026/pull/9) |
| 4 | [SwiftData + UserDefaults, CRUD](Lab4) | [#10](https://github.com/BogdanKur/ITMO-iOS-2026/pull/10) |
| 5 | [Два фоновых вычисления](Lab5) | [#11](https://github.com/BogdanKur/ITMO-iOS-2026/pull/11) |
| 6 | [Alamofire, GET/POST, итоговое приложение](Lab6) | [#12](https://github.com/BogdanKur/ITMO-iOS-2026/pull/12) |

## Открыть с Windows

1. [Actions](https://github.com/BogdanKur/ITMO-iOS-2026/actions) → **Lab 6** → последний зелёный запуск своей ветки.
2. Artifacts → **Lab6-simulator**. Распакуй внешний архив GitHub; внутри **StudyNotes-simulator.zip**.
3. Зарегистрируйся на [Appetize](https://appetize.io), загрузи внутренний zip, запусти приложение в браузере. Это нативная SwiftUI-сборка в облачном iOS Simulator. Free: 30 минут в месяц, сессия до 3 минут; тариф нужно проверить перед защитой.
4. **Lab6-preview** — PNG первого экрана, **Lab6-screens** — снимки сценария защиты, **Lab6-project** — исходники и готовый Xcode-проект для удалённого Mac. XCTest-логи и `.xcresult` — в **Lab6-test-results**.

Подробнее: [инструкция для Windows](Lab6/WINDOWS.md). Сам Xcode и SwiftUI локально на Windows не запускаются. Для консольной первой лабораторной существует [Swift для Windows](https://www.swift.org/install/windows/).

## Подготовка к защите

Прочитай [сценарий и вопросы](DEFENSE.md), затем README каждой лабораторной. Запусти приложение в Appetize заранее и проверь CRUD, сохранение, поиск, GET и POST. Облачная сборка не является проверкой совместимости с конкретным устройством Appetize. Без аккаунта Appetize отдельная интерактивная ссылка не создаётся.

Задания лабораторных 7–8 не предоставлены, их исходные папки не изменены.
