//
//  ChatWindowView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/18/25.
//
import SwiftUI

struct ChatWindowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Chat will go here")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
                Divider()
                HStack {
                    TextField("Ask something...", text: $message)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            sendMessage()
                            inputFocused = false
                        }
                        .onAppear {
                            // Auto-focus when sheet appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                inputFocused = true
                            }
                        }
                    Button {
                        sendMessage()
                        inputFocused = false
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .padding()
            }
            .navigationTitle("New conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Conversation 1") {}
                        Button("Conversation 2") {}
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        inputFocused = false
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // TODO: Hook into your chat backend / view model here
        message = ""
    }
}

#Preview {
    ChatWindowView()
}
