import SwiftUI

@Observable
@MainActor
final class AppState {

    // MARK: - Repository state
    var repository: Repository?
    var fileTree:   [GitFile] = []
    var branches:   [Branch]  = []
    var currentBranch: Branch?

    // MARK: - Selection
    var selectedFile: GitFile?

    // MARK: - View state
    enum ViewMode: String, CaseIterable { case rich, source }
    var viewMode: ViewMode = .rich

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

    // MARK: - Close repository

    func closeRepository() {
        repository    = nil
        fileTree      = []
        branches      = []
        currentBranch = nil
        selectedFile  = nil
        errorMessage  = nil
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
