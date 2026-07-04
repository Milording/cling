import XCTest
@testable import Cling

final class JSONLParserTests: XCTestCase {
    private let ts = "2026-07-03T16:24:07.883Z"
    private let session = "3a40c79f-dd3c-4b42-8ac3-9aeb9a295411"

    func testHumanUserMessage() throws {
        let line = """
        {"type":"user","message":{"role":"user","content":"Please fix the bug"},"timestamp":"\(ts)","sessionId":"\(session)"}
        """
        guard case .userMessage(let text, let date, let sid)? = JSONLParser.parse(line: line) else {
            return XCTFail("expected userMessage")
        }
        XCTAssertEqual(text, "Please fix the bug")
        XCTAssertEqual(sid, session)
        XCTAssertEqual(date.timeIntervalSince1970, 1783095847.883, accuracy: 0.01)
    }

    func testMetaUserMessageIsActivity() {
        let line = """
        {"type":"user","isMeta":true,"message":{"role":"user","content":"<local-command-caveat>x</local-command-caveat>"},"timestamp":"\(ts)","sessionId":"\(session)"}
        """
        guard case .activity? = JSONLParser.parse(line: line) else {
            return XCTFail("expected activity")
        }
    }

    func testCommandWrapperIsActivity() {
        let line = """
        {"type":"user","message":{"role":"user","content":"<command-name>/model</command-name>"},"timestamp":"\(ts)","sessionId":"\(session)"}
        """
        guard case .activity? = JSONLParser.parse(line: line) else {
            return XCTFail("expected activity")
        }
    }

    func testToolResultIsActivity() {
        let line = """
        {"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"ok","tool_use_id":"t1"}]},"timestamp":"\(ts)","sessionId":"\(session)"}
        """
        guard case .activity? = JSONLParser.parse(line: line) else {
            return XCTFail("expected activity")
        }
    }

    func testUserMessageWithContentBlocks() {
        let line = """
        {"type":"user","message":{"role":"user","content":[{"type":"text","text":"thank you Claude"},{"type":"image","source":{}}]},"timestamp":"\(ts)","sessionId":"\(session)"}
        """
        guard case .userMessage(let text, _, _)? = JSONLParser.parse(line: line) else {
            return XCTFail("expected userMessage")
        }
        XCTAssertEqual(text, "thank you Claude")
    }

    func testAssistantMessageTokens() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":7389,"output_tokens":212}},"timestamp":"\(ts)","sessionId":"\(session)"}
        """
        guard case .assistantMessage(let tokens, _, _)? = JSONLParser.parse(line: line) else {
            return XCTFail("expected assistantMessage")
        }
        XCTAssertEqual(tokens, 212)
    }

    func testSnapshotLineIsIgnored() {
        let line = """
        {"type":"file-history-snapshot","messageId":"m1","snapshot":{"timestamp":"\(ts)"}}
        """
        XCTAssertNil(JSONLParser.parse(line: line))
    }

    func testGarbageIsIgnored() {
        XCTAssertNil(JSONLParser.parse(line: "not json at all"))
        XCTAssertNil(JSONLParser.parse(line: "{\"type\":\"user\"}"))
    }
}
