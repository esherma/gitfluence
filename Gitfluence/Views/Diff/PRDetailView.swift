import SwiftUI

struct PRDetailView: View {
    let pr: PullRequest
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DiffView(
                diff: appState.prDiff,
                comments: appState.prComments,
                onCommentRequest: { path, line, side in
                    appState.pendingComment = .init(filePath: path, line: line, side: side)
                }
            )
            .opacity(appState.isLoadingPRData ? 0 : 1)

            if appState.isLoadingPRData {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading diff…")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gfBackground)
            }
        }
        .background(Color.gfBackground)
        .task(id: pr.id) {
            await appState.selectPR(pr)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(pr.title)
                        .font(Typography.bodySemibold)
                        .lineLimit(1)
                    Text("#\(pr.number) · \(pr.headRefName) → \(pr.baseRefName)")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await appState.selectPR(pr) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload diff")
                .disabled(appState.isLoadingPRData)
            }
        }
        .sheet(item: Binding(
            get:  { appState.pendingComment },
            set:  { appState.pendingComment = $0 }
        )) { pending in
            CommentComposerView(pr: pr, pending: pending)
        }
    }
}
