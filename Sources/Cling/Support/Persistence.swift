import Foundation

enum Persistence {
    static var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cling/state.json")
    }

    static func load() -> EngineState? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(EngineState.self, from: data)
    }

    static func save(_ state: EngineState) {
        let url = stateURL
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: url, options: .atomic)
        } catch {
            NSLog("Cling: failed to save state: \(error)")
        }
    }
}
