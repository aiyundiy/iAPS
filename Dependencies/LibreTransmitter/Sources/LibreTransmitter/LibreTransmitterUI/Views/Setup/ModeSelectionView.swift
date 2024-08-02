//
//  ModeSelectionView.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 02/09/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI

struct ModeSelectionView: View {

    @ObservedObject public var cancelNotifier: GenericObservableObject
    @ObservedObject public var saveNotifier: GenericObservableObject

    var modeSelectSection : some View {
        Section(header: Text("模式")) {

            #if canImport(CoreNFC)
            ZStack {
                NavigationLink(destination: Libre2DirectSetup(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    SettingsItem(title: NSLocalizedString("libre 2直接", comment: "Libre 2 Direct"), detail: .constant(""))
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                }
            }
            #endif

            ZStack {
                NavigationLink(destination: BluetoothSelection(cancelNotifier: cancelNotifier, saveNotifier: saveNotifier)) {
                    SettingsItem(title: NSLocalizedString("蓝牙发射器", comment: "Bluetooth Transmitters"), detail: .constant(""))
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                }
            }


        }
    }

    var cancelButton: some View {
        Button("Cancel"){
            print("cancel button pressed")
            cancelNotifier.notify()

        }//.accentColor(.red)
    }
    
    var body: some View {
        //no navview needed when embedded into a hostingcontroller
        //NavigationView{
        List {
            modeSelectSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: cancelButton)


    }
}



struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView(cancelNotifier: GenericObservableObject(), saveNotifier: GenericObservableObject())
    }
}
