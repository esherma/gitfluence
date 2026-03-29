import SwiftUI

struct PRListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoadingPRs {
                loadingView
            } else if appState.prs.isEmpty {
                emptyView
            } else {
                prList
            }
        }
        .task {
            if appState.prs.isEmpty {
                await appState.loadPRs()
            }
        }
    }

    // MARK: -

    private var prList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(appState.prs) { pr in
                    PRRow(pr: pr)
                        .background(appState.selectedPR?.id == pr.id
                                    ? Color.gfAccent.opacity(0.08)
                                    : Color.clear)
                        .onTapGesture {
                            Task { await appState.selectPR(pr) }
                        }
                    Divider().padding(.leading, 12)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView().scaleEffect(0.8)
            Text("Loading PRs…")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.pull")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
            Text("No open pull requests")
                .font(Typography.body)
                .foregroundStyle(.secondary)
            Button("Refresh") { Task { await appState.loadPRs() } }
                .font(Typography.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.gfAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct PRRow: View {
    let pr: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("#\(pr.number)  \(pr.title)")
                .font(Typography.bodyMedium)
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("\(pr.headRefName) → \(pr.baseRefName)")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Text(pr.author.login)
                .font(Typography.caption)
                .foregroundStyle(.gfTextTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
