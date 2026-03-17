import SwiftUI

@main
struct GitfluenceApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 560)
                .task {
                    // Restore previously opened repository on launch
                    await appState.restoreLastRepository()
                }
        }
        .defaultSize(width: 1280, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Repository…") {
                    appState.openRepositoryDialog()
                }
                .keyboardShortcut("o", modifiers: .command)

                if appState.repository != nil {
                    Button("Close Repository") {
                        appState.closeRepository()
                    }
                    .keyboardShortcut("w", modifiers: [.command, .shift])
                }
            }
            CommandGroup(after: .toolbar) {
                Button("Refresh File Tree") {
                    Task { await appState.refreshFileTree() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(appState.repository == nil)
            }
        }
    }
}
