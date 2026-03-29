import SwiftUI

struct FileTreeView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedID: String?

    var body: some View {
        List(appState.fileTree, children: \.optionalChildren, selection: $selectedID) { file in
            FileTreeRow(file: file)
                .tag(file.id)
        }
        .listStyle(.sidebar)
        .onChange(of: selectedID) { _, newID in
            guard let newID else {
                appState.selectedFile = nil
                return
            }
            let found = appState.findFile(id: newID)
            // Only allow selecting leaf files, not directories
            if let found, !found.isDirectory {
                appState.selectedFile = found
                appState.selectedPR   = nil   // clear PR when navigating to a file
            } else {
                // Clicked a directory — deselect it so it only expands/collapses
                if found?.isDirectory == true {
                    selectedID = nil
                    appState.selectedFile = nil
                }
            }
        }
        .onChange(of: appState.selectedFile) { _, file in
            // Keep selectedID in sync if the file changes externally
            if selectedID != file?.id {
                selectedID = file?.id
            }
        }
    }
}

// MARK: - Helpers

private extension GitFile {
    /// Returns children for directories, nil for leaf files.
    /// An empty children array is collapsed to nil so List doesn't
    /// render an expand arrow for empty directories.
    var optionalChildren: [GitFile]? {
        guard isDirectory, let children, !children.isEmpty else { return nil }
        return children
    }
}
