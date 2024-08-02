import Foundation

enum FontWeight: String, JSON, Identifiable, CaseIterable, Codable {
    var id: String { rawValue }

    case light
    case regular
    case medium
    case semibold
    case bold
    case black

    var displayName: String {
        switch self {
        case .light:
            return NSLocalizedString("轻量轻量级", comment: "")
        case .regular:
            return NSLocalizedString("常规轻量级", comment: "")
        case .medium:
            return NSLocalizedString("中量级", comment: "")
        case .semibold:
            return NSLocalizedString("SemiboldFont量级", comment: "")
        case .bold:
            return NSLocalizedString("boldfont量级", comment: "")
        case .black:
            return NSLocalizedString("blackfont量级", comment: "")
        }
    }
}
