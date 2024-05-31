import SwiftUI
import Swinject

extension Calibrations {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            return formatter
        }

        var body: some View {
            GeometryReader { geo in
                Form {
                    Section(header: Text("添加校准")) {
                        HStack {
                            Text("仪血糖")
                            Spacer()
                            DecimalTextField(
                                "0",
                                value: $state.newCalibration,
                                formatter: formatter,
                                autofocus: false,
                                cleanInput: true
                            )
                            Text(state.units.rawValue).foregroundColor(.secondary)
                        }
                        Button {
                            state.addCalibration()
                        }
                        label: { Text("添加") }
                            .disabled(state.newCalibration <= 0)
                    }

                    Section(header: Text("信息")) {
                        HStack {
                            Text("坡")
                            Spacer()
                            Text(formatter.string(from: state.slope as NSNumber)!)
                        }
                        HStack {
                            Text("截距")
                            Spacer()
                            Text(formatter.string(from: state.intercept as NSNumber)!)
                        }
                    }

                    Section(header: Text("消除")) {
                        Button {
                            state.removeLast()
                        }
                        label: { Text("删除最后") }
                            .disabled(state.calibrations.isEmpty)

                        Button {
                            state.removeAll()
                        }
                        label: { Text("移除所有") }
                            .disabled(state.calibrations.isEmpty)
                        List {
                            ForEach(state.items) { item in
                                HStack {
                                    Text(dateFormatter.string(from: item.calibration.date))
                                    Spacer()
                                    VStack(alignment: .leading) {
                                        Text("raw: \(item.calibration.x)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("value: \(item.calibration.y)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                            }.onDelete(perform: delete)
                        }
                    }

                    if state.calibrations.isNotEmpty {
                        Section(header: Text("图表")) {
                            CalibrationsChart().environmentObject(state)
                                .frame(minHeight: geo.size.width)
                        }
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Calibrations")
            .navigationBarItems(trailing: EditButton().disabled(state.calibrations.isEmpty))
            .navigationBarTitleDisplayMode(.automatic)
        }

        private func delete(at offsets: IndexSet) {
            state.removeAtIndex(offsets[offsets.startIndex])
        }
    }
}
