import Foundation

enum CGMType: String, JSON, CaseIterable, Identifiable {
    var id: String { rawValue }

    case nightscout
    case xdrip
    case dexcomG5
    case dexcomG6
    case dexcomG7
    case simulator
    case libreTransmitter
    case glucoseDirect
    case enlite

    var displayName: String {
        switch self {
        case .nightscout:
            return "Nightscout"
        case .xdrip:
            return "xDrip4iOS"
        case .glucoseDirect:
            return "Glucose Direct"
        case .dexcomG5:
            return "Dexcom G5"
        case .dexcomG6:
            return "Dexcom G6"
        case .dexcomG7:
            return "Dexcom G7"
        case .simulator:
            return NSLocalizedString("血糖模拟器", comment: "Glucose Simulator CGM type")
        case .libreTransmitter:
            return NSLocalizedString("Libre发射器", comment: "Libre Transmitter type")
        case .enlite:
            return "Medtronic Enlite"
        }
    }

    var appURL: URL? {
        switch self {
        case .enlite,
             .nightscout:
            return nil
        case .xdrip:
            return URL(string: "xdripswift://")!
        case .glucoseDirect:
            return URL(string: "libredirect://")!
        case .dexcomG5:
            return URL(string: "dexcomgcgm://")!
        case .dexcomG6:
            return URL(string: "dexcomg6://")!
        case .dexcomG7:
            return URL(string: "dexcomg7://")!
        case .simulator:
            return nil
        case .libreTransmitter:
            return URL(string: "freeaps-x://libre-transmitter")!
        }
    }

    var externalLink: URL? {
        switch self {
        case .xdrip:
            return URL(string: "https://github.com/JohanDegraeve/xdripswift")!
        case .glucoseDirect:
            return URL(string: "https://github.com/creepymonster/GlucoseDirectApp")!
        default: return nil
        }
    }

    var subtitle: String {
        switch self {
        case .nightscout:
            return NSLocalizedString("在线或内部服务器", comment: "Online or internal server")
        case .xdrip:
            return NSLocalizedString(
                "Using shared app group with external CGM app xDrip4iOS",
                comment: "Shared app group xDrip4iOS"
            )
        case .dexcomG5:
            return NSLocalizedString("本机G5应用程序", comment: "Native G5 app")
        case .dexcomG6:
            return NSLocalizedString("Dexcom G6应用程序", comment: "Dexcom G6 app")
        case .dexcomG7:
            return NSLocalizedString("Dexcom G7应用", comment: "Dexcom G76 app")
        case .simulator:
            return NSLocalizedString("简单的模拟器", comment: "Simple simulator")
        case .libreTransmitter:
            return NSLocalizedString(
                "Direct connection with Libre 1 transmitters or European Libre 2 sensors",
                comment: "Direct connection with Libre 1 transmitters or European Libre 2 sensors"
            )
        case .glucoseDirect:
            return NSLocalizedString(
                "Using shared app group with external CGM app GlucoseDirect",
                comment: "Shared app group GlucoseDirect"
            )
        case .enlite:
            return NSLocalizedString("Minilink发射器", comment: "Minilink transmitter")
        }
    }
}

enum GlucoseDataError: Error {
    case noData
    case unreliableData
}
