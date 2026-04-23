//
//  SupabaseNotificationDTOTests.swift
//  Phase 30 — D-24 entity_id / entity_type passthrough regression
//
//  Locks the JSON decode contract so a future refactor that drops
//  entityType/entityId from SupabaseNotification — or breaks the decoder's
//  convertFromSnakeCase strategy — fails at test time instead of silently
//  dropping deep-link payloads when the deferred routing phase lands.
//

import Testing
import Foundation
@testable import ready_player_8

struct SupabaseNotificationDTOTests {

    // Matches the decoder used by SupabaseService for cs_notifications rows.
    // See SupabaseService.swift:1682 ("Decoder uses .convertFromSnakeCase, so
    // Swift property names are camelCase.").
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    @Test func test_decode_preservesEntityIdAndEntityType() throws {
        let json = """
        {
          "id": "n1",
          "user_id": "u1",
          "event_id": "e1",
          "project_id": "p1",
          "category": "assigned_task",
          "title": "Test",
          "body": "body text",
          "entity_type": "cs_rfis",
          "entity_id": "rfi-42",
          "read_at": null,
          "dismissed_at": null,
          "created_at": "2026-04-22T00:00:00Z"
        }
        """.data(using: .utf8)!
        let n = try decoder().decode(SupabaseNotification.self, from: json)
        #expect(n.entityType == "cs_rfis")
        #expect(n.entityId == "rfi-42")
    }

    @Test func test_decode_nullEntityFieldsRemainNil() throws {
        let json = """
        {
          "id": "n2",
          "user_id": "u1",
          "event_id": "e2",
          "project_id": null,
          "category": "generic",
          "title": "Nil entity",
          "body": null,
          "entity_type": null,
          "entity_id": null,
          "read_at": null,
          "dismissed_at": null,
          "created_at": "2026-04-22T00:00:00Z"
        }
        """.data(using: .utf8)!
        let n = try decoder().decode(SupabaseNotification.self, from: json)
        #expect(n.entityType == nil)
        #expect(n.entityId == nil)
    }

    @Test func test_decode_omittedEntityFieldsToleratedAsNil() throws {
        // Server may omit the keys entirely when PostgREST returns a narrow
        // projection or a legacy row predates the columns. DTO properties are
        // Optional so decode must succeed with both fields nil — never throw.
        let json = """
        {
          "id": "n3",
          "user_id": "u1",
          "event_id": "e3",
          "project_id": "p1",
          "category": "generic",
          "title": "Missing entity keys",
          "body": null,
          "read_at": null,
          "dismissed_at": null,
          "created_at": "2026-04-22T00:00:00Z"
        }
        """.data(using: .utf8)!
        let n = try decoder().decode(SupabaseNotification.self, from: json)
        #expect(n.entityType == nil)
        #expect(n.entityId == nil)
    }
}
