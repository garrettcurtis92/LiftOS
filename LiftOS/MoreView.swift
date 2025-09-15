//
//  MoreView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Text("iCloud Status")
                    Text("Health Permissions")
                }
                Section("App") {
                    NavigationLink("Settings") { SettingsView() }
                    Text("Appearance")
                    Text("Haptics & Sounds")
                    Text("About")
                }
                Section("Developer") {
                    Text("Debug Sync")
                    Text("Reset Local Cache")
                }
            }
            .navigationTitle("More")
        }
    }
}
