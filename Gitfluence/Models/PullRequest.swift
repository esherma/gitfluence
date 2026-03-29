import Foundation

struct PullRequest: Identifiable, Sendable, Codable, Equatable {
    let number: Int
    let title: String
    let headRefName: String
    let baseRefName: String
    let author: Author
    let updatedAt: String
    let state: String
    let headRefOid: String  // HEAD commit SHA — required for posting review comments

    var id: Int { number }

    struct Author: Codable, Sendable, Equatable {
        let login: String
    }
}

struct PRComment: Identifiable, Sendable, Codable, Equatable {
    let id: Int
    let body: String
    let path: String?
    let line: Int?
    let side: String?   // "LEFT" or "RIGHT"
    let user: User
    let createdAt: String
    let htmlUrl: String

    struct User: Codable, Sendable, Equatable {
        let login: String
    }

    enum CodingKeys: String, CodingKey {
        case id, body, path, line, side, user
        case createdAt = "created_at"
        case htmlUrl   = "html_url"
    }
}
