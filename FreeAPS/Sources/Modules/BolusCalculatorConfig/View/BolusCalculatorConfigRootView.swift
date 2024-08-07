import SwiftUI
import Swinject

extension BolusCalculatorConfig {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        @State var isPresented = false
        @State var description = Text("")
        @State var descriptionHeader = Text("")
        @State var confirm = false
        @State var graphics: (any View)?

        private var conversionFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            return formatter
        }

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }

        var body: some View {
            Form {
                Section {
                    HStack {
                        Toggle("Use Bolus Calculator", isOn: $state.useCalc)
                    }
                }
                header: { Text("计算器设置") }
                footer: {
                    Text(
                        state
                            .useCalc ?
                            "Depending on your settings the Swift bolus calculator is using data from the OpenAPS glucose predictions and/or from IOB, COB, glucose trend, current gluccose and target glucose. At the end of the calculation a custom factor is applied (default 0.8).\n\nYou can also have the option in your bolus calculator to apply another (!) customizable factor at the end of the calculation which could be useful for fatty meals, e.g Pizza (default 0.7).\n\nThe bolus calculator is NOT using the OpenAPS variable \"insulinRequired\", made for SMBs." :
                            ""
                    )
                }

                if state.useCalc {
                    Section {
                        HStack {
                            Text("覆盖有一个因素")
                            Spacer()
                            DecimalTextField("0.8", value: $state.overrideFactor, formatter: conversionFormatter)
                        }
                    } header: { Text("调整") }
                }

                if state.useCalc {
                    Section {
                        Toggle("Apply factor for fatty meals", isOn: $state.fattyMeals)
                        if state.fattyMeals {
                            HStack {
                                Text("覆盖有一个因素")
                                Spacer()
                                DecimalTextField("0.7", value: $state.fattyMealFactor, formatter: conversionFormatter)
                            }
                        }
                    }
                    header: { Text("胖餐") }

                    Section {
                        Toggle("Display Predictions", isOn: $state.displayPredictions)
                    } header: { Text("较小的iPhone屏幕") }

                    Section {
                        Toggle(isOn: $state.eventualBG) {
                            HStack {
                                Text("1。")
                                Text("最终的血糖")
                            }
                        }
                        Toggle(isOn: $state.minumimPrediction) {
                            HStack {
                                Text("2。")
                                Text("最低预测血糖")
                            }
                        }
                    }
                    header: { Text("使用打开式血糖预测") }
                    footer: {
                        Text(
                            "1. Use the OpenAPS eventual glucose prediction for computing the insulin recommended. This setting will enable the \"old\" calculator. On by default.\n\n2. Use the OpenAPS minPredBG prediction as a complementary safety guard rail, not allowing the glucose prediction to descend below your threshold. This setting can be used together with or without the eventual glucose. On by default"
                        )
                    }
                }
                Section {
                    HStack {
                        Toggle(isOn: $state.allowBolusShortcut) {
                            Text("允许iOS大量捷径").foregroundStyle(state.allowBolusShortcut ? .red : .primary)
                        }.disabled(isPresented)
                            ._onBindingChange($state.allowBolusShortcut, perform: { _ in
                                if state.allowBolusShortcut {
                                    confirm = true
                                    graphics = confirmButton()
                                    info(
                                        header: "Allow iOS Bolus Shortcuts",
                                        body: "If you enable this setting you will be able to use iOS shortcuts and its automations to trigger a bolus in iAPS.\n\nObserve that the iOS shortuts also works with Siri!\n\nIf you need to use Bolus Shorcuts, please make sure to turn off the listen for 'Hey Siri' setting in iPhone Siri settings, to avoid any inadvertant activaton of a bolus with Siri.\nIf you don't disable 'Hey Siri' the iAPS bolus shortcut can be triggered with the utterance 'Hey Siri, iAPS Bolus'.\n\nWhen triggered with Siri you will be asked for an amount and a confirmation before the bolus command can be sent to iAPS.",
                                        useGraphics: graphics
                                    )
                                }
                            })
                    }
                    if state.allowBolusShortcut {
                        HStack {
                            Text(
                                state.allowedRemoteBolusAmount > state.settingsManager.pumpSettings
                                    .maxBolus ? "Max Bolus exceeded!" :
                                    "Max allowed bolus amount using shortcuts "
                            )
                            .foregroundStyle(
                                state.allowedRemoteBolusAmount > state.settingsManager.pumpSettings
                                    .maxBolus ? .red : .primary
                            )
                            Spacer()
                            DecimalTextField("0", value: $state.allowedRemoteBolusAmount, formatter: conversionFormatter)
                        }
                    }
                } header: { Text("iOS快捷方式") }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationBarTitle("Bolus Calculator")
            .navigationBarTitleDisplayMode(.automatic)
            .blur(radius: isPresented ? 5 : 0)
            .description(isPresented: isPresented, alignment: .center) {
                if confirm { confirmationView() } else { infoView() }
            }
        }

        func info(header: String, body: String, useGraphics: (any View)?) {
            isPresented.toggle()
            description = Text(NSLocalizedString(body, comment: "Dynamic ISF Setting"))
            descriptionHeader = Text(NSLocalizedString(header, comment: "Dynamic ISF Setting Title"))
            graphics = useGraphics
        }

        var info: some View {
            VStack(spacing: 20) {
                descriptionHeader.font(.title2).bold()
                description.font(.body)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }

        func infoView() -> some View {
            info
                .formatDescription()
                .onTapGesture {
                    isPresented.toggle()
                }
        }

        func confirmationView() -> some View {
            ScrollView {
                VStack(spacing: 20) {
                    info
                    if let view = graphics {
                        view.asAny()
                    }
                }
                .formatDescription()
            }
        }

        @ViewBuilder func confirmButton() -> some View {
            HStack(spacing: 20) {
                Button("Enable") {
                    state.allowBolusShortcut = true
                    isPresented.toggle()
                    confirm = false
                }.buttonStyle(.borderedProminent).tint(.blue)

                Button("Cancel") {
                    state.allowBolusShortcut = false
                    isPresented.toggle()
                    confirm = false
                }.buttonStyle(.borderedProminent).tint(.red)
            }.dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }
}
