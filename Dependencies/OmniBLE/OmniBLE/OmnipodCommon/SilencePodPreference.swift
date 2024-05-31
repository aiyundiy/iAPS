//
//  SilencePodPreference.swift
//  OmniBLE
//
//  Created by Joe Moran on 8/30/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation

public enum SilencePodPreference: Int, CaseIterable {
    case disabled
    case enabled

    var title: String {
        switch self {
        case .disabled:
            return LocalizedString("禁用", comment: "Title string for SilencePodPreference.disabled")
        case .enabled:
            return LocalizedString("静音", comment: "Title string for SilencePodPreference.enabled")
        }
    }

    var description: String {
        switch self {
        case .disabled:
            return LocalizedString("正常操作模式，其中所有POD警报使用可听见的POD哔哔声以及启用了置信点时。", comment: "Description for SilencePodPreference.disabled")
        case .enabled:
            return LocalizedString("All Pod alerts use no beeps and confirmation reminder beeps are suppressed. The Pod will only beep for fatal Pod faults and when playing test beeps.\n\n⚠️Warning - Whenever the Pod is silenced it must be kept within Bluetooth range of this device to receive notifications for Pod alerts.", comment: "Description for SilencePodPreference.enabled")
        }
    }
}
