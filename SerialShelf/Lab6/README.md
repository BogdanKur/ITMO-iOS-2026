# Лабораторная 6 — Alamofire, GET/POST и ошибки

**Ignatev Alexey · K4140 · СериалПолка**

Каталог загружается GET-запросом из TVmaze, отзыв отправляется POST-запросом в JSONPlaceholder. Ключи и регистрация не требуются. Транспорт, HTTP/JSON и состояние экранов разделены. JSONPlaceholder не сохраняет отзыв: постоянный личный комментарий хранится отдельно в SwiftData.

## Запуск на Mac

Из этой папки: `brew install xcodegen`, затем `xcodegen generate`. Откройте `SerialShelf.xcodeproj`, выберите iPhone Simulator и схему **SerialShelf**. Run — Cmd+R, Test — Cmd+U. Требуется Xcode с iOS 17+ SDK; облачные записи используют Xcode 26.

## Windows

Откройте исходники в PyCharm/VS Code как папку и смотрите приложенное MP4. Это настоящий iOS-проект: Windows не запускает SwiftUI или iPhone Simulator. Платные эмуляторы и API-ключи не нужны. Для сборки используйте Mac или GitHub Actions в своём форке.

## Материалы защиты

`DEFENSE.md` — речь по каждому файлу, причины решений и вопросы. `DEFENSE.html` — та же инструкция для браузера. Окончательные таймкоды появятся в `VIDEO-TIMELINE.md` после монтажа. Видео открывает каждый Swift-файл целиком; прокрутка перекрывает соседние фрагменты.
