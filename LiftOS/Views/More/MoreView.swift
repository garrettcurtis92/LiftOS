// More tab root
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
                    NavigationLink("Appearance") { AppearanceView() }
                    Text("Haptics & Sounds")
                    Text("About") 
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
