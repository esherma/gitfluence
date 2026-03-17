import Foundation

enum GitServiceError: Error, LocalizedError {
    case notAGitRepository
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAGitRepository:
            return "The selected folder is not a git repository."
        case .commandFailed(let msg):
            return msg
        }
    }
}

enum GitService {

    // MARK: - Repository

    /// Validate a URL is a git repo root and return a Repository model.
    static func openRepository(at url: URL) async throws -> Repository {
        let raw = await ProcessRunner.runSilent(
            ["git", "-C", url.path, "rev-parse", "--show-toplevel"]
        )
        let rootPath = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rootPath.isEmpty else { throw GitServiceError.notAGitRepository }

        let rootURL = URL(fileURLWithPath: rootPath)
        return Repository(name: rootURL.lastPathComponent, rootURL: rootURL)
    }

    // MARK: - File tree

    static func fileTree(in repo: Repository) async throws -> [GitFile] {
        let statusOutput = await ProcessRunner.runSilent(
            ["git", "-C", repo.rootURL.path, "status", "--porcelain", "-u"],
            cwd: repo.rootURL
        )
        let statusMap = parseGitStatus(statusOutput)
        return buildFileTree(at: repo.rootURL, repoRoot: repo.rootURL, gitStatus: statusMap)
    }

    // MARK: - Branches

    static func branches(in repo: Repository) async throws -> [Branch] {
        let output = try await ProcessRunner.run(
            ["git", "-C", repo.rootURL.path, "branch", "--format=%(refname:short)"]
        )
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { Branch(name: $0) }
    }

    static func currentBranch(in repo: Repository) async throws -> Branch? {
        let output = try await ProcessRunner.run(
            ["git", "-C", repo.rootURL.path, "branch", "--show-current"]
        )
        let name = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : Branch(name: name)
    }

    // MARK: - Checkout

    static func checkout(branch: Branch, in repo: Repository) async throws {
        _ = try await ProcessRunner.run(
            ["git", "-C", repo.rootURL.path, "checkout", branch.name]
        )
    }

    // MARK: - File content

    static func fileContents(at url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    }

    // MARK: - Private helpers

    private static func parseGitStatus(_ output: String) -> [String: GitStatus] {
        var result: [String: GitStatus] = [:]
        for line in output.components(separatedBy: "\n") {
            guard line.count >= 3 else { continue }
            let chars   = Array(line)
            let x       = chars[0]  // staged status
            let y       = chars[1]  // unstaged status
            let path    = String(line.dropFirst(3))

            // Handle rename: "R  old -> new" — porcelain v1 uses "R old\0new"
            // For simplicity, take the last token after " -> " if present
            let resolvedPath = path.components(separatedBy: " -> ").last ?? path

            let status: GitStatus
            if x == "?" && y == "?" {
                status = .untracked
            } else if x == "R" || y == "R" {
                status = .renamed
            } else if x != " " && x != "?" {
                // Something staged
                if y != " " && y != "?" {
                    status = .modified // staged + unstaged changes
                } else {
                    status = .staged
                }
            } else if y == "M" {
                status = .modified
            } else if y == "D" {
                status = .deleted
            } else if y == "A" {
                status = .added
            } else {
                continue
            }
            result[resolvedPath] = status
        }
        return result
    }

    private static func buildFileTree(
        at url: URL,
        repoRoot: URL,
        gitStatus: [String: GitStatus]
    ) -> [GitFile] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents
            .filter { $0.lastPathComponent != ".git" }
            .sorted { a, b in
                let aDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let bDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if aDir != bDir { return aDir } // directories first
                return a.lastPathComponent.localizedCaseInsensitiveCompare(b.lastPathComponent) == .orderedAscending
            }
            .compactMap { itemURL -> GitFile? in
                let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                // relativePath is relative to repo root, with no leading slash
                let relativePath = String(itemURL.path.dropFirst(repoRoot.path.count + 1))

                if isDir {
                    let children = buildFileTree(at: itemURL, repoRoot: repoRoot, gitStatus: gitStatus)
                    return GitFile(
                        name: itemURL.lastPathComponent,
                        url: itemURL,
                        relativePath: relativePath,
                        isDirectory: true,
                        children: children,
                        status: nil
                    )
                } else {
                    return GitFile(
                        name: itemURL.lastPathComponent,
                        url: itemURL,
                        relativePath: relativePath,
                        isDirectory: false,
                        children: nil,
                        status: gitStatus[relativePath]
                    )
                }
            }
    }
}
