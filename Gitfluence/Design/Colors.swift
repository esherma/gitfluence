import SwiftUI

// MARK: - Color palette
// Define as Color statics AND as ShapeStyle where Self == Color so that
// .foregroundStyle(.gfAccent) shorthand works (same pattern Apple uses for .blue, .red, etc.)

extension Color {
    static let gfAccent          = Color(hex: "0066FF")
    static let gfAccentSecondary = Color(hex: "6B5CF6")
    static let gfTextPrimary     = Color(hex: "111111")
    static let gfTextSecondary   = Color(hex: "6B7280")
    static let gfTextTertiary    = Color(hex: "9CA3AF")
    static let gfBackground          = Color(hex: "FFFFFF")
    static let gfBackgroundSecondary = Color(hex: "F7F7F8")
    static let gfBorder              = Color(hex: "E5E7EB")
    static let gfBorderLight         = Color(hex: "F0F0F2")
    static let gfStatusModified  = Color(hex: "F59E0B")
    static let gfStatusAdded     = Color(hex: "10B981")
    static let gfStatusDeleted   = Color(hex: "EF4444")
    static let gfStatusUntracked = Color(hex: "6B7280")
    static let gfStatusStaged    = Color(hex: "0066FF")
    static let gfStatusRenamed   = Color(hex: "8B5CF6")
    static let gfDiffAdd         = Color(hex: "DCFCE7")
    static let gfDiffAddText     = Color(hex: "166534")
    static let gfDiffRemove      = Color(hex: "FEE2E2")
    static let gfDiffRemoveText  = Color(hex: "991B1B")
    static let gfDiffHunk        = Color(hex: "EFF6FF")
    static let gfDiffHunkText    = Color(hex: "1E40AF")
}

// ShapeStyle extensions so .foregroundStyle(.gfAccent) etc. compile without
// writing Color.gfAccent everywhere.
extension ShapeStyle where Self == Color {
    static var gfAccent:          Color { .init(hex: "0066FF") }
    static var gfAccentSecondary: Color { .init(hex: "6B5CF6") }
    static var gfTextPrimary:     Color { .init(hex: "111111") }
    static var gfTextSecondary:   Color { .init(hex: "6B7280") }
    static var gfTextTertiary:    Color { .init(hex: "9CA3AF") }
    static var gfBackground:          Color { .init(hex: "FFFFFF") }
    static var gfBackgroundSecondary: Color { .init(hex: "F7F7F8") }
    static var gfBorder:              Color { .init(hex: "E5E7EB") }
    static var gfStatusModified:  Color { .init(hex: "F59E0B") }
    static var gfStatusAdded:     Color { .init(hex: "10B981") }
    static var gfStatusDeleted:   Color { .init(hex: "EF4444") }
    static var gfStatusUntracked: Color { .init(hex: "6B7280") }
    static var gfStatusStaged:    Color { .init(hex: "0066FF") }
    static var gfStatusRenamed:   Color { .init(hex: "8B5CF6") }
    static var gfDiffAdd:         Color { .init(hex: "DCFCE7") }
    static var gfDiffHunk:        Color { .init(hex: "EFF6FF") }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 200, 200, 200)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - GitStatus → Color

extension GitStatus {
    var color: Color {
        switch self {
        case .modified:  return .gfStatusModified
        case .added:     return .gfStatusAdded
        case .deleted:   return .gfStatusDeleted
        case .untracked: return .gfStatusUntracked
        case .staged:    return .gfStatusStaged
        case .renamed:   return .gfStatusRenamed
        }
    }
}
