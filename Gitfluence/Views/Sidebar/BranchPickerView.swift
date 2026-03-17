import SwiftUI

struct BranchPickerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Menu {
            ForEach(appState.branches) { branch in
                Button {
                    Task { await appState.switchBranch(to: branch) }
                } label: {
                    if branch.name == appState.currentBranch?.name {
                        Label(branch.name, systemImage: "checkmark")
                    } else {
                        Text(branch.name)
                    }
                }
            }
            if appState.branches.isEmpty {
                Text("No branches found")
                    .foregroundStyle(.secondary)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 10, weight: .medium))
                Text(appState.currentBranch?.name ?? "—")
                    .font(Typography.captionMedium)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .disabled(appState.isLoadingRepo || appState.branches.isEmpty)
    }
}
