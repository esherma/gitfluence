import SwiftUI

struct FileTreeRow: View {
    let file: GitFile

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: file.systemImage)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 16, alignment: .center)

            Text(file.name)
                .font(Typography.sidebarItem)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            if let status = file.status {
                StatusBadge(status: status)
            }
        }
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        if file.isDirectory {
            return Color(hex: "4A90D9") // folder blue
        }
        switch file.url.pathExtension.lowercased() {
        case "md", "mdx", "markdown": return .gfAccent
        case "swift":                 return Color(hex: "FA7343") // Swift orange
        case "json", "yaml", "yml":   return Color(hex: "F59E0B") // amber
        case "js", "ts":              return Color(hex: "F7DF1E") // JS yellow (darkened)
        case "tsx", "jsx":            return Color(hex: "61DAFB") // React blue
        default:                      return .gfTextTertiary
        }
    }
}
