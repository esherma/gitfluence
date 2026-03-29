import Foundation

enum GitHubService {

    // MARK: - Pull Requests

    static func openPRs(in repo: Repository) async throws -> [PullRequest] {
        let json = try await ProcessRunner.run(
            ["gh", "pr", "list",
             "--json", "number,title,headRefName,baseRefName,author,updatedAt,state,headRefOid",
             "--state", "open"],
            cwd: repo.rootURL
        )
        return try JSONDecoder().decode([PullRequest].self, from: Data(json.utf8))
    }

    /// Unified diff patch for a whole PR (all files).
    static func diff(pr: PullRequest, in repo: Repository) async throws -> String {
        return try await ProcessRunner.run(
            ["gh", "pr", "diff", "\(pr.number)", "--patch"],
            cwd: repo.rootURL
        )
    }

    // MARK: - Review Comments

    static func comments(pr: PullRequest, in repo: Repository) async throws -> [PRComment] {
        let json = try await ProcessRunner.run(
            ["gh", "api",
             "repos/{owner}/{repo}/pulls/\(pr.number)/comments",
             "--paginate"],
            cwd: repo.rootURL
        )
        return try JSONDecoder().decode([PRComment].self, from: Data(json.utf8))
    }

    /// Post a new inline review comment on a PR.
    @discardableResult
    static func addComment(
        to pr: PullRequest,
        body: String,
        path: String,
        line: Int,
        side: String,
        in repo: Repository
    ) async throws -> PRComment {
        let json = try await ProcessRunner.run(
            ["gh", "api",
             "repos/{owner}/{repo}/pulls/\(pr.number)/comments",
             "-X", "POST",
             "-f", "body=\(body)",
             "-f", "path=\(path)",
             "-F", "line=\(line)",
             "-f", "side=\(side)",
             "-f", "commit_id=\(pr.headRefOid)"],
            cwd: repo.rootURL
        )
        return try JSONDecoder().decode(PRComment.self, from: Data(json.utf8))
    }
}
