import SwiftUI
import Swinject

extension PumpSettingsEditor {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }

        var body: some View {
            Form {
                Section(header: Text("交互限制")) {
                    HStack {
                        Text("最大基础")
                        DecimalTextField("U/hr", value: $state.maxBasal, formatter: formatter)
                    }
                    HStack {
                        Text("Max Bolus")
                        DecimalTextField("U", value: $state.maxBolus, formatter: formatter)
                    }
                    HStack {
                        Text("最大碳水化合物")
                        DecimalTextField("g", value: $state.maxCarbs, formatter: formatter)
                    }
                }

                Section(header: Text("胰岛素作用的持续时间")) {
                    HStack {
                        Text("直径")
                        DecimalTextField("hours", value: $state.dia, formatter: formatter)
                    }
                }

                Section {
                    HStack {
                        if state.syncInProgress {
                            ProgressView().padding(.trailing, 10)
                        }
                        Button { state.save() }
                        label: {
                            Text(state.syncInProgress ? "Saving..." : "Save on Pump")
                        }
                        .disabled(state.syncInProgress)
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Pump Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
