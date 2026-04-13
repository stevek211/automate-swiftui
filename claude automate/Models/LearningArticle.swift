import Foundation

struct LearningArticle: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var description: String
    var readTimeMinutes: Int
    var difficulty: Difficulty
    var category: ArticleCategory
    var sections: [ArticleSection]
    var relatedSystemNames: [String]
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
}

enum ArticleCategory: String, Codable, CaseIterable, Identifiable {
    case carBasics = "Car Basics"
    case seasonalPrep = "Seasonal Prep"
    case understandingRepairs = "Understanding Repairs"

    var id: String { rawValue }
}

struct ArticleSection: Hashable, Codable {
    var heading: String
    var body: String
}
