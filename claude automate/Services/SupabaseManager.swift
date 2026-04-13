import Supabase
import Foundation

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://nlugowdxamlfrfyfygjd.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sdWdvd2R4YW1sZnJmeWZ5Z2pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MzYyMjEsImV4cCI6MjA4OTIxMjIyMX0.payarzOJvXLApDMTc34h7rZmnThixvFsOshIKnFbPjo"
    )
}
