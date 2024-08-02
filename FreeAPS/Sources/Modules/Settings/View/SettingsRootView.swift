import HealthKit
import SwiftUI
import Swinject

extension Settings {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State private var showShareSheet = false

        @FetchRequest(
            entity: VNr.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)], predicate: NSPredicate(
                format: "nr != %@", "" as String
            )
        ) var fetchedVersionNumber: FetchedResults<VNr>

        var body: some View {
            Form {
                Section {
                    Toggle("Closed loop", isOn: $state.closedLoop)
                }
                header: {
                    VStack(alignment: .leading) {
                        if let expirationDate = Bundle.main.profileExpiration {
                            Text(
                                "iAPS v\(state.versionNumber) (\(state.buildNumber))\nBranch: \(state.branch) \(state.copyrightNotice)" +
                                    "\nBuild Expires: " + expirationDate
                            ).textCase(nil)
                        } else {
                            Text(
                                "iAPS v\(state.versionNumber) (\(state.buildNumber))\nBranch: \(state.branch) \(state.copyrightNotice)"
                            )
                        }

                        if let latest = fetchedVersionNumber.first,
                           ((latest.nr ?? "") > state.versionNumber) ||
                           ((latest.nr ?? "") < state.versionNumber && (latest.dev ?? "") > state.versionNumber)
                        {
                            Text(
                                "Latest version on GitHub: " +
                                    ((latest.nr ?? "") < state.versionNumber ? (latest.dev ?? "") : (latest.nr ?? "")) + "\n"
                            )
                            .foregroundStyle(.orange).bold()
                            .multilineTextAlignment(.leading)
                        }
                    }
                }

                Section {
                    Text("泵").navigationLink(to: .pumpConfig, from: self)
                    Text("CGM").navigationLink(to: .cgm, from: self)
                    Text("手表").navigationLink(to: .watch, from: self)
                } header: { Text("设备") }

                Section {
                    Text("Nightscout").navigationLink(to: .nighscoutConfig, from: self)
                    if HKHealthStore.isHealthDataAvailable() {
                        Text("苹果健康").navigationLink(to: .healthkit, from: self)
                    }
                    Text("通知").navigationLink(to: .notificationsConfig, from: self)
                } header: { Text("服务") }

                Section {
                    Text("泵设置").navigationLink(to: .pumpSettingsEditor, from: self)
                    Text("基础率设置").navigationLink(to: .basalProfileEditor, from: self)
                    Text("胰岛素敏感性").navigationLink(to: .isfEditor, from: self)
                    Text("碳水化合物比率").navigationLink(to: .crEditor, from: self)
                    Text("血糖").navigationLink(to: .targetsEditor, from: self)
                } header: { Text("配置") }

                Section {
                    Text("打开APS").navigationLink(to: .preferencesEditor, from: self)
                    Text("自动").navigationLink(to: .autotuneConfig, from: self)
                } header: { Text("打开APS") }

                Section {
                    Text("UI/UX").navigationLink(to: .statisticsConfig, from: self)
                    Text("应用图标").navigationLink(to: .iconConfig, from: self)
                    Text("推注计算器").navigationLink(to: .bolusCalculatorConfig, from: self)
                    Text("脂肪和蛋白质转化").navigationLink(to: .fpuConfig, from: self)
                    Text("动态ISF").navigationLink(to: .dynamicISF, from: self)
                    Text("分享").navigationLink(to: .sharing, from: self)
                    Text("联系图像").navigationLink(to: .contactTrick, from: self)
                } header: { Text("额外功能") }

                Section {
                    Toggle("Debug options", isOn: $state.debugOptions)
                    if state.debugOptions {
                        Group {
                            HStack {
                                Text("NS上传配置文件和设置")
                                Button("Upload") { state.uploadProfileAndSettings(true) }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .buttonStyle(.borderedProminent)
                            }
                            /*
                             HStack {
                                 Text("删除所有NS覆盖")
                                 Button("Delete") { state.deleteOverrides() }
                                     .frame(maxWidth: .infinity, alignment: .trailing)
                                     .buttonStyle(.borderedProminent)
                                     .tint(.red)
                             }*/

                            HStack {
                                Toggle("Ignore flat CGM readings", isOn: $state.disableCGMError)
                            }
                        }
                        Group {
                            Text("优先")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.preferences), from: self)
                            Text("泵设置")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.settings), from: self)
                            Text("自动志")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.autosense), from: self)
                            Text("泵历史")
                                .navigationLink(to: .configEditor(file: OpenAPS.Monitor.pumpHistory), from: self)
                            Text("基础率设置")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.basalProfile), from: self)
                            Text("目标范围")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.bgTargets), from: self)
                            Text("临时目标")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.tempTargets), from: self)
                            Text("进餐")
                                .navigationLink(to: .configEditor(file: OpenAPS.Monitor.meal), from: self)
                        }

                        Group {
                            Text("泵轮廓")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.pumpProfile), from: self)
                            Text("轮廓")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.profile), from: self)
                            Text("碳水化合物")
                                .navigationLink(to: .configEditor(file: OpenAPS.Monitor.carbHistory), from: self)
                            Text("颁布")
                                .navigationLink(to: .configEditor(file: OpenAPS.Enact.enacted), from: self)
                            Text("公告")
                                .navigationLink(to: .configEditor(file: OpenAPS.FreeAPS.announcements), from: self)
                            Text("颁布公告")
                                .navigationLink(to: .configEditor(file: OpenAPS.FreeAPS.announcementsEnacted), from: self)
                            Text("覆盖未上传")
                                .navigationLink(to: .configEditor(file: OpenAPS.Nightscout.notUploadedOverrides), from: self)
                            Text("自动")
                                .navigationLink(to: .configEditor(file: OpenAPS.Settings.autotune), from: self)
                            Text("血糖")
                                .navigationLink(to: .configEditor(file: OpenAPS.Monitor.glucose), from: self)
                        }

                        Group {
                            Text("目标预设")
                                .navigationLink(to: .configEditor(file: OpenAPS.FreeAPS.tempTargetsPresets), from: self)
                            Text("校准")
                                .navigationLink(to: .configEditor(file: OpenAPS.FreeAPS.calibrations), from: self)
                            Text("中间件")
                                .navigationLink(to: .configEditor(file: OpenAPS.Middleware.determineBasal), from: self)
                            Text("统计数据")
                                .navigationLink(to: .configEditor(file: OpenAPS.Monitor.statistics), from: self)
                            Text("编辑设置JSON")
                                .navigationLink(to: .configEditor(file: OpenAPS.FreeAPS.settings), from: self)
                        }
                    }
                } header: { Text("开发人员") }

                Section {
                    Toggle("Animated Background", isOn: $state.animatedBackground)
                }

                Section {
                    Text("共享日志")
                        .onTapGesture {
                            showShareSheet = true
                        }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: state.logItems())
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Close", action: state.hideSettingsModal))
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear(perform: { state.uploadProfileAndSettings(false) })
        }
    }
}
