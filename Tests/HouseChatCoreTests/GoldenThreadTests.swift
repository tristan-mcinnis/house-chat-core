import Foundation
import Testing
@testable import HouseChatCore

/// An AI Chat thread as the Swift encoder writes it. Any other writer of the
/// shared schema tests against the same file, so a schema change here must
/// land with a regenerated fixture.
@Suite("Golden AI Chat thread")
struct GoldenThreadTests {
    private static let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/thread-golden.json")

    private static func record() -> ConversationRecord {
        let answer = AppPayload(namespace: "quick-launch", [
            "titleSource": .string("auto"),
            "assistantID": .string("default"),
            "enabledTools": .array([.string("web-search"), .string("calculator")]),
            "toolRecords": .array([
                .object([
                    "tool": .string("web-search"),
                    "query": .string("tokyo local time"),
                    "ok": .bool(true),
                ]),
            ]),
            "confidence": .number(0.75),
            "rank": .number(2),
            "note": .null,
        ])
        let notice = AppPayload(namespace: "quick-launch", [
            "kind": .string("provider-switch"),
            "provider": .string("local"),
        ])
        return ConversationRecord(
            id: "ai-chat-main",
            surface: .quickLaunch,
            title: "Time in Tokyo",
            createdAt: Date(timeIntervalSince1970: 1_792_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_792_053_000.5),
            sessionLinks: [SessionLink(kind: "web-page", id: "example", label: "Example")],
            turns: [
                TurnRecord(
                    id: "5c1e9a44-2f0b-4d8e-8b7a-93a6e0f1d2c3",
                    role: .user,
                    text: "What time is it in Tokyo?",
                    createdAt: Date(timeIntervalSince1970: 1_792_052_990)
                ),
                TurnRecord(
                    id: "0b6d2f7e-6a1c-4c53-9e2a-1d8f4a7c5b10",
                    role: .assistant,
                    text: "It is 17:30 in Tokyo.\n東京は17時30分です。",
                    createdAt: Date(timeIntervalSince1970: 1_792_053_000.125),
                    appPayload: answer
                ),
                TurnRecord(
                    id: "a7d3b8e1-4c92-4f6a-b5d0-6e1f2a9c8b47",
                    role: .system,
                    text: "Switched to the local model.",
                    createdAt: Date(timeIntervalSince1970: 1_792_053_101),
                    appPayload: notice
                ),
            ],
            appVersion: "quick-launch-1"
        )
    }

    private static func encoded(_ record: ConversationRecord) throws -> Data {
        try HouseChatCoding.makeEncoder(prettyPrinted: true).encode(record) + Data("\n".utf8)
    }

    @Test("The encoder still writes the committed file, byte for byte")
    func encoderMatchesFixture() throws {
        let fresh = try Self.encoded(Self.record())
        if ProcessInfo.processInfo.environment["HOUSE_CHAT_CORE_REGENERATE_GOLDEN"] == "1" {
            try fresh.write(to: Self.fixtureURL, options: .atomic)
        }
        let stored = try Data(contentsOf: Self.fixtureURL)
        #expect(String(decoding: fresh, as: UTF8.self) == String(decoding: stored, as: UTF8.self))
    }

    @Test("The file decodes to the record that produced it")
    func decodesToRecord() throws {
        let stored = try Data(contentsOf: Self.fixtureURL)
        let decoded = try HouseChatCoding.makeDecoder().decode(ConversationRecord.self, from: stored)

        #expect(decoded == Self.record())
        #expect(decoded.surface == .quickLaunch)
        #expect(decoded.turns.count == 3)
        #expect(decoded.turns[1].appPayload?.namespace == "quick-launch")
        #expect(decoded.turns[1].appPayload?["titleSource"]?.stringValue == "auto")
        #expect(decoded.turns[1].appPayload?["rank"] == .number(2))
        #expect(decoded.turns[1].appPayload?["note"] == .null)
        #expect(decoded.turns[2].role == .system)
        #expect(decoded.turns[2].attachments.isEmpty)
    }

    @Test("Decode then encode reproduces the file")
    func roundTripIsStable() throws {
        let stored = try Data(contentsOf: Self.fixtureURL)
        let decoded = try HouseChatCoding.makeDecoder().decode(ConversationRecord.self, from: stored)
        let reencoded = try Self.encoded(decoded)
        #expect(String(decoding: reencoded, as: UTF8.self) == String(decoding: stored, as: UTF8.self))
    }
}
