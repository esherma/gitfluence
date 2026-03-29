import SwiftUI

/// Hosts whichever editor is active (rich or source), loads file content,
/// and saves on ⌘S. Preserves markdown content across mode switches.
struct FileEditorView: View {
    let file: GitFile
    @Environment(AppState.self) private var appState

    @State private var markdown:  String = ""
    @State private var isDirty:   Bool   = false
    @State private var isLoading: Bool   = true
    @State private var saveError: String?
    @State private var fileDiff:  String = ""

    var body: some View {
        ZStack {
            // ── Active editor / diff ───────────────────────────────────────
            Group {
                switch appState.viewMode {
                case .rich:
                    RichEditorView(markdown: $markdown)
                case .source:
                    SourceEditorView(markdown: $markdown)
                case .diff:
                    DiffView(diff: fileDiff)
                }
            }
            .opacity(isLoading ? 0 : 1)

            // ── Loading spinner ────────────────────────────────────────────
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gfBackground)
            }

            // ── Save-error banner ──────────────────────────────────────────
            if let err = saveError {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                        Text(err).font(Typography.bodyMedium).foregroundStyle(.white)
                        Spacer()
                        Button { saveError = nil } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "DC2626"))
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .background(Color.gfBackground)
        // ── Load file when selection changes ───────────────────────────────
        .task(id: file.id) {
            await loadFile()
        }
        // ── Mark dirty on every edit ───────────────────────────────────────
        .onChange(of: markdown) { _, _ in
            if !isLoading { isDirty = true }
        }
        // ── Load diff when switching to diff mode ──────────────────────────
        .onChange(of: appState.viewMode) { _, newMode in
            if newMode == .diff && fileDiff.isEmpty {
                Task { await loadDiff() }
            }
        }
        // ── ⌘S to save ────────────────────────────────────────────────────
        .background {
            Button("Save") { Task { await saveFile() } }
                .keyboardShortcut("s", modifiers: .command)
                .hidden()
        }
        // ── Toolbar items ──────────────────────────────────────────────────
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Text(file.name)
                        .font(Typography.bodySemibold)
                        .foregroundStyle(.primary)
                    if isDirty {
                        Circle()
                            .fill(Color.gfStatusModified)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                ViewModeToggle(showDiff: file.status != nil)

                Button {
                    Task { await saveFile() }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Save  ⌘S")
                .disabled(!isDirty || appState.viewMode == .diff)
            }
        }
    }

    // MARK: - Load / Save

    private func loadFile() async {
        isLoading = true
        isDirty   = false
        saveError = nil
        fileDiff  = ""
        defer { isLoading = false }

        do {
            markdown = try await GitService.fileContents(at: file.url)
        } catch {
            saveError = "Could not load file: \(error.localizedDescription)"
            markdown  = ""
        }
    }

    private func loadDiff() async {
        guard let repo = appState.repository else { return }
        fileDiff = (try? await GitService.diff(
            relativePath: file.relativePath, in: repo
        )) ?? ""
    }

    private func saveFile() async {
        guard isDirty else { return }
        do {
            try markdown.write(to: file.url, atomically: true, encoding: .utf8)
            isDirty   = false
            saveError = nil
            // Refresh git status badges
            await appState.refreshFileTree()
        } catch {
            saveError = "Could not save: \(error.localizedDescription)"
        }
    }
}
