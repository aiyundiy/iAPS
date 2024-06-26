//
//  PumpAlarmPumpEvent.swift
//  RileyLink
//
//  Created by Pete Schwamb on 3/8/16.
//  Copyright © 2016 LoopKit Authors. All rights reserved.
//

import Foundation

public enum PumpAlarmType {
    case batteryOutLimitExceeded
    case noDelivery             
    case batteryDepleted
    case autoOff
    case deviceReset
    case deviceResetBatteryIssue17
    case deviceResetBatteryIssue21
    case reprogramError         
    case emptyReservoir         
    case unknownType(rawType: UInt8)

    init(rawType: UInt8) {
        switch rawType {
        case 3:
            self = .batteryOutLimitExceeded
        case 4:
            self = .noDelivery
        case 5:
            self = .batteryDepleted
        case 6:
            self = .autoOff 
        case 16:
            self = .deviceReset
        case 17:
            self = .deviceResetBatteryIssue17
        case 21:
            self = .deviceResetBatteryIssue21
        case 61:
            self = .reprogramError
        case 62:
            self = .emptyReservoir
        default:
            self = .unknownType(rawType: rawType)
        }
    }
}

extension PumpAlarmType {
    var localizedString: String {
        switch self {
        case .autoOff:
            return LocalizedString("自动警报", comment: "Title for PumpAlarmType.autoOff")
        case .batteryOutLimitExceeded:
            return LocalizedString("电池限制", comment: "Title for PumpAlarmType.batteryOutLimitExceeded")
        case .noDelivery:
            return LocalizedString("没有交互警报", comment: "Title for PumpAlarmType.noDelivery")
        case .batteryDepleted:
            return LocalizedString("电池耗尽", comment: "Title for PumpAlarmType.batteryDepleted")
        case .deviceReset:
            return LocalizedString("设备重置", comment: "Title for deviceReset")
        case .deviceResetBatteryIssue17:
            return LocalizedString("电池17", comment: "Title for PumpAlarmType.deviceResetBatteryIssue17")
        case .deviceResetBatteryIssue21:
            return LocalizedString("电池21", comment: "Title for PumpAlarmType.deviceResetBatteryIssue21")
        case .reprogramError:
            return LocalizedString("重编程错误", comment: "Title for PumpAlarmType.reprogramError")
        case .emptyReservoir:
            return LocalizedString("空储液器", comment: "Title for PumpAlarmType.emptyReservoir")
        case .unknownType:
            return LocalizedString("未知警报", comment: "Title for PumpAlarmType.unknownType")
        }
    }
}

public struct PumpAlarmPumpEvent: TimestampedPumpEvent {
    public let length: Int
    public let rawData: Data
    public let timestamp: DateComponents
    public let alarmType: PumpAlarmType

    public init?(availableData: Data, pumpModel: PumpModel) {
        length = 9
        
        guard length <= availableData.count else {
            return nil
        }

        rawData = availableData.subdata(in: 0..<length)
        
        alarmType = PumpAlarmType(rawType: availableData[1])
        
        timestamp = DateComponents(pumpEventData: availableData, offset: 4)
    }
    
    public var dictionaryRepresentation: [String: Any] {

        return [
            "_type": "AlarmPump",
            "alarm": "\(self.alarmType)",
        ]
    }
}
