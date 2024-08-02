import SwiftUI
import Swinject

extension WatchConfig {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        var body: some View {
            Form {
                Section(header: Text("Apple Watch")) {
                    Picker(
                        selection: $state.selectedAwConfig,
                        label: Text("在监视上显示")
                    ) {
                        ForEach(AwConfig.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                }

                Toggle("Display Protein & Fat", isOn: $state.displayFatAndProteinOnWatch)

                Toggle("Confirm Bolus Faster", isOn: $state.confirmBolusFaster)

                Section {
                    Toggle("Profile Overrides Button / Temp Targets Button", isOn: $state.profilesOrTempTargets)
                } header: { Text("显示过度或临时目标") }

                Section(header: Text("Garmin手表")) {
                    List {
                        ForEach(state.devices, id: \.uuid) { device in
                            Text(device.friendlyName)
                        }
                        .onDelete(perform: onDelete)
                    }
                    Button("Add devices") {
                        state.selectGarminDevices()
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Watch Configuration")
            .navigationBarTitleDisplayMode(.automatic)
        }

        private func onDelete(offsets: IndexSet) {
            state.devices.remove(atOffsets: offsets)
            state.deleteGarminDevice()
        }
    }
}
