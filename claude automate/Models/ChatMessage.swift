import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var text: String
    var isUser: Bool
    var timestamp: Date
    var suggestions: [String]?

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = .now, suggestions: [String]? = nil) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.suggestions = suggestions
    }
}
