import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedID: String?

    var body: some View {
        ZStack {
            if appState.repository == nil && !appState.isLoadingRepo {
                WelcomeView()
            } else {
                mainLayout
            }

            // Error banner (overlays everything)
            if let message = appState.errorMessage {
                errorBanner(message)
            }

            // Full-screen loading overlay when switching repos
            if appState.isLoadingRepo {
                loadingOverlay
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: appState.repository == nil)
    }

    // MARK: - Main layout

    private var mainLayout: some View {
        NavigationSplitView {
            SidebarView(selectedID: $selectedID)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 340)
        } detail: {
            if let file = appState.selectedFile {
                DetailView(file: file)
            } else {
                emptyDetail
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Empty detail

    private var emptyDetail: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(.gfTextTertiary)
            Text("Select a file")
                .font(Typography.title2)
                .foregroundStyle(.gfTextSecondary)
            if let repo = appState.repository {
                Text(repo.name)
                    .font(Typography.caption)
                    .foregroundStyle(.gfTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gfBackground)
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 13))
                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer()
                Button {
                    appState.dismissError()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "DC2626"), in: Rectangle())
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(100)
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.gfBackground.opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(true)
            VStack(spacing: 12) {
                ProgressView()
                Text("Opening repository…")
                    .font(Typography.body)
                    .foregroundStyle(.gfTextSecondary)
            }
        }
    }
}
