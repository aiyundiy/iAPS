import Charts
import CoreData
import SwiftUI
import Swinject

extension Bolus {
    struct AlternativeBolusCalcRootView: BaseView {
        let resolver: Resolver
        let waitForSuggestion: Bool
        let fetch: Bool
        @StateObject var state: StateModel
        @State private var showInfo = false
        @State private var exceededMaxBolus = false
        @State private var keepForNextWiew: Bool = false
        @State private var remoteBolusAlert: Alert?
        @State private var isRemoteBolusAlertPresented: Bool = false

        private enum Config {
            static let dividerHeight: CGFloat = 2
            static let overlayColour: Color = .white // Currently commented out
            static let spacing: CGFloat = 3
        }

        @Environment(\.colorScheme) var colorScheme
        @FocusState private var isFocused: Bool

        let meal: FetchedResults<Meals>
        let mealEntries: any View

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        private var mealFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            return formatter
        }

        private var gluoseFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if state.units == .mmolL {
                formatter.maximumFractionDigits = 1
            } else { formatter.maximumFractionDigits = 0 }
            return formatter
        }

        private var fractionDigits: Int {
            if state.units == .mmolL {
                return 1
            } else { return 0 }
        }

        var body: some View {
            Form {
                Section {
                    if state.waitForSuggestion {
                        Text("请稍等")
                    } else {
                        predictionChart
                    }
                }

                Section {}
                if fetch {
                    Section { mealEntries.asAny() }
                }

                Section {
                    if !state.waitForSuggestion {
                        HStack {
                            Button(action: {
                                showInfo.toggle()
                            }, label: {
                                Image(systemName: "info.bubble")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(colorScheme == .light ? .black : .white, .blue)
                                    .font(.infoSymbolFont)
                                Text("计算")
                            })
                                .foregroundStyle(.blue)
                                .font(.footnote)
                                .buttonStyle(PlainButtonStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if state.fattyMeals {
                                Spacer()
                                Toggle(isOn: $state.useFattyMealCorrectionFactor) {
                                    Text("脂肪饭")
                                }
                                .toggleStyle(CheckboxToggleStyle())
                                .font(.footnote)
                                .onChange(of: state.useFattyMealCorrectionFactor) { _ in
                                    state.insulinCalculated = state.calculateInsulin()
                                }
                            }
                        }
                    }

                    if state.waitForSuggestion {
                        HStack {
                            Text("请等一下").foregroundColor(.secondary)
                            Spacer()
                            ActivityIndicator(isAnimating: .constant(true), style: .medium) // fix iOS 15 bug
                        }
                    } else {
                        HStack {
                            Text("推荐胰岛素")
                            Spacer()
                            Text(
                                formatter
                                    .string(from: Double(state.insulinCalculated) as NSNumber) ?? ""
                            )
                            Text(
                                NSLocalizedString(" U", comment: "Unit in number of units delivered (keep the space character!)")
                            ).foregroundColor(.secondary)
                        }.contentShape(Rectangle())
                            .onTapGesture { state.amount = state.insulinCalculated }
                    }

                    HStack {
                        Text("推注")
                        Spacer()
                        DecimalTextField(
                            "0",
                            value: $state.amount,
                            formatter: formatter,
                            cleanInput: true,
                            useButtons: true
                        )
                        Text(exceededMaxBolus ? "😵" : " U").foregroundColor(.secondary)
                    }
                    .focused($isFocused)
                    .onChange(of: state.amount) { newValue in
                        if newValue > state.maxBolus {
                            exceededMaxBolus = true
                        } else {
                            exceededMaxBolus = false
                        }
                    }
                }

                if state.amount > 0 {
                    Section {
                        Button {
                            if let remoteBolus = state.remoteBolus() {
                                remoteBolusAlert = Alert(
                                    title: Text("刚刚交付了一个远程推注！"),
                                    message: Text(remoteBolus),
                                    primaryButton: .destructive(Text("推注"), action: {
                                        keepForNextWiew = true
                                        state.add()
                                    }),
                                    secondaryButton: .cancel()
                                )
                                isRemoteBolusAlertPresented = true
                            } else {
                                keepForNextWiew = true
                                state.add()
                            }
                        }
                        label: { Text(exceededMaxBolus ? "Max Bolus exceeded!" : "Enact bolus") }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .disabled(disabled)
                            .listRowBackground(!disabled ? Color(.systemBlue) : Color(.systemGray4))
                            .tint(.white)
                    }
                    footer: {
                        if (-1 * state.loopDate.timeIntervalSinceNow / 60) > state.loopReminder, let string = state.lastLoop() {
                            Text(NSLocalizedString(string, comment: "Bolus View footer"))
                                .padding(.top, 20).multilineTextAlignment(.center)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if state.amount <= 0 {
                    Section {
                        Button {
                            keepForNextWiew = true
                            state.showModal(for: nil)
                        }
                        label: {
                            fetch ?
                                Text("不用推注而保存饭") :
                                Text("继续没有推注")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color(.systemBlue))
                        .tint(.white)
                    }
                    footer: {
                        if (-1 * state.loopDate.timeIntervalSinceNow / 60) > state.loopReminder, let string = state.lastLoop() {
                            Text(NSLocalizedString(string, comment: "Bolus View footer"))
                                .padding(.top, 20).multilineTextAlignment(.center)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .compactSectionSpacing()
            .alert(isPresented: $isRemoteBolusAlertPresented) {
                remoteBolusAlert!
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .navigationTitle("Enact Bolus")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button {
                    keepForNextWiew = state.carbsView(fetch: fetch, hasFatOrProtein: hasFatOrProtein, mealSummary: meal)
                }
                label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("进餐")
                    }
                },
                trailing: Button {
                    state.hideModal()
                    state.notActive()
                }
                label: { Text("取消") }
            )
            .onAppear {
                configureView {
                    state.viewActive()
                    state.waitForSuggestionInitial = waitForSuggestion
                    state.waitForSuggestion = waitForSuggestion
                    state.insulinCalculated = state.calculateInsulin()
                }
            }
            .onDisappear {
                if fetch, hasFatOrProtein, !keepForNextWiew, state.useCalc, !state.eventualBG {
                    state.delete(deleteTwice: true, meal: meal)
                } else if fetch, !keepForNextWiew, state.useCalc, !state.eventualBG {
                    state.delete(deleteTwice: false, meal: meal)
                }
            }
            .popup(isPresented: showInfo, alignment: .bottom, direction: .center, type: .default) {
                illustrationView()
            }
        }

        var predictionChart: some View {
            ZStack {
                PredictionView(
                    predictions: $state.predictions, units: $state.units, eventualBG: $state.evBG,
                    useEventualBG: $state.eventualBG, target: $state.target,
                    displayPredictions: $state.displayPredictions, currentGlucose: $state.currentBG
                )
            }
        }

        private var disabled: Bool {
            state.amount <= 0 || state.amount > state.maxBolus
        }

        var changed: Bool {
            ((meal.first?.carbs ?? 0) > 0) || ((meal.first?.fat ?? 0) > 0) || ((meal.first?.protein ?? 0) > 0)
        }

        var hasFatOrProtein: Bool {
            ((meal.first?.fat ?? 0) > 0) || ((meal.first?.protein ?? 0) > 0)
        }

        func carbsView() {
            if fetch {
                keepForNextWiew = true
                state.backToCarbsView(complexEntry: hasFatOrProtein, meal, override: false, deleteNothing: false, editMode: true)
            } else {
                state.backToCarbsView(complexEntry: false, meal, override: true, deleteNothing: true, editMode: false)
            }
        }

        private func illustrationView() -> some View {
            VStack {
                IllustrationView(data: $state.data)

                // Hide button
                VStack {
                    Button { showInfo = false }
                    label: { Text("隐藏") }.frame(maxWidth: .infinity, alignment: .center)
                        .tint(.blue)
                }.padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(colorScheme == .dark ? UIColor.systemGray4 : UIColor.systemGray5))
            )
        }
    }
}
