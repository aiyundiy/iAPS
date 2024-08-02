import CoreData
import SwiftUI
import Swinject

extension AddTempTarget {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State private var isPromptPresented = false
        @State private var isRemoveAlertPresented = false
        @State private var removeAlert: Alert?
        @State private var isEditing = false

        @FetchRequest(
            entity: TempTargetsSlider.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        ) var isEnabledArray: FetchedResults<TempTargetsSlider>

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            return formatter
        }

        var body: some View {
            Form {
                if !state.presets.isEmpty {
                    Section(header: Text("预设")) {
                        ForEach(state.presets) { preset in
                            presetView(for: preset)
                        }
                    }
                }

                HStack {
                    Text("实验")
                    Toggle(isOn: $state.viewPercantage) {}.controlSize(.mini)
                    Image(systemName: "figure.highintensity.intervaltraining")
                    Image(systemName: "fork.knife")
                }

                if state.viewPercantage {
                    Section {
                        VStack {
                            Text("\(state.percentage.formatted(.number)) % Insulin")
                                .foregroundColor(isEditing ? .orange : .blue)
                                .font(.largeTitle)
                                .padding(.vertical)
                            Slider(
                                value: $state.percentage,
                                in: 15 ...
                                    min(Double(state.maxValue * 100), 200),
                                step: 1,
                                onEditingChanged: { editing in
                                    isEditing = editing
                                }
                            )
                            // Only display target slider when not 100 %
                            if state.percentage != 100 {
                                Spacer()
                                Divider()
                                Text(
                                    (
                                        state
                                            .units == .mmolL ?
                                            "\(state.computeTarget().asMmolL.formatted(.number.grouping(.never).rounded().precision(.fractionLength(1)))) mmol/L" :
                                            "\(state.computeTarget().formatted(.number.grouping(.never).rounded().precision(.fractionLength(0)))) mg/dl"
                                    )
                                        + NSLocalizedString("血糖", comment: "")
                                )
                                .foregroundColor(.green)
                                .padding(.vertical)

                                Slider(
                                    value: $state.hbt,
                                    in: 101 ... 295,
                                    step: 1
                                ).accentColor(.green)
                            }
                        }
                    }
                } else {
                    Section(header: Text("自定义")) {
                        HStack {
                            Text("目标")
                            Spacer()
                            DecimalTextField("0", value: $state.low, formatter: formatter, cleanInput: true)
                            Text(state.units.rawValue).foregroundColor(.secondary)
                        }
                        HStack {
                            Text("期间")
                            Spacer()
                            DecimalTextField("0", value: $state.duration, formatter: formatter, cleanInput: true)
                            Text("分钟").foregroundColor(.secondary)
                        }
                        DatePicker("Date", selection: $state.date)
                        Button { isPromptPresented = true }
                        label: { Text("保存为预设") }
                    }
                }
                if state.viewPercantage {
                    Section {
                        HStack {
                            Text("期间")
                            Spacer()
                            DecimalTextField("0", value: $state.duration, formatter: formatter, cleanInput: true)
                            Text("分钟").foregroundColor(.secondary)
                        }
                        DatePicker("Date", selection: $state.date)
                        Button { isPromptPresented = true }
                        label: { Text("保存为预设") }
                            .disabled(state.duration == 0)
                    }
                }

                Section {
                    Button { state.enact() }
                    label: { Text("开始") }
                    Button { state.cancel() }
                    label: { Text("取消临时目标") }
                }
            }
            .popover(isPresented: $isPromptPresented) {
                Form {
                    Section(header: Text("输入预设名称")) {
                        TextField("Name", text: $state.newPresetName)
                        Button {
                            state.save()
                            isPromptPresented = false
                        }
                        label: { Text("保存") }
                        Button { isPromptPresented = false }
                        label: { Text("取消") }
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear {
                configureView()
                state.hbt = isEnabledArray.first?.hbt ?? 160
            }
            .navigationTitle("Enact Temp Target")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close", action: state.hideModal))
        }

        private func presetView(for preset: TempTarget) -> some View {
            var low = preset.targetBottom
            var high = preset.targetTop
            if state.units == .mmolL {
                low = low?.asMmolL
                high = high?.asMmolL
            }
            return HStack {
                VStack {
                    HStack {
                        Text(preset.displayName)
                        Spacer()
                    }
                    HStack(spacing: 2) {
                        Text(
                            "\(formatter.string(from: (low ?? 0) as NSNumber)!) - \(formatter.string(from: (high ?? 0) as NSNumber)!)"
                        )
                        .foregroundColor(.secondary)
                        .font(.caption)

                        Text(state.units.rawValue)
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("为了")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(formatter.string(from: preset.duration as NSNumber)!)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("最小")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Spacer()
                    }.padding(.top, 2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    state.enactPreset(id: preset.id)
                }

                Image(systemName: "xmark.circle").foregroundColor(.secondary)
                    .contentShape(Rectangle())
                    .padding(.vertical)
                    .onTapGesture {
                        removeAlert = Alert(
                            title: Text("你确定吗？"),
                            message: Text("Delete preset \"\(preset.displayName)\""),
                            primaryButton: .destructive(Text("删除"), action: { state.removePreset(id: preset.id) }),
                            secondaryButton: .cancel()
                        )
                        isRemoveAlertPresented = true
                    }
                    .alert(isPresented: $isRemoveAlertPresented) {
                        removeAlert!
                    }
            }
        }
    }
}
