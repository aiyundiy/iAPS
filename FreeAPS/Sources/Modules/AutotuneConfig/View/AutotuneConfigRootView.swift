import SwiftUI
import Swinject

extension AutotuneConfig {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State var replaceAlert = false

        private var isfFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        private var rateFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }

        var body: some View {
            Form {
                Section {
                    Toggle("Use Autotune", isOn: $state.useAutotune)
                    if state.useAutotune {
                        Toggle("Only Autotune Basal Insulin", isOn: $state.onlyAutotuneBasals)
                    }
                }

                Section {
                    HStack {
                        Text("最后一步")
                        Spacer()
                        Text(dateFormatter.string(from: state.publishedDate))
                    }
                    Button { state.run() }
                    label: { Text("现在跑步") }
                }

                if let autotune = state.autotune {
                    if !state.onlyAutotuneBasals {
                        Section {
                            HStack {
                                Text("碳水化合物比")
                                Spacer()
                                Text(isfFormatter.string(from: autotune.carbRatio as NSNumber) ?? "0")
                                Text("g/U").foregroundColor(.secondary)
                            }
                            HStack {
                                Text("灵敏度")
                                Spacer()
                                if state.units == .mmolL {
                                    Text(isfFormatter.string(from: autotune.sensitivity.asMmolL as NSNumber) ?? "0")
                                } else {
                                    Text(isfFormatter.string(from: autotune.sensitivity as NSNumber) ?? "0")
                                }
                                Text(state.units.rawValue + "/U").foregroundColor(.secondary)
                            }
                        }
                    }

                    Section(header: Text("基础率设置")) {
                        ForEach(0 ..< autotune.basalProfile.count, id: \.self) { index in
                            HStack {
                                Text(autotune.basalProfile[index].start).foregroundColor(.secondary)
                                Spacer()
                                Text(rateFormatter.string(from: autotune.basalProfile[index].rate as NSNumber) ?? "0")
                                Text("U/hr").foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Text("全部的")
                                .bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Text(rateFormatter.string(from: autotune.basalProfile.reduce(0) { $0 + $1.rate } as NSNumber) ?? "0")
                                .foregroundColor(.primary) +
                                Text("u/day")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        Button { state.delete() }
                        label: { Text("删除自动点数据") }
                            .foregroundColor(.red)
                    }

                    /*
                     Section {
                         Button {
                             replaceAlert = true
                         }
                         label: { Text("保存为正常的基础费率") }
                     } header: {
                         Text("保存泵")
                     }*/
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Autotune")
            .navigationBarTitleDisplayMode(.automatic)
            .alert(Text("你确定吗？"), isPresented: $replaceAlert) {
                Button("Yes", action: {
                    state.replace()
                    replaceAlert.toggle()
                })
                Button("No", action: { replaceAlert.toggle() })
            }
        }
    }
}
