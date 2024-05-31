import CoreData
import SwiftUI
import Swinject

extension NightscoutConfig {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State var importAlert: Alert?
        @State var isImportAlertPresented = false
        @State var importedHasRun = false
        @State var displayPopUp = false

        @FetchRequest(
            entity: ImportError.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)], predicate: NSPredicate(
                format: "date > %@", Date().addingTimeInterval(-1.minutes.timeInterval) as NSDate
            )
        ) var fetchedErrors: FetchedResults<ImportError>

        private var portFormater: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.allowsFloats = false
            return formatter
        }

        var body: some View {
            Form {
                Section {
                    TextField("URL", text: $state.url)
                        .disableAutocorrection(true)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    SecureField("API secret", text: $state.secret)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .textContentType(.password)
                        .keyboardType(.asciiCapable)
                    if !state.message.isEmpty {
                        Text(state.message)
                    }
                    if state.connecting {
                        HStack {
                            Text("连接...")
                            Spacer()
                            ProgressView()
                        }
                    }
                }

                Section {
                    Button("Connect") { state.connect() }
                        .disabled(state.url.isEmpty || state.connecting)
                    Button("Delete") { state.delete() }.foregroundColor(.red).disabled(state.connecting)
                }

                Section {
                    Toggle("Upload", isOn: $state.isUploadEnabled)
                    if state.isUploadEnabled {
                        Toggle("Glucose", isOn: $state.uploadGlucose)

                        /*
                         Toggle(isOn: $state.uploadStats) {
                             HStack {
                                 Text("统计数据")
                                 Image(systemName: "info.bubble")
                                     .symbolRenderingMode(.palette)
                                     .foregroundStyle(.primary, .blue)
                                     .onTapGesture {
                                         displayPopUp.toggle()
                                     }
                             }
                         }
                         if displayPopUp {
                             VStack {
                                 Text(
                                     "This enables uploading of statistics.json to Nightscout, which can be used by the Community Statistics and Demographics Project.\n\nParticipation in Community Statistics is opt-in, and requires separate registration at:\n"
                                 )
                                 Text("https://iaps-stats.hub.org")
                                     .multilineTextAlignment(.center)
                             }
                             .font(.extraSmall)
                             .onTapGesture {
                                 displayPopUp.toggle()
                             }
                         }*/
                    }
                } header: {
                    Text("允许上传")
                }

                Section {
                    Button("Import settings from Nightscout") {
                        importAlert = Alert(
                            title: Text("导入设置？"),
                            message: Text(
                                "\n" +
                                    NSLocalizedString(
                                        "This will replace some or all of your current pump settings. Are you sure you want to import profile settings from Nightscout?",
                                        comment: "Profile Import Alert"
                                    ) +
                                    "\n"
                            ),
                            primaryButton: .destructive(
                                Text("是的，导入"),
                                action: {
                                    state.importSettings()
                                    importedHasRun = true
                                }
                            ),
                            secondaryButton: .cancel()
                        )
                        isImportAlertPresented.toggle()
                    }.disabled(state.url.isEmpty || state.connecting)

                } header: { Text("从Nightscout进口") }

                    .alert(isPresented: $importedHasRun) {
                        Alert(
                            title: Text((fetchedErrors.first?.error ?? "").count < 4 ? "Settings imported" : "Import Error"),
                            message: Text(
                                (fetchedErrors.first?.error ?? "").count < 4 ?
                                    NSLocalizedString(
                                        "\nNow please verify all of your new settings thoroughly:\n\n* Basal Settings\n * Carb Ratios\n * Glucose Targets\n * Insulin Sensitivities\n * DIA\n\n in iAPS Settings > Configuration.\n\nBad or invalid profile settings could have disatrous effects.",
                                        comment: "Imported Profiles Alert"
                                    ) :
                                    NSLocalizedString(fetchedErrors.first?.error ?? "", comment: "Import Error")
                            ),
                            primaryButton: .destructive(
                                Text("好的")
                            ),
                            secondaryButton: .cancel()
                        )
                    }

                Section {
                    Toggle("Use local glucose server", isOn: $state.useLocalSource)
                    HStack {
                        Text("港口")
                        DecimalTextField("", value: $state.localPort, formatter: portFormater)
                    }
                } header: { Text("局部血糖来源") }
                Section {
                    Button("Backfill glucose") { state.backfillGlucose() }
                        .disabled(state.url.isEmpty || state.connecting || state.backfilling)
                }

                Section {
                    Toggle("Remote control", isOn: $state.allowAnnouncements)
                } header: { Text("允许IAP的遥控器") }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationBarTitle("Nightscout Config")
            .navigationBarTitleDisplayMode(.automatic)
            .alert(isPresented: $isImportAlertPresented) {
                importAlert!
            }
        }
    }
}
