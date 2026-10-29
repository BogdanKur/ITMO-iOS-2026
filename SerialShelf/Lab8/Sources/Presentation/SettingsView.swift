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
                Label("Лабораторная 8", systemImage: "graduationcap")
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
