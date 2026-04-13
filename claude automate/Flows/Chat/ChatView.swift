import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AGSpacing.lg) {
                            ForEach(appState.chatMessages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(AGSpacing.screenPadding)
                    }
                    .onChange(of: appState.chatMessages.count) { _, _ in
                        if let lastId = appState.chatMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input bar
                HStack(spacing: AGSpacing.md) {
                    TextField("Ask about your car...", text: $inputText, axis: .vertical)
                        .font(.jakartaBody)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .padding(AGSpacing.md)
                        .background(Color.agMuted)
                        .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadiusLg))

                    Button {
                        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let text = inputText
                        inputText = ""
                        withAnimation {
                            appState.sendChatMessage(text)
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(inputText.isEmpty ? Color.agMutedForeground : Color.agPrimary)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, AGSpacing.screenPadding)
                .padding(.vertical, AGSpacing.md)
                .background(Color.agCard)
            }
            .background(Color.agBackground)
            .navigationTitle("Ask the Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environment(AppState())
}
