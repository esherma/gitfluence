import SwiftUI

/// Phase 1: plain source text preview.
/// Will be replaced in Phase 2 with RichEditorView / SourceEditorView.
struct FilePreviewView: View {
    let file: GitFile
    @Environment(AppState.self) private var appState

    @State private var content: String?
    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        ZStack {
            Color.gfBackground.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let err = loadError {
                errorView(err)
            } else if let text = content {
                textView(text)
            }
        }
        .task(id: file.id) {
            await loadContent()
        }
    }

    // MARK: - Sub-views

    private func textView(_ text: String) -> some View {
        ScrollView {
            Text(text)
                .font(Typography.code)
                .foregroundStyle(.gfTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .textSelection(.enabled)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.gfStatusDeleted)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(.gfTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading

    private func loadContent() async {
        guard !file.isDirectory else { return }
        isLoading = true
        loadError = nil
        content   = nil
        defer { isLoading = false }

        do {
            content = try await GitService.fileContents(at: file.url)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
