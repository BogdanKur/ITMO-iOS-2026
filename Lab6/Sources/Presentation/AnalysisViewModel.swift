import Foundation
import Combine
@MainActor final class AnalysisViewModel: ObservableObject {
    @Published private(set) var matches: [Note] = []
    @Published private(set) var statistics: NoteStatistics?
    @Published private(set) var searching = false
    @Published private(set) var calculating = false
    @Published var errorMessage: String?
    // Detached tasks get immutable Sendable snapshots, never ModelContext or SwiftUI state.
    func search(notes: [Note], query: String) async {
        searching = true
        let worker = Task.detached(priority: .userInitiated) { try NoteAnalysis.search(notes, query: query) }
        do {
            let result = try await withTaskCancellationHandler(operation: { try await worker.value },
                onCancel: { worker.cancel() })
            try Task.checkCancellation()
            matches = result; searching = false
        } catch is CancellationError { /* A newer SwiftUI .task owns the loading state. */ }
        catch { errorMessage = error.localizedDescription; searching = false }
    }
    func calculate(notes: [Note]) async {
        calculating = true
        let worker = Task.detached(priority: .utility) { try NoteAnalysis.statistics(notes) }
        do {
            let result = try await withTaskCancellationHandler(operation: { try await worker.value },
                onCancel: { worker.cancel() })
            try Task.checkCancellation()
            statistics = result; calculating = false
        } catch is CancellationError { }
        catch { errorMessage = error.localizedDescription; calculating = false }
    }
}
