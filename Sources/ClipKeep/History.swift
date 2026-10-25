import Foundation

struct Clip: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var app: String?
    var date = Date()
}

// Pure logic, kept separate so --selftest can check it without a pasteboard.
enum History {
    static let limit = 500

    /// New clip goes on top; an identical older text is removed instead of duplicated.
    static func adding(_ clip: Clip, to clips: [Clip]) -> [Clip] {
        Array(([clip] + clips.filter { $0.text != clip.text }).prefix(limit))
    }

    /// Every word must appear somewhere in the text or app name, case-insensitive.
    static func search(_ query: String, in clips: [Clip]) -> [Clip] {
        let words = query.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return clips }
        return clips.filter { clip in
            let hay = clip.text + " " + (clip.app ?? "")
            return words.allSatisfy { hay.localizedCaseInsensitiveContains($0) }
        }
    }
}

// ponytail: whole-file JSON rewrite on every copy; fine for 500 text clips, switch to append-only JSONL if history grows large.
struct FileStore {
    let url: URL

    static var standard: FileStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipKeep", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return FileStore(url: dir.appendingPathComponent("history.json"))
    }

    func load() -> [Clip] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Clip].self, from: data)) ?? []
    }

    func save(_ clips: [Clip]) {
        guard let data = try? JSONEncoder().encode(clips) else { return }
        try? data.write(to: url, options: [.atomic])
        // Clipboard history can hold secrets: owner-only file.
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
