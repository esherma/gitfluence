import SwiftUI

struct CommentComposerView: View {
    let pr: PullRequest
    let pending: AppState.PendingComment
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var isSubmitting = false
    @State private var submitError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Add comment")
                        .font(Typography.title2)
                    Text("\(pending.filePath):\(pending.line)")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }

            // Text input
            TextEditor(text: $text)
                .font(Typography.body)
                .frame(minHeight: 100, maxHeight: 240)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gfBorder, lineWidth: 1)
                )

            // Error
            if let err = submitError {
                Text(err)
                    .font(Typography.caption)
                    .foregroundStyle(.red)
            }

            // Actions
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 4)
                Button("Submit comment") {
                    Task { await submit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 260)
    }

    private func submit() async {
        isSubmitting = true
        submitError  = nil
        defer { isSubmitting = false }
        do {
            try await appState.submitComment(
                body: text,
                pr: pr,
                path: pending.filePath,
                line: pending.line,
                side: pending.side
            )
            dismiss()
        } catch {
            submitError = error.localizedDescription
        }
    }
}
