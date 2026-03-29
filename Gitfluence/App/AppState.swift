import SwiftUI

@Observable
@MainActor
final class AppState {

    // MARK: - Repository state
    var repository: Repository?
    var fileTree:   [GitFile] = []
    var branches:   [Branch]  = []
    var currentBranch: Branch?

    // MARK: - Sidebar section
    enum SidebarSection { case files, pullRequests }
    var sidebarSection: SidebarSection = .files

    // MARK: - Selection
    var selectedFile: GitFile?
    var selectedPR:   PullRequest?

    // MARK: - View state
    enum ViewMode: String, CaseIterable { case rich, source, diff }
    var viewMode: ViewMode = .rich

    // MARK: - Pull Requests
    var prs:            [PullRequest] = []
    var isLoadingPRs:   Bool = false
    var prDiff:         String = ""
    var prComments:     [PRComment] = []
    var isLoadingPRData: Bool = false

    // Pending comment (set when user clicks "+" on a diff line)
    struct PendingComment: Identifiable, Equatable {
        var id: String { "\(filePath):\(line):\(side)" }
        let filePath: String
        let line: Int
        let side: String
    }
    var pendingComment: PendingComment?

    // MARK: - Loading / error
    var isLoadingRepo  = false
    var isLoadingTree  = false
    var errorMessage:  String?

    // MARK: - Open repository

    func openRepositoryDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles        = false
        panel.canChooseDirectories  = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a git repository folder"
        panel.prompt  = "Open"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Store a security-scoped bookmark so the repo can be re-opened after relaunch
        saveBookmark(for: url)
        _ = url.startAccessingSecurityScopedResource()

        Task { await loadRepository(at: url) }
    }

    func loadRepository(at url: URL) async {
        isLoadingRepo = true
        errorMessage  = nil
        defer { isLoadingRepo = false }

        do {
            let repo = try await GitService.openRepository(at: url)
            // Load tree + branches concurrently
            async let treeResult    = GitService.fileTree(in: repo)
            async let branchResult  = GitService.branches(in: repo)
            async let currentResult = GitService.currentBranch(in: repo)

            let (tree, branchList, current) = try await (treeResult, branchResult, currentResult)

            self.repository    = repo
            self.fileTree      = tree
            self.branches      = branchList
            self.currentBranch = current
            self.selectedFile  = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh file tree

    func refreshFileTree() async {
        guard let repo = repository else { return }
        isLoadingTree = true
        defer { isLoadingTree = false }
        do {
            fileTree = try await GitService.fileTree(in: repo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Branch switching

    func switchBranch(to branch: Branch) async {
        guard let repo = repository else { return }
        do {
            try await GitService.checkout(branch: branch, in: repo)
            currentBranch = branch
            selectedFile  = nil
            fileTree = try await GitService.fileTree(in: repo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Pull Requests

    func loadPRs() async {
        guard let repo = repository else { return }
        isLoadingPRs = true
        defer { isLoadingPRs = false }
        do {
            prs = try await GitHubService.openPRs(in: repo)
        } catch {
            errorMessage = "Could not load PRs: \(error.localizedDescription)"
        }
    }

    func selectPR(_ pr: PullRequest) async {
        guard let repo = repository else { return }
        selectedPR = pr
        selectedFile = nil
        prDiff = ""
        prComments = []
        isLoadingPRData = true
        defer { isLoadingPRData = false }
        do {
            async let diffResult     = GitHubService.diff(pr: pr, in: repo)
            async let commentsResult = GitHubService.comments(pr: pr, in: repo)
            let (d, c) = try await (diffResult, commentsResult)
            prDiff     = d
            prComments = c
        } catch {
            errorMessage = "Could not load PR data: \(error.localizedDescription)"
        }
    }

    func submitComment(body: String, pr: PullRequest, path: String, line: Int, side: String) async throws {
        guard let repo = repository else { return }
        let comment = try await GitHubService.addComment(
            to: pr, body: body, path: path, line: line, side: side, in: repo
        )
        prComments.append(comment)
        pendingComment = nil
    }

    // MARK: - Close repository

    func closeRepository() {
        repository      = nil
        fileTree        = []
        branches        = []
        currentBranch   = nil
        selectedFile    = nil
        selectedPR      = nil
        prs             = []
        prDiff          = ""
        prComments      = []
        pendingComment  = nil
        errorMessage    = nil
        sidebarSection  = .files
    }

    // MARK: - Security-scoped bookmark persistence

    private let bookmarkKey = "lastRepoBookmark"

    private func saveBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    func restoreLastRepository() async {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Re-save updated bookmark
                saveBookmark(for: url)
            }
            _ = url.startAccessingSecurityScopedResource()
            await loadRepository(at: url)
        } catch {
            // Bookmark stale / deleted — clear it silently
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    // MARK: - Helpers

    func findFile(id: String?, in tree: [GitFile]? = nil) -> GitFile? {
        guard let id else { return nil }
        let source = tree ?? fileTree
        for file in source {
            if file.id == id { return file }
            if let children = file.children, let found = findFile(id: id, in: children) {
                return found
            }
        }
        return nil
    }

    func dismissError() {
        errorMessage = nil
    }
}
