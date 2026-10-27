import Foundation
import Combine

@MainActor final class AnalysisViewModel: ObservableObject {
    @Published private(set) var matches: [LibraryEntry] = []
    @Published private(set) var statistics: ShelfStatistics?
    @Published private(set) var searching = false
    @Published private(set) var calculating = false
    private var searchGeneration = 0
    private var statisticsGeneration = 0

    func search(_ entries: [LibraryEntry], query: String) async {
        searchGeneration += 1
        let generation = searchGeneration
        searching = true
        let task = Task.detached(priority: .userInitiated) {
            try ShelfAnalysis.search(entries, query: query)
        }
        defer { if generation == searchGeneration { searching = false } }
        do {
            let result = try await withTaskCancellationHandler(operation: { try await task.value },
                onCancel: { task.cancel() })
            try Task.checkCancellation()
            guard generation == searchGeneration else { return }
            matches = result
        } catch { /* Cancellation keeps the last completed result. */ }
    }

    func calculate(_ entries: [LibraryEntry]) async {
        statisticsGeneration += 1
        let generation = statisticsGeneration
        calculating = true
        let task = Task.detached(priority: .utility) { try ShelfAnalysis.statistics(entries) }
        defer { if generation == statisticsGeneration { calculating = false } }
        do {
            let result = try await withTaskCancellationHandler(operation: { try await task.value },
                onCancel: { task.cancel() })
            try Task.checkCancellation()
            guard generation == statisticsGeneration else { return }
            statistics = result
        } catch { /* Both workers check cancellation inside their loops. */ }
    }
}
