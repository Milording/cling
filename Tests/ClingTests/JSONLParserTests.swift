import XCTest
@testable import Cling

final class JSONLParserTests: XCTestCase {
    private let ts = "2026-07-03T16:24:07.883Z"
    private let session = "3a40c79f-dd3c-4b42-8ac3-9aeb9a295411"

    private func line(_ body: String) -> [TranscriptEvent] {
        JSONLParser.parse(line: body)
    }

    func testHumanUserMessage() {
        let events = line("""
        {"type":"user","message":{"role":"user","content":"Please fix the bug"},"timestamp":"\(ts)","sessionId":"\(session)"}
        """)
        guard case .user(let text, _, let sid)? = events.first else { return XCTFail() }
        XCTAssertEqual(text, "Please fix the bug")
        XCTAssertEqual(sid, session)
    }

    func testSlashCommand() {
        let events = line("""
        {"type":"user","message":{"role":"user","content":"<command-name>/doctor</command-name>"},"timestamp":"\(ts)","sessionId":"\(session)"}
        """)
        guard case .slashCommand(let name, _, _)? = events.first else { return XCTFail() }
        XCTAssertEqual(name, "doctor")
    }

    func testInterruptionMarker() {
        let events = line("""
        {"type":"user","message":{"role":"user","content":"[Request interrupted by user]"},"timestamp":"\(ts)","sessionId":"\(session)"}
        """)
        guard case .interrupted? = events.first else { return XCTFail() }
    }

    func testToolResult() {
        let events = line("""
        {"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"ok","is_error":false}]},"timestamp":"\(ts)","sessionId":"\(session)"}
        """)
        guard case .toolResult(let isError, _, _)? = events.first else { return XCTFail() }
        XCTAssertFalse(isError)
    }

    func testAssistantUsageAndToolUse() {
        let events = line("""
        {"type":"assistant","message":{"role":"assistant","model":"claude-sonnet-4","usage":{"input_tokens":100,"output_tokens":50,"cache_read_input_tokens":10},"content":[{"type":"tool_use","name":"Bash","input":{"command":"git commit -m x"}}]},"timestamp":"\(ts)","sessionId":"\(session)"}
        """)
        guard case .assistant(let usage, let model, _, _) = events[0] else { return XCTFail() }
        XCTAssertEqual(usage.total, 160)
        XCTAssertEqual(model, "claude-sonnet-4")
        guard case .toolUse(let name, let input, _, _) = events[1] else { return XCTFail() }
        XCTAssertEqual(name, "Bash")
        XCTAssertTrue(input.contains("git commit"))
    }

    func testMcpToolUse() {
        let events = line("""
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"mcp__sentry__find_issues","input":{}}]},"timestamp":"\(ts)","sessionId":"\(session)"}
        """)
        guard case .toolUse(let name, _, _, _) = events.first(where: { if case .toolUse = $0 { return true }; return false })! else {
            return XCTFail()
        }
        XCTAssertTrue(name.hasPrefix("mcp__"))
    }

    func testSnapshotAndGarbageIgnored() {
        XCTAssertTrue(line("{\"type\":\"file-history-snapshot\"}").isEmpty)
        XCTAssertTrue(line("not json").isEmpty)
    }
}
