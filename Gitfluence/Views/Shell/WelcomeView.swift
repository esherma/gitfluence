import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                colors: [Color(hex: "F0F4FF"), Color(hex: "FAFAFA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer().frame(height: 40)
                openButton
                Spacer()
                footer
            }
            .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sections

    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0066FF"), Color(hex: "6B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: .gfAccent.opacity(0.3), radius: 16, x: 0, y: 6)

                Image(systemName: "doc.richtext")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("Gitfluence")
                    .font(Typography.largeTitle)
                    .foregroundStyle(.gfTextPrimary)

                Text("Rich document editing, powered by Git")
                    .font(Typography.body)
                    .foregroundStyle(.gfTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var openButton: some View {
        VStack(spacing: 12) {
            Button {
                appState.openRepositoryDialog()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Open Repository…")
                        .font(Typography.bodyMedium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 11)
                .frame(minWidth: 200)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0066FF"), Color(hex: "0050CC")],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .shadow(color: .gfAccent.opacity(0.35), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Text("⌘O")
                .font(Typography.captionMedium)
                .foregroundStyle(.gfTextTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.gfBackgroundSecondary, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    private var footer: some View {
        Text("One repository at a time  ·  Backed by Git")
            .font(Typography.caption)
            .foregroundStyle(.gfTextTertiary)
            .padding(.bottom, 24)
    }
}
