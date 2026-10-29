import Foundation
import Combine

@MainActor final class RemoteCatalogViewModel: ObservableObject {
    @Published private(set) var shows: [Show] = []
    @Published private(set) var loading = false
    @Published private(set) var loaded = false
    @Published private(set) var error: String?
    private let service: any CatalogService
    private var generation = 0
    init(service: any CatalogService = CatalogAPI()) { self.service = service }

    func load(query: String) async {
        generation += 1
        let current = generation
        loading = true; error = nil
        defer { if current == generation { loading = false } }
        do {
            try await Task.sleep(for: .milliseconds(350))
            let result = try await service.shows(query: query)
            try Task.checkCancellation()
            guard current == generation else { return }
            shows = result; loaded = true
        } catch is CancellationError { }
        catch { if current == generation { self.error = error.localizedDescription } }
    }
}

@MainActor final class ReviewViewModel: ObservableObject {
    @Published private(set) var sending = false
    @Published private(set) var receipt: ReviewReceipt?
    @Published private(set) var error: String?
    private let service: any ReviewService
    init(service: any ReviewService = CatalogAPI()) { self.service = service }
    func send(show: Show, text: String) async {
        guard !sending else { return }
        sending = true; error = nil; receipt = nil
        defer { sending = false }
        do { receipt = try await service.sendReview(show: show, text: text) }
        catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}
