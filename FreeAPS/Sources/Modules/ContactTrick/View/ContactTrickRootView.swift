import Contacts
import ContactsUI
import SwiftUI
import Swinject

extension ContactTrick {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()

        @State private var contactStore = CNContactStore()
        @State private var authorization = CNContactStore.authorizationStatus(for: .contacts)

        var body: some View {
            Form {
                switch authorization {
                case .authorized:
                    Section(header: Text("联系人")) {
                        list
                        addButton
                    }
                    Section(
                        header: state.changed ?
                            Text("不要忘记保存更改。")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.primary) : nil
                    ) {
                        HStack {
                            if state.syncInProgress {
                                ProgressView().padding(.trailing, 10)
                            }
                            Button { state.save() }
                            label: {
                                Text(state.syncInProgress ? "Saving..." : "Save")
                            }
                            .disabled(state.syncInProgress || !state.changed)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                case .notDetermined:
                    Section {
                        Text(
                            "iAPS needs access to your contacts for this feature to work"
                        )
                    }
                    Section {
                        Button(action: onRequestContactsAccess) {
                            Text("授予IAPS访问联系人")
                        }
                    }

                case .denied:
                    Section {
                        Text(
                            "Access to contacts denied"
                        )
                    }

                case .restricted:
                    Section {
                        Text(
                            "Access to contacts is restricted (parental control?)"
                        )
                    }

                @unknown default:
                    Section {
                        Text(
                            "Access to contacts - unknown state"
                        )
                    }
                }

                Section {}
                footer: {
                    Text(
                        "A Contact Image can be used to get live updates from iAPS to your Apple Watch Contact complication and/or your iPhone Contact widget."
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear(perform: configureView)
            .navigationTitle("Contact Image")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(
                trailing: EditButton()
            )
        }

        private func contactSettings(for index: Int) -> some View {
            EntryView(entry: Binding(
                get: { state.items[index].entry },
                set: { newValue in state.update(index, newValue) }
            ), previewState: previewState)
        }

        var previewState: ContactTrickState {
            let units = state.units

            return ContactTrickState(
                glucose: units == .mmolL ? "6,8" : "127",
                trend: "↗︎",
                delta: units == .mmolL ? "+0,3" : "+7",
                lastLoopDate: .now,
                iob: 6.1,
                iobText: "6,1",
                cob: 27.0,
                cobText: "27",
                eventualBG: units == .mmolL ? "8,9" : "163",
                maxIOB: 12.0,
                maxCOB: 120.0
            )
        }

        private var list: some View {
            List {
                ForEach(state.items.indexed(), id: \.1.id) { index, item in
                    NavigationLink(destination: contactSettings(for: index)) {
                        EntryListView(entry: .constant(item.entry), index: .constant(index), previewState: previewState)
                    }
                    .moveDisabled(true)
                }
                .onDelete(perform: onDelete)
            }
        }

        private var addButton: some View {
            AnyView(Button(action: onAdd) { Text("添加") })
        }

        func onAdd() {
            state.add()
        }

        func onRequestContactsAccess() {
            contactStore.requestAccess(for: .contacts) { _, _ in
                DispatchQueue.main.async {
                    authorization = CNContactStore.authorizationStatus(for: .contacts)
                }
            }
        }

        private func onDelete(offsets: IndexSet) {
            state.remove(atOffsets: offsets)
        }
    }

    struct EntryListView: View {
        @Binding var entry: ContactTrickEntry
        @Binding var index: Int
        @State private var refreshKey = UUID()
        let previewState: ContactTrickState

        var body: some View {
            HStack {
                Text(
                    NSLocalizedString("接触", comment: "") + ": " + "iAPS \(index + 1)"
                )
                .font(.body)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

                Spacer()

                VStack {
                    GeometryReader { geometry in
                        ZStack {
                            Circle()
                                .fill(entry.darkMode ? .black : .white)
                                .foregroundColor(.white)
                            Image(uiImage: ContactPicture.getImage(contact: entry, state: previewState))
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: geometry.size.height, height: geometry.size.height)
                                .clipShape(Circle())
                            Circle()
                                .stroke(lineWidth: 2)
                                .foregroundColor(.white)
                        }
                        .frame(width: geometry.size.height, height: geometry.size.height)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 30)
            }
            .frame(maxWidth: .infinity)
        }
    }

    struct EntryView: View {
        @Binding var entry: ContactTrickEntry
        @State private var availableFonts: [String]? = nil
        let previewState: ContactTrickState

        private let fontSizes: [Int] = [100, 120, 130, 140, 160, 180, 200, 225, 250, 275, 300, 350, 400]
        private let ringWidths: [Int] = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        private let ringGaps: [Int] = [0, 1, 2, 3, 4, 5]

        var body: some View {
            Section {
                HStack {
                    ZStack {
                        Circle()
                            .fill(entry.darkMode ? .black : .white)
                            .foregroundColor(.white)
                        Image(uiImage: ContactPicture.getImage(contact: entry, state: previewState))
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                        Circle()
                            .stroke(lineWidth: 2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 64, height: 64)
                }
            }
            Form {
                Section {
                    Picker(
                        selection: $entry.layout,
                        label: Text("布局")
                    ) {
                        ForEach(ContactTrickLayout.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                }
                Section {
                    switch entry.layout {
                    case .single:
                        Picker(
                            selection: $entry.primary,
                            label: Text("基本的")
                        ) {
                            ForEach(ContactTrickValue.allCases) { v in
                                Text(v.displayName).tag(v)
                            }
                        }
                        Picker(
                            selection: $entry.top,
                            label: Text("顶部")
                        ) {
                            ForEach(ContactTrickValue.allCases) { v in
                                Text(v.displayName).tag(v)
                            }
                        }
                        Picker(
                            selection: $entry.bottom,
                            label: Text("底部")
                        ) {
                            ForEach(ContactTrickValue.allCases) { v in
                                Text(v.displayName).tag(v)
                            }
                        }
                    case .split:
                        Picker(
                            selection: $entry.top,
                            label: Text("顶部")
                        ) {
                            ForEach(ContactTrickValue.allCases) { v in
                                Text(v.displayName).tag(v)
                            }
                        }
                        Picker(
                            selection: $entry.bottom,
                            label: Text("底部")
                        ) {
                            ForEach(ContactTrickValue.allCases) { v in
                                Text(v.displayName).tag(v)
                            }
                        }
                    }
                }

                Section(header: Text("戒指")) {
                    Picker(
                        selection: $entry.ring1,
                        label: Text("外")
                    ) {
                        ForEach(ContactTrickLargeRing.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                    Picker(
                        selection: $entry.ringWidth,
                        label: Text("宽度")
                    ) {
                        ForEach(ringWidths, id: \.self) { s in
                            Text("\(s)").tag(s)
                        }
                    }
                    Picker(
                        selection: $entry.ringGap,
                        label: Text("差距")
                    ) {
                        ForEach(ringGaps, id: \.self) { s in
                            Text("\(s)").tag(s)
                        }
                    }
                }

                Section(header: Text("字体")) {
                    if availableFonts == nil {
                        HStack {
                            Spacer()
                            Button {
                                loadFonts()
                            } label: {
                                Text(entry.fontName)
                            }
                        }
                    } else {
                        Picker(
                            selection: $entry.fontName,
                            label: EmptyView()
                        ) {
                            ForEach(availableFonts!, id: \.self) { f in
                                Text(f).tag(f)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .labelsHidden()
                    }
                    Picker(
                        selection: $entry.fontSize,
                        label: Text("尺寸")
                    ) {
                        ForEach(fontSizes, id: \.self) { s in
                            Text("\(s)").tag(s)
                        }
                    }
                    Picker(
                        selection: $entry.secondaryFontSize,
                        label: Text("次要大小")
                    ) {
                        ForEach(fontSizes, id: \.self) { s in
                            Text("\(s)").tag(s)
                        }
                    }
                    Picker(
                        selection: $entry.fontTracking,
                        label: Text("追踪")
                    ) {
                        ForEach(FontTracking.allCases) { w in
                            Text(w.displayName).tag(w)
                        }
                    }
                    if entry.isDefaultFont() {
                        Picker(
                            selection: $entry.fontWeight,
                            label: Text("重量")
                        ) {
                            ForEach(FontWeight.allCases) { w in
                                Text(w.displayName).tag(w)
                            }
                        }
                    }
                }
                Section {
                    Toggle("Dark mode", isOn: $entry.darkMode)
                }
            }
        }

        private func loadFonts() {
            if availableFonts != nil {
                return
            }
            var data = [String]()

            data.append("Default Font")
            UIFont.familyNames.forEach { family in
                UIFont.fontNames(forFamilyName: family).forEach { font in
                    data.append(font)
                }
            }
            availableFonts = data
        }
    }
}
