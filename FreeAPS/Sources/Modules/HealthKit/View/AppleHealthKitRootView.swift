import SwiftUI
import Swinject

extension AppleHealthKit {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        var body: some View {
            Form {
                Section {
                    Toggle("Connect to Apple Health", isOn: $state.useAppleHealth)
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                        Text(
                            "This allows iAPS to read from and write to Apple Heath. You must also give permissions in Settings > Health > Data Access. If you enter a glucose value into Apple Health, open iAPS to confirm it shows up."
                        )
                        .font(.caption)
                    }
                    .foregroundColor(Color.secondary)
                    if state.needShowInformationTextForSetPermissions {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("对于苹果健康的写数据，您必须在设置>健康>数据访问中授予权限")
                                .font(.caption)
                        }
                        .foregroundColor(Color.secondary)
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
}
