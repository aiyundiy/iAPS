import Foundation

enum FontTracking: String, JSON, Identifiable, CaseIterable, Codable {
    var id: String { rawValue }

    case tighter
    case tight
    case normal
    case wide

    var displayName: String {
        switch self {
        case .tighter:
            NSLocalizedString("更紧密的口气", comment: "")
        case .tight:
            NSLocalizedString("紧身饰面", comment: "")
        case .normal:
            NSLocalizedString("正常换带", comment: "")
        case .wide:
            NSLocalizedString("宽阔的路线", comment: "")
        }
    }

    var value: Double {
        switch self {
        case .tighter: -0.07
        case .tight: -0.04
        case .normal: 0
        case .wide: 0.04
        }
    }
}
