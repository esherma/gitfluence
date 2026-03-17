import SwiftUI

enum Typography {
    // Display
    static let largeTitle   = Font.system(size: 26, weight: .semibold, design: .default)
    static let title        = Font.system(size: 20, weight: .semibold, design: .default)
    static let title2       = Font.system(size: 17, weight: .semibold, design: .default)

    // Body
    static let bodyLarge    = Font.system(size: 15, weight: .regular, design: .default)
    static let body         = Font.system(size: 13, weight: .regular, design: .default)
    static let bodyMedium   = Font.system(size: 13, weight: .medium,  design: .default)
    static let bodySemibold = Font.system(size: 13, weight: .semibold, design: .default)

    // UI chrome
    static let label        = Font.system(size: 13, weight: .regular, design: .default)
    static let labelMedium  = Font.system(size: 13, weight: .medium,  design: .default)
    static let caption      = Font.system(size: 11, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .medium, design: .default)

    // Sidebar
    static let sidebarItem   = Font.system(size: 13, weight: .regular, design: .default)
    static let sidebarHeader = Font.system(size: 10, weight: .semibold, design: .default)

    // Code / monospaced
    static let code         = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let codeSmall    = Font.system(size: 11, weight: .regular, design: .monospaced)
}
