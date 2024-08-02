import SwiftUI
import Swinject

extension StatConfig {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        private var glucoseFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            if state.units == .mmolL {
                formatter.maximumFractionDigits = 1
            }
            formatter.roundingMode = .halfUp
            return formatter
        }

        private var carbsFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter
        }

        private var insulinFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        var body: some View {
            Form {
                Section {
                    Toggle("Display Chart X - Grid lines", isOn: $state.xGridLines)
                    Toggle("Display Chart Y - Grid lines", isOn: $state.yGridLines)
                    Toggle("Display Chart Threshold lines for Low and High", isOn: $state.rulerMarks)
                    Toggle("Standing / Laying TIR Chart", isOn: $state.oneDimensionalGraph)
                    HStack {
                        Text("水平滚动视图可见时间")
                        Spacer()
                        DecimalTextField("6", value: $state.hours, formatter: carbsFormatter)
                        Text("小时").foregroundColor(.secondary)
                    }
                    Toggle("Use insulin bars", isOn: $state.useInsulinBars)
                    HStack {
                        Text("金额不足时隐藏推注量字符串")
                        Spacer()
                        DecimalTextField("0.2", value: $state.minimumSMB, formatter: insulinFormatter)
                        Text("U").foregroundColor(.secondary)
                    }
                    Toggle("Display Time Interval Setting Button", isOn: $state.timeSettings)

                } header: { Text("家庭图表设置") }

                Section {
                    Toggle("Display Temp Targets Button", isOn: $state.useTargetButton)
                } header: { Text("家用按钮面板") }
                footer: { Text("如果您同时使用配置文件和临时目标") }

                Section {
                    Toggle("Never display the small glucose chart when scrolling", isOn: $state.skipGlucoseChart)
                    Toggle("Always Color Glucose Value (green, yellow etc)", isOn: $state.alwaysUseColors)
                } header: { Text("标题设置") }
                footer: { Text("通常，血糖仅在高/低的通知极限上或以下时才有色红色") }

                Section {
                    HStack {
                        Text("低的")
                        Spacer()
                        DecimalTextField("0", value: $state.low, formatter: glucoseFormatter)
                        Text(state.units.rawValue).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("高的")
                        Spacer()
                        DecimalTextField("0", value: $state.high, formatter: glucoseFormatter)
                        Text(state.units.rawValue).foregroundColor(.secondary)
                    }
                    Toggle("Override HbA1c Unit", isOn: $state.overrideHbA1cUnit)

                } header: { Text("统计设置") }

                Section {
                    Toggle("Skip Bolus screen after carbs", isOn: $state.skipBolusScreenAfterCarbs)
                    Toggle("Display and allow Fat and Protein entries", isOn: $state.useFPUconversion)
                } header: { Text("添加餐景设置") }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationBarTitle("UI/UX")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(trailing: Button("Close", action: state.hideModal))
        }
    }
}
