import SwiftUI

/// Segmented rich / source toggle for the detail toolbar.
/// Wired up to AppState.viewMode; the actual mode-switching logic
/// lives in Phase 2 editors — this provides the visual control.
struct ViewModeToggle: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Picker("View mode", selection: $state.viewMode) {
            Text("Rich").tag(AppState.ViewMode.rich)
            Text("Source").tag(AppState.ViewMode.source)
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
        .help("Toggle between rich and source editing modes")
    }
}
