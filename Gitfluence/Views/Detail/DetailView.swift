import SwiftUI

struct DetailView: View {
    let file: GitFile
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            fileHeader
            Divider()
            content
        }
        .background(Color.gfBackground)
    }

    // MARK: - Content routing

    @ViewBuilder
    private var content: some View {
        if file.isMarkdown {
            // Full rich/source editor
            FileEditorView(file: file)
        } else if file.isTextFile {
            // Source-only with notice
            VStack(spacing: 0) {
                richUnavailableBanner
                Divider()
                FilePreviewView(file: file)
            }
        } else {
            binaryFileView
        }
    }

    // MARK: - Header (breadcrumb + status)

    private var fileHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: file.systemImage)
                .font(.system(size: 13))
                .foregroundStyle(.gfAccent)

            breadcrumb

            Spacer()

            if let status = file.status {
                StatusBadge(status: status)
                Text(status.label)
                    .font(Typography.captionMedium)
                    .foregroundStyle(status.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gfBackgroundSecondary)
    }

    private var breadcrumb: some View {
        let parts = file.relativePath.components(separatedBy: "/")
        return HStack(spacing: 2) {
            ForEach(0..<parts.count, id: \.self) { idx in
                if idx > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.gfTextTertiary)
                }
                Text(parts[idx])
                    .font(Typography.caption)
                    .foregroundStyle(idx == parts.count - 1
                                     ? Color.gfTextPrimary
                                     : Color.gfTextTertiary)
            }
        }
    }

    // MARK: - Non-markdown banners / placeholders

    private var richUnavailableBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
            Text("Rich mode unavailable for this file type — showing source")
                .font(Typography.caption)
        }
        .foregroundStyle(Color.gfTextSecondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gfDiffHunk.opacity(0.5))
    }

    private var binaryFileView: some View {
        VStack(spacing: 12) {
            Image(systemName: file.systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.gfTextTertiary)
            Text("Preview unavailable")
                .font(Typography.title2)
                .foregroundStyle(Color.gfTextSecondary)
            Text("This file type cannot be displayed in Gitfluence.")
                .font(Typography.body)
                .foregroundStyle(Color.gfTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gfBackground)
    }
}
