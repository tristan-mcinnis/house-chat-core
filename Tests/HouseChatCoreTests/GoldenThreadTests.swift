import Foundation
import Testing
@testable import HouseChatCore

/// The chief-of-staff thread as the Swift encoder writes it. The Python writer
/// in `chief-of-staff/cos/thread.py` tests against the same file, so a schema
/// change here must land with a regenerated fixture.
@Suite("Golden chief-of-staff thread")
struct GoldenThreadTests {
    private static let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/thread-golden.json")

    private static func record() -> ConversationRecord {
        let proposal = AppPayload(namespace: "chief-of-staff", [
            "kind": .string("proposal"),
            "id": .string("3fa91c07"),
            "status": .string("pending"),
            "project": .string("acme"),
            "event_kind": .string("mail"),
            "title": .string("Re: Q4 scope"),
            "sender": .string("Jane Doe"),
            "paths": .array([.string("mail/example-scope.md")]),
            "reason": .string("A client asked for a date."),
            "message": .string("Jane Doe wants a Q4 scope date.\n季度范围需要日期。"),
            "actions": .array([
                .object([
                    "type": .string("task_add"),
                    "title": .string("Send Q4 scope date to Jane Doe"),
                    "due": .string("2026-10-20"),
                    "project": .string("acme"),
                ]),
                .object([
                    "type": .string("draft_reply"),
                    "body": .string("Hi Jane, the scope lands on 20 Oct."),
                ]),
            ]),
            "created": .string("2026-10-15T08:30:00.125Z"),
            "tier": .string("today"),
            "importance": .string("client"),
            "due": .string("2026-10-20"),
            "headline": .string("Q4 scope date for Jane Doe"),
            "why": .string("Client waiting, one-line answer."),
            "silent": .bool(false),
            "confidence": .number(0.75),
            "rank": .number(2),
            "note": .null,
        ])
        let verdict = AppPayload(namespace: "chief-of-staff", [
            "kind": .string("verdict"),
            "proposal": .string("3fa91c07"),
            "verdict": .string("do"),
        ])
        return ConversationRecord(
            id: "chief-of-staff-main",
            surface: ChatSurface("chief-of-staff"),
            title: "Chief of Staff",
            createdAt: Date(timeIntervalSince1970: 1_792_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_792_053_000.5),
            sessionLinks: [SessionLink(kind: "vault-note", id: "acme", label: "Acme")],
            turns: [
                TurnRecord(
                    id: "0b6d2f7e-6a1c-4c53-9e2a-1d8f4a7c5b10",
                    role: .assistant,
                    text: "Jane Doe wants a Q4 scope date.\n季度范围需要日期。",
                    createdAt: Date(timeIntervalSince1970: 1_792_053_000.125),
                    appPayload: proposal
                ),
                TurnRecord(
                    id: "5c1e9a44-2f0b-4d8e-8b7a-93a6e0f1d2c3",
                    role: .user,
                    text: "Do it.",
                    createdAt: Date(timeIntervalSince1970: 1_792_053_100)
                ),
                TurnRecord(
                    id: "a7d3b8e1-4c92-4f6a-b5d0-6e1f2a9c8b47",
                    role: .system,
                    text: "Done: task added.",
                    createdAt: Date(timeIntervalSince1970: 1_792_053_101),
                    appPayload: verdict
                ),
            ],
            appVersion: "cos-1"
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
        #expect(decoded.surface == ChatSurface("chief-of-staff"))
        #expect(decoded.turns.count == 3)
        #expect(decoded.turns[0].appPayload?.namespace == "chief-of-staff")
        #expect(decoded.turns[0].appPayload?["status"]?.stringValue == "pending")
        #expect(decoded.turns[0].appPayload?["rank"] == .number(2))
        #expect(decoded.turns[0].appPayload?["note"] == .null)
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
