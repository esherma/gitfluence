import SwiftUI

/// Small coloured dot indicating a file's git status.
struct StatusBadge: View {
    let status: GitStatus

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 7, height: 7)
            .help(statusHelp)
    }

    private var statusHelp: String {
        switch status {
        case .modified:  return "Modified"
        case .added:     return "Added (staged)"
        case .deleted:   return "Deleted"
        case .untracked: return "Untracked"
        case .staged:    return "Staged"
        case .renamed:   return "Renamed"
        }
    }
}
