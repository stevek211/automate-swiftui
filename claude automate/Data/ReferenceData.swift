import Foundation

/// App-level reference/knowledge data that is NOT user-specific.
/// This is always available regardless of auth state or demo mode.
/// Distinct from DemoData, which contains fake user data for demo mode.
enum ReferenceData {
    // MARK: - Diagnostic Lights (knowledge base — not user data)
    static var diagnosticLights: [DiagnosticLight] { DemoData.diagnosticLights }

    // MARK: - Noise Diagnosis (knowledge base — not user data)
    static var noiseDiagnoses: [NoiseDiagnosis] { DemoData.noiseDiagnoses }
    static var noiseLocations: [String] { DemoData.noiseLocations }
    static var noiseTimings: [String] { DemoData.noiseTimings }
    static var noiseSounds: [String] { DemoData.noiseSounds }

    // MARK: - Car Systems (knowledge base — not user data)
    static var carSystems: [CarSystem] { DemoData.carSystems }

    // MARK: - Learning Articles (knowledge base — not user data)
    static var articles: [LearningArticle] { DemoData.articles }
}
