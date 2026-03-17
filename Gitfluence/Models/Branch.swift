import Foundation

struct Branch: Sendable, Identifiable, Hashable {
    var id: String { name }
    let name: String
}
