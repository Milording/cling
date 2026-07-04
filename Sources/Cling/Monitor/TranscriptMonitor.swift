import Foundation

/// Tails Claude Code transcripts under `~/.claude/projects/`, emitting parsed events
/// for bytes appended since the last poll. Polling (2s) is used instead of FSEvents:
/// the directory holds a handful of small files, and polling keeps the code trivial.
@MainActor
final class TranscriptMonitor {
    let projectsDirectory: URL
    var onEvents: (([TranscriptEvent]) -> Void)?

    /// Byte offset already consumed, keyed by file path. Persisted by the caller.
    var offsets: [String: UInt64] = [:]
    /// Most recent transcript modification observed (drives the status indicator).
    private(set) var lastActivity: Date?
    private(set) var directoryExists = false

    private var timer: Timer?

    init(projectsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/projects")) {
        self.projectsDirectory = projectsDirectory
    }

    /// Skip everything already on disk; called on first launch so history is not replayed.
    func baselineToCurrentEnd() {
        for url in transcriptFiles() {
            offsets[url.path] = fileSize(url)
        }
    }

    func start(interval: TimeInterval = 2) {
        stop()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func poll() {
        directoryExists = FileManager.default.fileExists(atPath: projectsDirectory.path)
        var events: [TranscriptEvent] = []
        for url in transcriptFiles() {
            if let mtime = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                if lastActivity.map({ mtime > $0 }) ?? true { lastActivity = mtime }
            }
            events.append(contentsOf: readNewEvents(from: url))
        }
        if !events.isEmpty {
            events.sort { $0.timestamp < $1.timestamp }
            onEvents?(events)
        }
    }

    private func readNewEvents(from url: URL) -> [TranscriptEvent] {
        let path = url.path
        let size = fileSize(url)
        var offset = offsets[path] ?? 0
        if size < offset { offset = 0 } // file replaced or truncated
        guard size > offset, let handle = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { try? handle.close() }

        guard (try? handle.seek(toOffset: offset)) != nil,
              let data = try? handle.readToEnd(), !data.isEmpty else { return [] }

        // Only consume up to the final newline; a partial trailing line is re-read next poll.
        guard let lastNewline = data.lastIndex(of: UInt8(ascii: "\n")) else { return [] }
        let complete = data[data.startIndex...lastNewline]
        offsets[path] = offset + UInt64(complete.count)

        guard let text = String(data: complete, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap { JSONLParser.parse(line: String($0)) }
    }

    private func transcriptFiles() -> [URL] {
        guard let projects = try? FileManager.default.contentsOfDirectory(
            at: projectsDirectory, includingPropertiesForKeys: nil) else { return [] }
        return projects.flatMap { project in
            (try? FileManager.default.contentsOfDirectory(
                at: project, includingPropertiesForKeys: [.contentModificationDateKey]))?
                .filter { $0.pathExtension == "jsonl" } ?? []
        }
    }

    private func fileSize(_ url: URL) -> UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
    }
}
