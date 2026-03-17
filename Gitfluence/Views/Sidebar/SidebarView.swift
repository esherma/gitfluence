import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedID: String?

    var body: some View {
        VStack(spacing: 0) {
            // Repo + branch header
            if let repo = appState.repository {
                repoHeader(repo)
                Divider()
            }

            // File tree or loading state
            if appState.isLoadingRepo {
                loadingView
            } else if appState.fileTree.isEmpty && appState.repository != nil {
                emptyTreeView
            } else if appState.repository != nil {
                FileTreeView(selectedID: $selectedID)
            }
        }
        .toolbar {
            if appState.repository != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await appState.refreshFileTree() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh file tree  ⇧⌘R")
                    .disabled(appState.isLoadingTree)
                }
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func repoHeader(_ repo: Repository) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(repo.name)
                .font(Typography.bodySemibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            BranchPickerView()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading…")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyTreeView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
            Text("No files")
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
