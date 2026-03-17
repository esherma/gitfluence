import Foundation

struct Repository: Sendable, Identifiable {
    var id: String { rootURL.path }
    let name: String
    let rootURL: URL
}
