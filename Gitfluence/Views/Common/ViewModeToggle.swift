import SwiftUI

/// Segmented rich / source / diff toggle for the editor toolbar.
/// Pass `showDiff: true` when the current file has git changes so the
/// Diff segment appears. Wired to AppState.viewMode.
struct ViewModeToggle: View {
    var showDiff: Bool = false
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Picker("View mode", selection: $state.viewMode) {
            Text("Rich").tag(AppState.ViewMode.rich)
            Text("Source").tag(AppState.ViewMode.source)
            if showDiff {
                Text("Diff").tag(AppState.ViewMode.diff)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: showDiff ? 180 : 120)
        .help("Toggle view mode")
        // If diff mode was active but the file no longer has changes, revert
        .onChange(of: showDiff) { _, newValue in
            if !newValue && state.viewMode == .diff {
                state.viewMode = .rich
            }
        }
    }
}
