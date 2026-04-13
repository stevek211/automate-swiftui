import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: AGSpacing.sm) {
                if !message.isUser {
                    HStack(spacing: AGSpacing.sm) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.agPrimary)
                            .clipShape(Circle())
                        Text("AutoGuard")
                            .font(.jakartaCaption)
                            .foregroundStyle(Color.agMutedForeground)
                    }
                }

                Text(message.text)
                    .font(.jakartaBody)
                    .foregroundStyle(message.isUser ? .white : Color.agForeground)
                    .padding(AGSpacing.md)
                    .background(message.isUser ? Color.agPrimary : Color.agMuted)
                    .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadiusLg))

                if let suggestions = message.suggestions, !suggestions.isEmpty {
                    FlowLayout(spacing: AGSpacing.sm) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Text(suggestion)
                                .font(.jakartaCaption)
                                .foregroundStyle(Color.agPrimary)
                                .padding(.horizontal, AGSpacing.md)
                                .padding(.vertical, AGSpacing.sm)
                                .background(Color.agPrimary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowMaxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y = rowMaxY + spacing
            }
            positions.append(CGPoint(x: x, y: y))
            rowMaxY = max(rowMaxY, y + size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, rowMaxY)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}

#Preview {
    VStack {
        ChatBubble(message: ChatMessage(text: "When should I change my oil?", isUser: true))
        ChatBubble(message: ChatMessage(
            text: "For your 2019 Honda CR-V, Honda recommends an oil change every 7,500 miles with full synthetic oil.",
            isUser: false,
            suggestions: ["Tell me more", "What will it cost?"]
        ))
    }
    .padding()
}
