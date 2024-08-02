//
//  G7SettingsView.swift
//  CGMBLEKitUI
//
//  Created by Pete Schwamb on 9/25/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import SwiftUI
import G7SensorKit
import LoopKitUI

struct G7SettingsView: View {

    private var durationFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    @Environment(\.guidanceColors) private var guidanceColors
    @Environment(\.glucoseTintColor) private var glucoseTintColor

    var didFinish: (() -> Void)
    var deleteCGM: (() -> Void)
    @ObservedObject var viewModel: G7SettingsViewModel

    @State private var showingDeletionSheet = false

    init(didFinish: @escaping () -> Void, deleteCGM: @escaping () -> Void, viewModel: G7SettingsViewModel) {
        self.didFinish = didFinish
        self.deleteCGM = deleteCGM
        self.viewModel = viewModel
    }

    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter
    }()

    var body: some View {
        List {
            Section() {
                VStack {
                    headerImage
                    progressBar
                }
            }
            if let activatedAt = viewModel.activatedAt {
                HStack {
                    Text(LocalizedString("传感器启动", comment: "title for g7 settings row showing sensor start time"))
                    Spacer()
                    Text(timeFormatter.string(from: activatedAt))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(LocalizedString("传感器到期", comment: "title for g7 settings row showing sensor expiration time"))
                    Spacer()
                    Text(timeFormatter.string(from: activatedAt.addingTimeInterval(G7Sensor.lifetime)))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(LocalizedString("宽限期结束", comment: "title for g7 settings row showing sensor grace period end time"))
                    Spacer()
                    Text(timeFormatter.string(from: activatedAt.addingTimeInterval(G7Sensor.lifetime + G7Sensor.gracePeriod)))
                        .foregroundColor(.secondary)
                }
            }

            Section(LocalizedString("最后读", comment: "")) {
                LabeledValueView(label: LocalizedString("血糖", comment: "Field label"),
                                 value: viewModel.lastGlucoseString)
                LabeledDateView(label: LocalizedString("时间", comment: "Field label"),
                                date: viewModel.latestReadingTimestamp,
                                dateFormatter: viewModel.dateFormatter)
                LabeledValueView(label: LocalizedString("趋势", comment: "Field label"),
                                 value: viewModel.lastGlucoseTrendString)
            }

            Section(LocalizedString("蓝牙", comment: "")) {
                if let name = viewModel.sensorName {
                    HStack {
                        Text(LocalizedString("姓名", comment: "title for g7 settings row showing BLE Name"))
                        Spacer()
                        Text(name)
                            .foregroundColor(.secondary)
                    }
                }
                if viewModel.scanning {
                    HStack {
                        Text(LocalizedString("扫描", comment: "title for g7 settings connection status when scanning"))
                        Spacer()
                        SwiftUI.ProgressView()
                    }
                } else {
                    if viewModel.connected {
                        Text(LocalizedString("连接的", comment: "title for g7 settings connection status when connected"))
                    } else {
                        HStack {
                            Text(LocalizedString("连接", comment: "title for g7 settings connection status when connecting"))
                            Spacer()
                            SwiftUI.ProgressView()
                        }
                    }
                }
                if let lastConnect = viewModel.lastConnect {
                    LabeledValueView(label: LocalizedString("最后一个连接", comment: "title for g7 settings row showing sensor last connect time"),
                                     value: timeFormatter.string(from: lastConnect))
                }
            }

            Section(LocalizedString("配置", comment: "")) {
                HStack {
                    Toggle(LocalizedString("上传读数", comment: "title for g7 config settings to upload readings"), isOn: $viewModel.uploadReadings)
                }
            }

            Section () {
                if !self.viewModel.scanning {
                    Button(LocalizedString("扫描新传感器", comment: ""), action: {
                        self.viewModel.scanForNewSensor()
                    })
                }

                deleteCGMButton
            }
        }
        .insetGroupedListStyle()
        .navigationBarItems(trailing: doneButton)
        .navigationBarTitle(LocalizedString("Dexcom G7", comment: "Navigation bar title for G7SettingsView"))
    }

    private var deleteCGMButton: some View {
        Button(action: {
            showingDeletionSheet = true
        }, label: {
            Text(LocalizedString("删除CGM", comment: "Button label for removing CGM"))
                .foregroundColor(.red)
        }).actionSheet(isPresented: $showingDeletionSheet) {
            ActionSheet(
                title: Text("您确定要删除此CGM吗？"),
                buttons: [
                    .destructive(Text("删除CGM")) {
                        self.deleteCGM()
                    },
                    .cancel(),
                ]
            )
        }
    }

    private var headerImage: some View {
        VStack(alignment: .center) {
            Image(frameworkImage: "g7")
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .frame(height: 150)
                .padding(.horizontal)
        }.frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.progressBarState.label)
                    .font(.system(size: 17))
                    .foregroundColor(color(for: viewModel.progressBarState.labelColor))

                Spacer()
                if let referenceDate = viewModel.progressReferenceDate {
                    Text(durationFormatter.localizedString(for: referenceDate, relativeTo: Date()))
                        .foregroundColor(.secondary)
                }
            }
            ProgressView(value: viewModel.progressBarProgress)
                .accentColor(color(for: viewModel.progressBarColorStyle))
        }
    }

    private func color(for colorStyle: ColorStyle) -> Color {
        switch colorStyle {
        case .glucose:
            return glucoseTintColor
        case .warning:
            return guidanceColors.warning
        case .critical:
            return guidanceColors.critical
        case .normal:
            return .primary
        case .dimmed:
            return .secondary
        }
    }


    private var doneButton: some View {
        Button("Done", action: {
            self.didFinish()
        })
    }

}
