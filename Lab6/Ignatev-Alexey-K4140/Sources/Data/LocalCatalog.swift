import Foundation

enum LocalCatalog {
    static func load(bundle: Bundle = .main) throws -> [Show] {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Show].self, from: Data(contentsOf: url))
    }
}
