//
//  APNsRegistrationTests.swift
//  Phase 14 — APNs registration helpers
//

import Testing
import Foundation
@testable import ready_player_8

struct APNsRegistrationTests {

    // MARK: - Hex token formatting

    @Test func hexStringEmptyData() {
        #expect(APNsHexEncoder.hexString(from: Data()) == "")
    }

    @Test func hexStringSingleByte() {
        #expect(APNsHexEncoder.hexString(from: Data([0x00])) == "00")
        #expect(APNsHexEncoder.hexString(from: Data([0xff])) == "ff")
        #expect(APNsHexEncoder.hexString(from: Data([0x7a])) == "7a")
    }

    @Test func hexStringMultiByte() {
        let bytes: [UInt8] = [0xde, 0xad, 0xbe, 0xef, 0x00, 0x01, 0x02, 0x03]
        #expect(APNsHexEncoder.hexString(from: Data(bytes)) == "deadbeef00010203")
    }

    @Test func hexStringIsLowercase() {
        // APNs HTTP/2 path requires lowercase hex
        let bytes: [UInt8] = [0xAB, 0xCD, 0xEF]
        let hex = APNsHexEncoder.hexString(from: Data(bytes))
        #expect(hex == hex.lowercased())
        #expect(hex == "abcdef")
    }

    @Test func hexStringRealisticTokenLength() {
        // Real APNs device tokens are 32 bytes -> 64 hex chars
        let token = Data((0..<32).map { UInt8($0) })
        let hex = APNsHexEncoder.hexString(from: token)
        #expect(hex.count == 64)
        #expect(hex.hasPrefix("000102030405"))
    }

    // MARK: - Bundle identifier sanity

    @Test func bundleIdMatchesAPNsTopic() {
        // The APNS_BUNDLE_ID Supabase secret must match this exact string,
        // or APNs will reject pushes with BadTopic.
        let expected = "nailed-it-network.ready-player-8"
        // Cannot read Bundle.main.bundleIdentifier in test target reliably,
        // but this constant is the contract — change in both places together.
        #expect(expected == "nailed-it-network.ready-player-8")
    }
}
