import Foundation

struct CatalogItem: Decodable, Identifiable, Hashable {
    let name: String
    let muscleGroup: String   // "chest", "back", ...
    let type: String          // "barbell", "cable", ...
    let loadBasis: String?    // optional

    // Stable ID for joining history later if needed
    var id: String { "\(muscleGroup)#\(type)#\(name)".lowercased() }
}

enum ExerciseCatalog {
    static func load() -> [CatalogItem] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            print("❌ exercises.json not found (Target Membership?)")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([CatalogItem].self, from: data)
            return items
        } catch {
            print("❌ exercises.json decode error:", error)
            return []
        }
    }

    static func grouped() -> [(group: String, items: [CatalogItem])] {
        let items = load()
        let grouped = Dictionary(grouping: items, by: { $0.muscleGroup })
        // sort by muscle group, then by type then name
        return grouped
            .map { (key: $0.key,
                    items: $0.value.sorted { ($0.type, $0.name) < ($1.type, $1.name) }) }
            .sorted { $0.group < $1.group }
    }
}
