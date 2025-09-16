import SwiftUI

struct MesocycleEntryView: View {
    @State private var draft: MesoDraft? = ActiveMesocycleStore.shared.load()
    @State private var showBuilder = false
    @State private var startMode: StartMode? = nil

    enum StartMode: Hashable {
        case resume
        case copyPrevious
        case template
        case scratch
    }

    var body: some View {
        List {
            Section("Mesocycles") {
                entryCard(title: "Resume plan",
                          subtitle: "Continue your in-progress mesocycle",
                          systemImage: "play.circle.fill",
                          enabled: draft != nil) {
                    startMode = .resume
                    showBuilder = true
                }

                entryCard(title: "Copy previous",
                          subtitle: "Duplicate last mesocycle and tweak",
                          systemImage: "doc.on.doc.fill") {
                    startMode = .copyPrevious
                    showBuilder = true
                }

                entryCard(title: "Start from template",
                          subtitle: "Pick a Push/Pull/Legs or Upper/Lower base",
                          systemImage: "square.grid.2x2.fill") {
                    startMode = .template
                    showBuilder = true
                }

                entryCard(title: "Start from scratch",
                          subtitle: "Choose weeks (4–8) and build days (2–6)",
                          systemImage: "sparkles") {
                    startMode = .scratch
                    showBuilder = true
                }
            }
        }
        .navigationTitle("Build Mesocycle")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBuilder) {
            NavigationStack {
                NewMesoView(mode: startMode ?? .scratch)
            }
            .presentationDetents([.large])
            .presentationCornerRadius(20)
        }
    }

    @ViewBuilder
    private func entryCard(title: String, subtitle: String, systemImage: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .imageScale(.large)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.tint)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .listRowBackground(Color.clear)
    }
}