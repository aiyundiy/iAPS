import SwiftUI
import Swinject

extension CREditor {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State private var editMode = EditMode.inactive

        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.timeStyle = .short
            return formatter
        }

        private var rateFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }

        var body: some View {
            Form {
                if let autotune = state.autotune, !state.settingsManager.settings.onlyAutotuneBasals {
                    Section(header: Text("自动")) {
                        HStack {
                            Text("计算的比率")
                            Spacer()
                            Text(rateFormatter.string(from: autotune.carbRatio as NSNumber) ?? "0")
                            Text("g/U").foregroundColor(.secondary)
                        }
                    }
                }
                Section(header: Text("日程")) {
                    list
                    addButton
                }
                Section {
                    Button {
                        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                        impactHeavy.impactOccurred()
                        state.save()
                    }
                    label: {
                        Text("保存")
                    }
                    .disabled(state.items.isEmpty)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Carb Ratios")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(
                trailing: EditButton()
            )
            .environment(\.editMode, $editMode)
            .onAppear {
                state.validate()
            }
        }

        private func pickers(for index: Int) -> some View {
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Text("比率").frame(width: geometry.size.width / 2)
                        Text("时间").frame(width: geometry.size.width / 2)
                    }
                    HStack(spacing: 0) {
                        Picker(selection: $state.items[index].rateIndex, label: EmptyView()) {
                            ForEach(0 ..< state.rateValues.count, id: \.self) { i in
                                Text(
                                    (
                                        self.rateFormatter
                                            .string(from: state.rateValues[i] as NSNumber) ?? ""
                                    ) + " g/U"
                                ).tag(i)
                            }
                        }
                        .frame(maxWidth: geometry.size.width / 2)
                        .clipped()

                        Picker(selection: $state.items[index].timeIndex, label: EmptyView()) {
                            ForEach(0 ..< state.timeValues.count, id: \.self) { i in
                                Text(
                                    self.dateFormatter
                                        .string(from: Date(
                                            timeIntervalSince1970: state
                                                .timeValues[i]
                                        ))
                                ).tag(i)
                            }
                        }
                        .frame(maxWidth: geometry.size.width / 2)
                        .clipped()
                    }
                }
            }
        }

        private var list: some View {
            List {
                ForEach(state.items.indexed(), id: \.1.id) { index, item in
                    NavigationLink(destination: pickers(for: index)) {
                        HStack {
                            Text("比率").foregroundColor(.secondary)
                            Text(
                                "\(rateFormatter.string(from: state.rateValues[item.rateIndex] as NSNumber) ?? "0") g/U"
                            )
                            Spacer()
                            Text("开始于").foregroundColor(.secondary)
                            Text(
                                "\(dateFormatter.string(from: Date(timeIntervalSince1970: state.timeValues[item.timeIndex])))"
                            )
                        }
                    }
                    .moveDisabled(true)
                }
                .onDelete(perform: onDelete)
            }
        }

        private var addButton: some View {
            guard state.canAdd else {
                return AnyView(EmptyView())
            }

            switch editMode {
            case .inactive:
                return AnyView(Button(action: onAdd) { Text("添加") })
            default:
                return AnyView(EmptyView())
            }
        }

        func onAdd() {
            state.add()
        }

        private func onDelete(offsets: IndexSet) {
            state.items.remove(atOffsets: offsets)
            state.validate()
        }
    }
}
