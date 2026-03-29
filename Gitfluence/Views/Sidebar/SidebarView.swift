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
                sectionPicker
                Divider()
            }

            // Section content
            if appState.isLoadingRepo {
                loadingView
            } else if appState.repository != nil {
                switch appState.sidebarSection {
                case .files:
                    if appState.fileTree.isEmpty {
                        emptyTreeView
                    } else {
                        FileTreeView(selectedID: $selectedID)
                    }
                case .pullRequests:
                    PRListView()
                }
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

    // MARK: - Section picker

    @ViewBuilder
    private var sectionPicker: some View {
        @Bindable var state = appState
        Picker("Section", selection: $state.sidebarSection) {
            Text("Files").tag(AppState.SidebarSection.files)
            Text("Pull Requests").tag(AppState.SidebarSection.pullRequests)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
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
