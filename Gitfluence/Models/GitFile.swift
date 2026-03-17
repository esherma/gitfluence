import Foundation

struct GitFile: Sendable, Identifiable, Hashable {
    var id: String { relativePath }

    let name: String
    let url: URL
    let relativePath: String
    let isDirectory: Bool
    // nil on leaf files; non-nil (even if empty) only on directories
    let children: [GitFile]?
    let status: GitStatus?

    // MARK: - Helpers

    var isMarkdown: Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "md" || ext == "mdx" || ext == "markdown"
    }

    var isTextFile: Bool {
        let textExtensions: Set<String> = [
            "md", "mdx", "markdown", "txt", "rst",
            "json", "yaml", "yml", "toml", "xml",
            "swift", "js", "ts", "jsx", "tsx", "py",
            "rb", "go", "rs", "c", "cpp", "h", "sh",
            "css", "html", "htm"
        ]
        return textExtensions.contains(url.pathExtension.lowercased())
    }

    /// SF Symbol name appropriate for this file's type/extension
    var systemImage: String {
        if isDirectory { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "md", "mdx", "markdown": return "doc.richtext.fill"
        case "txt", "rst":            return "doc.text.fill"
        case "json", "yaml", "yml", "toml": return "curlybraces"
        case "swift":                 return "swift"
        case "js", "ts", "jsx", "tsx": return "chevron.left.forwardslash.chevron.right"
        case "py":                    return "terminal.fill"
        case "png", "jpg", "jpeg", "gif", "svg", "webp": return "photo.fill"
        case "pdf":                   return "doc.fill"
        case "sh", "bash", "zsh":     return "terminal"
        default:                      return "doc.fill"
        }
    }
}

// MARK: -

enum GitStatus: Sendable, Hashable {
    case modified   // tracked, unstaged changes
    case added      // new file staged
    case deleted    // deleted
    case untracked  // not tracked by git
    case staged     // staged changes to existing file
    case renamed    // renamed

    var label: String {
        switch self {
        case .modified:  return "M"
        case .added:     return "A"
        case .deleted:   return "D"
        case .untracked: return "U"
        case .staged:    return "S"
        case .renamed:   return "R"
        }
    }
}
