import Charts
import CoreData
import SwiftUI
import Swinject

extension Bolus {
    struct DefaultBolusCalcRootView: BaseView {
        let resolver: Resolver
        let waitForSuggestion: Bool
        let fetch: Bool

        @StateObject var state = StateModel()

        let meal: FetchedResults<Meals>
        let mealEntries: any View

        @State private var isAddInsulinAlertPresented = false
        @State private var presentInfo = false
        @State private var displayError = false
        @State private var keepForNextWiew: Bool = false
        @State private var remoteBolusAlert: Alert?
        @State private var isRemoteBolusAlertPresented: Bool = false

        @Environment(\.colorScheme) var colorScheme
        @FocusState private var isFocused: Bool

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        private var glucoseFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = state.units == .mmolL ? 1 : 0
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

                if fetch {
                    Section {
                        mealEntries.asAny()
                    } // header: { Text("进餐摘要") }
                }

                Section {
                    if state.waitForSuggestion {
                        HStack {
                            Text("请等一下").foregroundColor(.secondary)
                            Spacer()
                            ActivityIndicator(isAnimating: .constant(true), style: .medium) // fix iOS 15 bug
                        }
                    } else {
                        HStack {
                            Text("推荐胰岛素")
                            Image(systemName: "info.bubble")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.primary, .blue)
                                .onTapGesture {
                                    presentInfo.toggle()
                                }

                            Spacer()

                            Text(
                                formatter
                                    .string(from: state.insulinCalculated as NSNumber)! +
                                    NSLocalizedString(" U", comment: "Insulin unit")
                            ).foregroundColor(.secondary)
                                .onTapGesture {
                                    state.amount = state.insulinCalculated
                                }
                        }.contentShape(Rectangle())
                    }
                    HStack {
                        Text("数量")
                        Spacer()
                        DecimalTextField(
                            "0",
                            value: $state.amount,
                            formatter: formatter,
                            cleanInput: true,
                            useButtons: true
                        )
                        Text(!(state.amount > state.maxBolus) ? "U" : "😵").foregroundColor(.secondary)
                    }
                    .focused($isFocused)
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
                        label: { Text(!(state.amount > state.maxBolus) ? "Enact bolus" : "Max Bolus exceeded!") }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .disabled(disabled)
                            .listRowBackground(!disabled ? Color(.systemBlue) : Color(.systemGray4))
                            .tint(.white)
                    }
                    .alert(isPresented: $isRemoteBolusAlertPresented) {
                        remoteBolusAlert!
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
                                Text("继续没有推注") }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color(.systemBlue))
                            .tint(.white)
                    }
                }
            }
            .compactSectionSpacing()
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear {
                configureView {
                    state.waitForSuggestionInitial = waitForSuggestion
                    state.waitForSuggestion = waitForSuggestion
                }
            }

            .onDisappear {
                if fetch, hasFatOrProtein, !keepForNextWiew, state.eventualBG {
                    state.delete(deleteTwice: true, meal: meal)
                } else if fetch, !keepForNextWiew, state.eventualBG {
                    state.delete(deleteTwice: false, meal: meal)
                }
            }

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
                trailing: Button { state.hideModal() }
                label: { Text("取消") }
            )
            .popup(isPresented: presentInfo, alignment: .bottom, direction: .bottom, type: .default) {
                formulasView()
            }
        }

        var disabled: Bool {
            state.amount <= 0 || state.amount > state.maxBolus
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

        @ViewBuilder private func formulasView() -> some View {
            let entries = [
                Formulas(
                    variable: NSLocalizedString("最终的血糖", comment: ""),
                    value: glucoseFormatter.string(for: state.evBG) ?? "",
                    unit: state.units.rawValue,
                    color: .primary
                ),
                Formulas(
                    variable: NSLocalizedString("血糖", comment: ""),
                    value: state.target.formatted(),
                    unit: state.units.rawValue,
                    color: .primary
                ),
                Formulas(
                    variable: NSLocalizedString("ISF", comment: ""),
                    value: state.isf.formatted(),
                    unit: state.units.rawValue + NSLocalizedString("/u", comment: "Insulin unit"),
                    color: .primary
                ),
                Formulas(
                    variable: NSLocalizedString("因素", comment: ""),
                    value: state.fraction.formatted(),
                    unit: "",
                    color: .primary
                )
            ]

            VStack {
                Grid(verticalSpacing: 3) {
                    ForEach(entries.dropLast()) { entry in
                        GridRow {
                            Text(entry.variable).foregroundStyle(.secondary)
                            Text(entry.value).foregroundStyle(entry.color)
                            Text(entry.unit).foregroundStyle(.secondary)
                        }
                    }

                    Divider().padding(.top, 10)

                    HStack {
                        Text("公式：")
                        Text("（最终血糖 - 目标） / ISF")
                    }.foregroundStyle(.secondary).italic().padding(.vertical, 10)
                    Divider()
                    // Formula
                    VStack(spacing: 5) {
                        if state.insulin > 0 {
                            let unit = NSLocalizedString(
                                " U",
                                comment: "Unit in number of units delivered (keep the space character!)"
                            )
                            let color: Color = (state.fraction != 1 && state.insulin > 0) ? .secondary : .blue
                            let fontWeight: Font.Weight = (state.fraction != 1 && state.insulin > 0) ? .regular : .bold
                            HStack {
                                Text(NSLocalizedString("推荐胰岛素", comment: "") + ":")
                                Text(formatter.string(for: state.insulin) ?? "" + unit).foregroundStyle(color)
                            }.padding(.vertical, 10)
                            if state.fraction != 1, state.insulin > 0 {
                                Divider()
                                HStack {
                                    Text((entries.last?.variable ?? "") + " " + (entries.last?.value ?? "") + "  ->")
                                        .foregroundStyle(.secondary)
                                    Text(
                                        state.insulinCalculated.formatted() + unit
                                    ).fontWeight(fontWeight).font(.title3).foregroundStyle(.blue).bold()
                                }
                            }
                        }
                        // Footer
                        VStack {
                            if state.evBG < state.target {
                                Text(
                                    "Eventual Glucose is lower than your target glucose. No insulin recommended."
                                ).foregroundStyle(.red)
                            } else if state.minimumPrediction, state.minPredBG < state.threshold {
                                Text(
                                    "Minimum Predicted Glucose is lower than your glucose threshold. No insulin recommended."
                                ).foregroundStyle(.red)
                            } else {
                                Text(
                                    "Carbs and previous insulin are included in the eventual glucose prediction."
                                ).foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption2)
                        .padding(20)
                        // Hide button
                        VStack {
                            Button { presentInfo = false }
                            label: { Text("隐藏") }.frame(maxWidth: .infinity, alignment: .center)
                                .tint(.blue)
                        }.padding(.bottom, 10)
                    }
                }
                .padding(20)
                .dynamicTypeSize(...DynamicTypeSize.small)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(colorScheme == .dark ? UIColor.systemGray4 : UIColor.systemGray4))
            )
        }
    }
}
