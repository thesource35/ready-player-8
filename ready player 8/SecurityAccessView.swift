import CoreImage
import CoreImage.CIFilterBuiltins
import CryptoKit
import Foundation
import LocalAuthentication
import Security
import SwiftUI
import Combine
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


// MARK: - ========== SecurityAccessView.swift ==========

// MARK: - Security Enums & Types

enum SecurityTwoFactorMethod: String, CaseIterable {
    case authenticator = "AUTH_APP"
    case sms = "SMS"
    case email = "EMAIL"

    var display: String {
        switch self {
        case .authenticator: return "Authenticator App"
        case .sms: return "SMS OTP"
        case .email: return "Email OTP"
        }
    }
}

enum SecurityCredentialKey: String {
    case passwordHash = "passwordHash"
    case twoFactorSecret = "twoFactorSecret"
}

enum SecuritySecureStore {
    static let service = "ConstructOS.Security"

    static func read(_ key: SecurityCredentialKey) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }

        return value
    }

    static func save(_ value: String, for key: SecurityCredentialKey) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var create = query
            create[kSecValueData as String] = data
            SecItemAdd(create as CFDictionary, nil)
        }
    }

    static func delete(_ key: SecurityCredentialKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Security Helper Functions

func securityPasswordHash(_ password: String) -> String {
    let digest = SHA256.hash(data: Data(password.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}

func securityBiometricsAvailable() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
}

func securityBiometricLabel() -> String {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        return "Biometric Unlock"
    }

    switch context.biometryType {
    case .faceID:
        return "Face ID"
    case .touchID:
        return "Touch ID"
    default:
        return "Biometric Unlock"
    }
}

let securityAuditLogKey = "ConstructOS.Security.AuditLog"
let securityForceLockNotification = Notification.Name("ConstructOS.SecurityForceLock")
let securityOutOfBandCodeKey = "ConstructOS.Security.OutOfBandCode"
let securityOutOfBandExpiryKey = "ConstructOS.Security.OutOfBandExpiry"
let securityOutOfBandLastSentKey = "ConstructOS.Security.OutOfBandLastSent"
let securityOutOfBandMethodKey = "ConstructOS.Security.OutOfBandMethod"

#if os(macOS)
typealias PlatformSecurityImage = NSImage
#elseif os(iOS)
typealias PlatformSecurityImage = UIImage
#endif

func base32EncodedString(from data: Data) -> String {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    var encoded = ""
    var buffer = 0
    var bitsLeft = 0

    for byte in data {
        buffer = (buffer << 8) | Int(byte)
        bitsLeft += 8
        while bitsLeft >= 5 {
            let index = (buffer >> (bitsLeft - 5)) & 0x1F
            encoded.append(alphabet[index])
            bitsLeft -= 5
        }
    }

    if bitsLeft > 0 {
        let index = (buffer << (5 - bitsLeft)) & 0x1F
        encoded.append(alphabet[index])
    }

    return encoded
}

func base32DecodedData(_ string: String) -> Data? {
    let alphabet = Dictionary(uniqueKeysWithValues: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".enumerated().map { (Character(String($0.element)), $0.offset) })
    let cleaned = string.uppercased().filter { !$0.isWhitespace && $0 != "=" }
    guard !cleaned.isEmpty else { return nil }

    var buffer = 0
    var bitsLeft = 0
    var bytes: [UInt8] = []

    for character in cleaned {
        guard let value = alphabet[character] else { return nil }
        buffer = (buffer << 5) | value
        bitsLeft += 5
        if bitsLeft >= 8 {
            let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
            bytes.append(byte)
            bitsLeft -= 8
        }
    }

    return Data(bytes)
}

func normalizedSecuritySecret(_ secret: String) -> String {
    let cleaned = secret.uppercased().replacingOccurrences(of: " ", with: "")
    if let data = base32DecodedData(cleaned), !data.isEmpty {
        return cleaned
    }
    return base32EncodedString(from: Data(cleaned.utf8))
}

func generateSecuritySecret() -> String {
    var bytes = [UInt8](repeating: 0, count: 20)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return base32EncodedString(from: Data(bytes))
}

func securityTwoFactorCode(secret: String, at date: Date = Date()) -> String {
    guard let secretData = base32DecodedData(secret), !secretData.isEmpty else { return "000000" }

    let counter = UInt64(date.timeIntervalSince1970 / 30).bigEndian
    let counterData = withUnsafeBytes(of: counter) { Data($0) }
    let key = SymmetricKey(data: secretData)
    let digest = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
    let hash = Array(digest)
    let offset = Int(hash.last! & 0x0F)
    let binary = (UInt32(hash[offset] & 0x7F) << 24)
        | (UInt32(hash[offset + 1]) << 16)
        | (UInt32(hash[offset + 2]) << 8)
        | UInt32(hash[offset + 3])
    return String(format: "%06d", Int(binary % 1_000_000))
}

func securityRecoveryCodes(secret: String) -> [String] {
    guard !secret.isEmpty else { return [] }
    return (0..<6).map { index in
        let seed = base32EncodedString(from: Data("\(secret)-R\(index)".utf8))
        let code = securityTwoFactorCode(secret: seed, at: Date(timeIntervalSince1970: Double(index * 45)))
        return "RC-\(code.prefix(3))-\(code.suffix(3))"
    }
}

func normalizedEmergencyCode(_ raw: String) -> String {
    raw.uppercased().filter { $0.isLetter || $0.isNumber }
}

func securityEmergencyCodes(count: Int = 6) -> [String] {
    let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    func token(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(alphabet[Int($0) % alphabet.count]) }.joined()
    }

    return (0..<count).map { _ in
        "EC-\(token(length: 4))-\(token(length: 4))"
    }
}

func generateOutOfBandSecurityCode(length: Int = 6) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return bytes.map { String(Int($0) % 10) }.joined()
}

func issueOutOfBandSecurityCode(method: SecurityTwoFactorMethod, ttl: TimeInterval = 300) -> String {
    let code = generateOutOfBandSecurityCode()
    let now = Date()
    UserDefaults.standard.set(code, forKey: securityOutOfBandCodeKey)
    UserDefaults.standard.set(now.addingTimeInterval(ttl).timeIntervalSince1970, forKey: securityOutOfBandExpiryKey)
    UserDefaults.standard.set(now.timeIntervalSince1970, forKey: securityOutOfBandLastSentKey)
    UserDefaults.standard.set(method.rawValue, forKey: securityOutOfBandMethodKey)
    return code
}

func currentOutOfBandSecurityCode() -> String {
    UserDefaults.standard.string(forKey: securityOutOfBandCodeKey) ?? ""
}

func currentOutOfBandSecurityExpiry() -> Double {
    UserDefaults.standard.double(forKey: securityOutOfBandExpiryKey)
}

func currentOutOfBandLastSentAt() -> Double {
    UserDefaults.standard.double(forKey: securityOutOfBandLastSentKey)
}

func currentOutOfBandSecurityMethod() -> SecurityTwoFactorMethod? {
    guard let raw = UserDefaults.standard.string(forKey: securityOutOfBandMethodKey) else { return nil }
    return SecurityTwoFactorMethod(rawValue: raw)
}

func clearOutOfBandSecurityCode() {
    UserDefaults.standard.removeObject(forKey: securityOutOfBandCodeKey)
    UserDefaults.standard.removeObject(forKey: securityOutOfBandExpiryKey)
    UserDefaults.standard.removeObject(forKey: securityOutOfBandLastSentKey)
    UserDefaults.standard.removeObject(forKey: securityOutOfBandMethodKey)
}

func validateOutOfBandSecurityCode(_ input: String, method: SecurityTwoFactorMethod) -> Bool {
    let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty,
          let activeMethod = currentOutOfBandSecurityMethod(),
          activeMethod == method,
          currentOutOfBandSecurityExpiry() > Date().timeIntervalSince1970 else {
        return false
    }
    return normalized == currentOutOfBandSecurityCode()
}

func securityAuditEntries() -> [String] {
    UserDefaults.standard.stringArray(forKey: securityAuditLogKey) ?? []
}

func auditEntryHash(_ entry: String, previous: String) -> String {
    let input = previous + entry
    let data = Data(input.utf8)
    let digest = SHA256.hash(data: data)
    return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
}

func appendSecurityAudit(_ message: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"
    var entries = securityAuditEntries()
    let previous = entries.first ?? ""
    let entry = "[\(formatter.string(from: Date()))] \(message)"
    let hash = auditEntryHash(entry, previous: previous)
    entries.insert("\(entry) #\(hash)", at: 0)
    UserDefaults.standard.set(Array(entries.prefix(20)), forKey: securityAuditLogKey)
}

func securityOtpAuthURL(secret: String, accountName: String = "ops@constructionos.app", issuer: String = "Construction OS") -> String {
    guard !secret.isEmpty else { return "" }
    let allowed = CharacterSet.urlQueryAllowed
    let encodedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: allowed) ?? issuer
    let encodedAccount = accountName.addingPercentEncoding(withAllowedCharacters: allowed) ?? accountName
    return "otpauth://totp/\(encodedIssuer):\(encodedAccount)?secret=\(secret)&issuer=\(encodedIssuer)&algorithm=SHA1&digits=6&period=30"
}

func securityQRCodeImage(from string: String, scale: CGFloat = 10) -> PlatformSecurityImage? {
    guard !string.isEmpty else { return nil }
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"

    guard let outputImage = filter.outputImage else { return nil }
    let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }

#if os(macOS)
    return NSImage(cgImage: cgImage, size: NSSize(width: transformedImage.extent.width, height: transformedImage.extent.height))
#elseif os(iOS)
    return UIImage(cgImage: cgImage)
#endif
}

func copyTextToClipboard(_ text: String, autoClearAfter seconds: TimeInterval = 30) {
#if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    let changeCount = NSPasteboard.general.changeCount
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(seconds))
        if NSPasteboard.general.changeCount == changeCount {
            NSPasteboard.general.clearContents()
        }
    }
#elseif os(iOS)
    UIPasteboard.general.string = text
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(seconds))
        if UIPasteboard.general.string == text {
            UIPasteboard.general.string = ""
        }
    }
#endif
}

private func securityPasswordStrength(_ password: String) -> (score: Int, label: String) {
    var score = 0
    if password.count >= 8  { score += 1 }
    if password.count >= 12 { score += 1 }
    if password.unicodeScalars.contains(where: { CharacterSet.uppercaseLetters.contains($0) }) { score += 1 }
    if password.unicodeScalars.contains(where: { CharacterSet.lowercaseLetters.contains($0) }) { score += 1 }
    if password.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) }) { score += 1 }
    let symbols = CharacterSet.alphanumerics.inverted
    if password.unicodeScalars.contains(where: { symbols.contains($0) }) { score += 1 }
    let label: String
    switch score {
    case 0...2: label = "WEAK"
    case 3...4: label = "FAIR"
    case 5:     label = "STRONG"
    default:    label = "VERY STRONG"
    }
    return (score, label)
}

// MARK: - Security Access

struct SecurityAccessPanel: View {
    @AppStorage("ConstructOS.Security.PasswordEnabled") private var passwordEnabledRaw: Bool = false
    @AppStorage("ConstructOS.Security.PasswordValue") private var legacyStoredPassword: String = ""
    @AppStorage("ConstructOS.Security.TwoFactorEnabled") private var twoFactorEnabledRaw: Bool = false
    @AppStorage("ConstructOS.Security.TwoFactorSecret") private var legacyTwoFactorSecret: String = ""
    @AppStorage("ConstructOS.Security.TwoFactorMethod") private var twoFactorMethodRaw: String = SecurityTwoFactorMethod.authenticator.rawValue
    @AppStorage("ConstructOS.Security.BiometricEnabled") private var biometricEnabledRaw: Bool = false
    @AppStorage("ConstructOS.Security.FailedAttempts") private var failedUnlockAttempts: Int = 0
    @AppStorage("ConstructOS.Security.LockoutUntil") private var lockoutUntilEpoch: Double = 0
    @AppStorage("ConstructOS.Security.IdleLockEnabled") private var idleLockEnabledRaw: Bool = true
    @AppStorage("ConstructOS.Security.IdleLockMinutes") private var idleLockMinutesRaw: Int = 5
    @AppStorage("ConstructOS.Security.TrustedUntil") private var trustedUntilEpoch: Double = 0
    @AppStorage("ConstructOS.Security.TrustHours") private var trustedDeviceHoursRaw: Int = 8
    @AppStorage("ConstructOS.Security.EmergencyCodes") private var emergencyCodesRaw: String = ""
    @AppStorage("ConstructOS.Security.AuthAccount") private var authAccountNameRaw: String = "ops@constructionos.app"
    @AppStorage("ConstructOS.Security.AuthIssuer") private var authIssuerRaw: String = "Construction OS"
    @AppStorage("ConstructOS.Security.SMSNumber") private var smsNumberRaw: String = "+1 (555) 010-2424"
    @AppStorage("ConstructOS.Security.EmailDestination") private var emailDestinationRaw: String = "ops@constructionos.app"
    @AppStorage("ConstructOS.Security.LastUnlockEpoch") private var lastUnlockEpoch: Double = 0
    @AppStorage("ConstructOS.Security.LastFailedEpoch") private var lastFailedEpoch: Double = 0
    @State private var currentPasswordInput: String = ""
    @State private var newPasswordInput: String = ""
    @State private var confirmPasswordInput: String = ""
    @State private var statusMessage: String?
    @State private var now: Date = Date()
    @State private var storedPasswordHash: String = ""
    @State private var twoFactorSecret: String = ""
    @State private var biometricAvailable: Bool = false
    @State private var auditEntries: [String] = loadJSON("ConstructOS.Security.AuditLog", default: [String]())
    @State private var showRotateConfirmation: Bool = false
    @State private var showDisablePasswordAlert: Bool = false
    @State private var showDisable2FAAlert: Bool = false
    @State private var reauthInput: String = ""
    @State private var demoOutOfBandCode: String?
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var passwordConfigured: Bool {
        !storedPasswordHash.isEmpty
    }

    private var passwordProtectionEnabled: Bool {
        passwordEnabledRaw && passwordConfigured
    }

    private var twoFactorMethod: SecurityTwoFactorMethod {
        SecurityTwoFactorMethod(rawValue: twoFactorMethodRaw) ?? .authenticator
    }

    private var twoFactorReady: Bool {
        passwordProtectionEnabled && twoFactorEnabledRaw && !twoFactorSecret.isEmpty
    }

    private var biometricLabel: String {
        securityBiometricLabel()
    }

    private var isLockedOut: Bool {
        Date().timeIntervalSince1970 < lockoutUntilEpoch
    }

    private var lockoutRemainingSeconds: Int {
        max(0, Int(ceil(lockoutUntilEpoch - Date().timeIntervalSince1970)))
    }

    private var liveCode: String {
        securityTwoFactorCode(secret: twoFactorSecret, at: now)
    }

    private var recoveryCodes: [String] {
        securityRecoveryCodes(secret: twoFactorSecret)
    }

    private var emergencyCodes: [String] {
        emergencyCodesRaw
            .split(separator: "|")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    private var otpAuthURL: String {
        securityOtpAuthURL(secret: twoFactorSecret, accountName: authenticatorAccountName, issuer: authenticatorIssuer)
    }

    private var authenticatorAccountName: String {
        let trimmed = authAccountNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ops@constructionos.app" : trimmed
    }

    private var authenticatorIssuer: String {
        let trimmed = authIssuerRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Construction OS" : trimmed
    }

    private var trustedDeviceActive: Bool {
        Date().timeIntervalSince1970 < trustedUntilEpoch
    }

    private var trustedDeviceHours: Int {
        max(trustedDeviceHoursRaw, 1)
    }

    private var trustedUntilLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: Date(timeIntervalSince1970: trustedUntilEpoch))
    }

    private var outOfBandCodeExpiresIn: Int {
        max(0, Int(ceil(currentOutOfBandSecurityExpiry() - Date().timeIntervalSince1970)))
    }

    private var outOfBandLastSentAgo: Int {
        guard currentOutOfBandLastSentAt() > 0 else { return 0 }
        return max(0, Int(Date().timeIntervalSince1970 - currentOutOfBandLastSentAt()))
    }

    private var outOfBandDestination: String {
        let rawValue = twoFactorMethod == .sms ? smsNumberRaw : emailDestinationRaw
        return rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var securityHealthScore: Int {
        var score = 0
        if passwordProtectionEnabled { score += 35 }
        if twoFactorReady { score += 30 }
        if !emergencyCodes.isEmpty { score += 20 }
        if !isLockedOut { score += 10 }
        if !trustedDeviceActive || trustedDeviceHours <= 8 { score += 5 }
        return min(100, max(0, score))
    }

    private var securityHealthLabel: String {
        if securityHealthScore >= 85 { return "HARDENED" }
        if securityHealthScore >= 65 { return "GOOD" }
        if securityHealthScore >= 45 { return "NEEDS ATTENTION" }
        return "AT RISK"
    }

    private var securityHealthColor: Color {
        if securityHealthScore >= 85 { return Theme.green }
        if securityHealthScore >= 65 { return Theme.cyan }
        if securityHealthScore >= 45 { return Theme.gold }
        return Theme.red
    }

    private var authenticatorActionRow: some View {
        HStack(spacing: 12) {
            Button("COPY SECRET") { copyAuthenticatorSecret() }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.cyan)
            Button("COPY SETUP URI") { copyAuthenticatorURI() }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.gold)
            Button("COPY RECOVERY") { copyRecoveryPack() }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.green)
        }
    }

        #if os(macOS)
            private func qrCodeImageView(_ qrCode: PlatformSecurityImage) -> some View {
                Image(nsImage: qrCode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        #elseif os(iOS)
            private func qrCodeImageView(_ qrCode: PlatformSecurityImage) -> some View {
                Image(uiImage: qrCode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        #endif

    @ViewBuilder
    private var qrCodePreview: some View {
        if let qrCode = securityQRCodeImage(from: otpAuthURL) {
                qrCodeImageView(qrCode)
        }
    }

    private var twoFactorSetupSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current TOTP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                        Text(liveCode)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(Theme.gold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Setup key")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                        Text(String(twoFactorSecret.prefix(24)))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.cyan)
                    }
                }

                Text("Scan the QR with 1Password, Google Authenticator, Microsoft Authenticator, or any RFC 6238 TOTP app.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)

                authenticatorActionRow
            }

            Spacer()
            qrCodePreview
        }
    }

    private func refreshState() {
        if authAccountNameRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authAccountNameRaw = "ops@constructionos.app"
        }

        if authIssuerRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authIssuerRaw = "Construction OS"
        }

        if !legacyStoredPassword.isEmpty && SecuritySecureStore.read(.passwordHash).isEmpty {
            SecuritySecureStore.save(securityPasswordHash(legacyStoredPassword), for: .passwordHash)
            appendSecurityAudit("Migrated password credential into Keychain")
            legacyStoredPassword = ""
        }

        if !legacyTwoFactorSecret.isEmpty && SecuritySecureStore.read(.twoFactorSecret).isEmpty {
            let normalized = normalizedSecuritySecret(legacyTwoFactorSecret)
            SecuritySecureStore.save(normalized, for: .twoFactorSecret)
            appendSecurityAudit("Migrated 2FA secret into Keychain")
            legacyTwoFactorSecret = ""
        }

        storedPasswordHash = SecuritySecureStore.read(.passwordHash)
        twoFactorSecret = SecuritySecureStore.read(.twoFactorSecret)
        biometricAvailable = securityBiometricsAvailable()
        auditEntries = Array(securityAuditEntries().prefix(5))
        if currentOutOfBandSecurityExpiry() <= Date().timeIntervalSince1970 {
            demoOutOfBandCode = nil
        }

        if twoFactorEnabledRaw && twoFactorSecret.isEmpty {
            let secret = generateSecuritySecret()
            SecuritySecureStore.save(secret, for: .twoFactorSecret)
            twoFactorSecret = secret
            appendSecurityAudit("Generated new TOTP secret")
            auditEntries = Array(securityAuditEntries().prefix(5))
        }

        if twoFactorEnabledRaw && emergencyCodes.isEmpty {
            emergencyCodesRaw = securityEmergencyCodes().joined(separator: "|")
            appendSecurityAudit("Generated emergency unlock codes")
            auditEntries = Array(securityAuditEntries().prefix(5))
        }
    }

    private func postStatus(_ message: String) {
        statusMessage = message
        auditEntries = Array(securityAuditEntries().prefix(5))
    }

    private func savePassword() {
        guard newPasswordInput.count >= 6 else {
            statusMessage = "Password must be at least 6 characters."
            return
        }
        guard newPasswordInput == confirmPasswordInput else {
            statusMessage = "Password confirmation does not match."
            return
        }
        let hash = securityPasswordHash(newPasswordInput)
        SecuritySecureStore.save(hash, for: .passwordHash)
        storedPasswordHash = hash
        passwordEnabledRaw = true
        appendSecurityAudit("Enabled password protection")
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmPasswordInput = ""
        postStatus("Password protection enabled.")
    }

    private func updatePassword() {
        guard securityPasswordHash(currentPasswordInput) == storedPasswordHash else {
            statusMessage = "Current password is incorrect."
            return
        }
        guard newPasswordInput.count >= 6 else {
            statusMessage = "New password must be at least 6 characters."
            return
        }
        guard newPasswordInput == confirmPasswordInput else {
            statusMessage = "New password confirmation does not match."
            return
        }
        let hash = securityPasswordHash(newPasswordInput)
        SecuritySecureStore.save(hash, for: .passwordHash)
        storedPasswordHash = hash
        appendSecurityAudit("Updated security password")
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmPasswordInput = ""
        postStatus("Password updated successfully.")
    }

    private func setTwoFactor(_ enabled: Bool) {
        guard enabled else {
            showDisable2FAAlert = true
            return
        }
        guard passwordProtectionEnabled else {
            statusMessage = "Enable password protection before turning on 2FA."
            return
        }
        if twoFactorSecret.isEmpty {
            let secret = generateSecuritySecret()
            SecuritySecureStore.save(secret, for: .twoFactorSecret)
            twoFactorSecret = secret
        }
        twoFactorEnabledRaw = true
        appendSecurityAudit("Enabled 2FA via \(twoFactorMethod.display)")
        postStatus("2FA enabled via \(twoFactorMethod.display).")
    }

    private func sendDemoTwoFactorCode() {
        guard twoFactorReady else {
            statusMessage = "Enable password + 2FA first."
            return
        }
        guard twoFactorMethod != .authenticator else {
            statusMessage = "Authenticator app mode uses TOTP instead of sent codes."
            return
        }
        let destination = twoFactorMethod == .sms ? smsNumberRaw.trimmingCharacters(in: .whitespacesAndNewlines) : emailDestinationRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else {
            statusMessage = "Add a \(twoFactorMethod == .sms ? "phone number" : "delivery email") before sending a demo code."
            return
        }

        let code = issueOutOfBandSecurityCode(method: twoFactorMethod)
        demoOutOfBandCode = code
        let channel = twoFactorMethod == .sms ? "SMS" : "email"
        appendSecurityAudit("Issued demo \(channel) 2FA code to \(destination)")
        postStatus("Demo \(channel) code sent to \(destination): \(code)")
    }

    private func confirmDisablePassword() {
        guard securityPasswordHash(reauthInput) == storedPasswordHash else {
            reauthInput = ""
            postStatus("Incorrect password. Protection not changed.")
            return
        }
        reauthInput = ""
        passwordEnabledRaw = false
        twoFactorEnabledRaw = false
        biometricEnabledRaw = false
        idleLockEnabledRaw = false
        appendSecurityAudit("Disabled app entry protection (re-auth verified)")
        postStatus("Password protection disabled.")
    }

    private func confirmDisable2FA() {
        guard securityPasswordHash(reauthInput) == storedPasswordHash else {
            reauthInput = ""
            postStatus("Incorrect password. 2FA not changed.")
            return
        }
        reauthInput = ""
        twoFactorEnabledRaw = false
        appendSecurityAudit("Disabled 2FA (re-auth verified)")
        postStatus("Two-factor authentication disabled.")
    }

    private func copyRecoveryPack() {
        let payload = (["ConstructOS Security Recovery Pack", "Method: \(twoFactorMethod.display)", ""] + recoveryCodes).joined(separator: "\n")
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied recovery code pack")
        postStatus("Recovery codes copied. Store them offline.")
    }

    private func copyEmergencyCodePack() {
        guard !emergencyCodes.isEmpty else {
            statusMessage = "No emergency codes available. Generate a new pack first."
            return
        }

        let payload = (["ConstructOS Emergency Unlock Codes", ""] + emergencyCodes).joined(separator: "\n")
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied emergency unlock code pack")
        postStatus("Emergency unlock codes copied. Store offline.")
    }

    private func regenerateEmergencyCodes() {
        guard twoFactorReady else {
            statusMessage = "Enable password + 2FA before regenerating emergency codes."
            return
        }

        emergencyCodesRaw = securityEmergencyCodes().joined(separator: "|")
        appendSecurityAudit("Regenerated emergency unlock codes")
        postStatus("Emergency unlock codes rotated.")
    }

    private func copyAuthenticatorSecret() {
        copyTextToClipboard(twoFactorSecret)
        appendSecurityAudit("Copied TOTP setup secret")
        postStatus("Authenticator setup secret copied.")
    }

    private func copyAuthenticatorURI() {
        copyTextToClipboard(otpAuthURL)
        appendSecurityAudit("Copied otpauth setup URI")
        postStatus("Authenticator setup link copied.")
    }

    private func recoveryKitPayload() -> String {
        let auditSnapshot = securityAuditEntries()
        var lines: [String] = [
            "ConstructOS Recovery Kit",
            "Generated: \(Date().formatted(date: .abbreviated, time: .standard))",
            "",
            "Authenticator Profile",
            "- Account: \(authenticatorAccountName)",
            "- Issuer: \(authenticatorIssuer)",
            "- Method: \(twoFactorMethod.display)",
            "",
            "Setup",
            "- Secret: \(twoFactorSecret)",
            "- OTPAuth URI: \(otpAuthURL)",
            "",
            "Recovery Codes",
        ]

        if recoveryCodes.isEmpty {
            lines.append("- No recovery codes available")
        } else {
            lines.append(contentsOf: recoveryCodes.map { "- \($0)" })
        }

        lines.append("")
        lines.append("Emergency Unlock Codes")
        if emergencyCodes.isEmpty {
            lines.append("- No emergency unlock codes available")
        } else {
            lines.append(contentsOf: emergencyCodes.map { "- \($0)" })
        }

        lines.append("")
        lines.append("Security Audit Snapshot")
        if auditSnapshot.isEmpty {
            lines.append("- No audit entries recorded")
        } else {
            lines.append(contentsOf: auditSnapshot.map { "- \($0)" })
        }

        return lines.joined(separator: "\n")
    }

    private func exportRecoveryKit() {
        guard twoFactorReady else {
            statusMessage = "Enable password + 2FA before exporting a recovery kit."
            return
        }

        let payload = recoveryKitPayload()

#if os(macOS)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "constructos-recovery-kit-\(formatter.string(from: Date())).txt"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try payload.write(to: url, atomically: true, encoding: .utf8)
                appendSecurityAudit("Exported recovery kit")
                postStatus("Recovery kit exported to \(url.lastPathComponent).")
            } catch {
                statusMessage = "Failed to export recovery kit."
            }
        }
#elseif os(iOS)
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied recovery kit")
        postStatus("Recovery kit copied for sharing.")
#endif
    }

    private func exportSecurityAudit() {
        let payload = securityAuditEntries().isEmpty
            ? "ConstructOS Security Audit\nNo entries recorded yet."
            : (["ConstructOS Security Audit", ""] + securityAuditEntries()).joined(separator: "\n")

#if os(macOS)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "constructos-security-audit-\(formatter.string(from: Date())).log"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try payload.write(to: url, atomically: true, encoding: .utf8)
                appendSecurityAudit("Exported security audit log")
                postStatus("Audit log exported to \(url.lastPathComponent).")
            } catch {
                statusMessage = "Failed to export audit log."
            }
        }
#elseif os(iOS)
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied security audit log")
        postStatus("Audit log copied for sharing.")
#endif
    }

    private func rotateTwoFactorSecret() {
        guard passwordProtectionEnabled else {
            statusMessage = "Enable password protection before rotating 2FA."
            return
        }
        guard twoFactorEnabledRaw else {
            statusMessage = "Enable 2FA before rotating the authenticator secret."
            return
        }

        let replacement = normalizedSecuritySecret(generateSecuritySecret())
        SecuritySecureStore.save(replacement, for: .twoFactorSecret)
        twoFactorSecret = replacement
        emergencyCodesRaw = securityEmergencyCodes().joined(separator: "|")
        trustedUntilEpoch = 0
        appendSecurityAudit("Rotated 2FA secret and regenerated emergency unlock codes")
        NotificationCenter.default.post(name: securityForceLockNotification, object: nil)
        postStatus("2FA secret rotated. Re-scan the new QR on every authenticator.")
    }

    private func trustCurrentDevice() {
        guard passwordProtectionEnabled else {
            statusMessage = "Enable password protection before trusting this device."
            return
        }

        trustedUntilEpoch = Date().timeIntervalSince1970 + Double(trustedDeviceHours) * 3600
        appendSecurityAudit("Trusted this device for \(trustedDeviceHours)h")
        postStatus("This device is trusted until \(trustedUntilLabel).")
    }

    private func revokeTrustedDevice() {
        trustedUntilEpoch = 0
        appendSecurityAudit("Revoked trusted device session")
        postStatus("Trusted device session cleared.")
    }

    private func lockNow() {
        trustedUntilEpoch = 0
        appendSecurityAudit("Manual security lock triggered")
        NotificationCenter.default.post(name: securityForceLockNotification, object: nil)
        postStatus("App locked. Re-enter credentials to continue.")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "SECURITY",
                    title: "Access and protection controls",
                    detail: "Credential hardening, trust state, and audit visibility for app access.",
                    accent: Theme.gold
                )
                Spacer()
                Text(passwordProtectionEnabled ? "PASSWORD ON" : "PASSWORD OFF")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(passwordProtectionEnabled ? Theme.green : Theme.muted)
                    .cornerRadius(5)
                Text(twoFactorReady ? "2FA ON" : "2FA OFF")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(twoFactorReady ? Theme.gold : Theme.muted)
                    .cornerRadius(5)
            }

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(securityHealthScore)/100", label: "SECURITY HEALTH", color: securityHealthColor)
                DashboardStatPill(value: twoFactorReady ? "ACTIVE" : "OFF", label: "TWO-FACTOR", color: twoFactorReady ? Theme.gold : Theme.muted)
                DashboardStatPill(value: trustedDeviceActive ? "TRUSTED" : "STANDARD", label: "DEVICE STATE", color: trustedDeviceActive ? Theme.cyan : Theme.muted)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SECURITY HEALTH")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(securityHealthColor)
                    Spacer()
                    Text("\(securityHealthScore)/100 · \(securityHealthLabel)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(securityHealthColor)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surface)
                        Capsule()
                            .fill(securityHealthColor)
                            .frame(width: max(10, proxy.size.width * CGFloat(securityHealthScore) / 100.0))
                    }
                }
                .frame(height: 8)

                HStack(spacing: 10) {
                    Text(passwordProtectionEnabled ? "Password: ON" : "Password: OFF")
                    Text(twoFactorReady ? "2FA: ON" : "2FA: OFF")
                    Text(emergencyCodes.isEmpty ? "Emergency: MISSING" : "Emergency: READY")
                    Text(isLockedOut ? "Lockout: ACTIVE" : "Lockout: CLEAR")
                }
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.muted)

                HStack(spacing: 10) {
                    if lastUnlockEpoch > 0 {
                        let lastUnlock = Date(timeIntervalSince1970: lastUnlockEpoch)
                        let ago = Int(Date().timeIntervalSince(lastUnlock))
                        let agoStr = ago < 60 ? "\(ago)s ago" : ago < 3600 ? "\(ago/60)m ago" : "\(ago/3600)h ago"
                        Text("Last unlock: \(agoStr)")
                    } else {
                        Text("Last unlock: never")
                    }
                    if lastFailedEpoch > 0 {
                        let lastFailed = Date(timeIntervalSince1970: lastFailedEpoch)
                        let ago = Int(Date().timeIntervalSince(lastFailed))
                        let agoStr = ago < 60 ? "\(ago)s ago" : ago < 3600 ? "\(ago/60)m ago" : "\(ago/3600)h ago"
                        Text("Last fail: \(agoStr)").foregroundColor(Theme.red)
                    } else {
                        Text("Last fail: never")
                    }
                }
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.muted)
            }

            Toggle("Require password on app entry", isOn: Binding(
                get: { passwordEnabledRaw },
                set: { enabled in
                    if !enabled {
                        showDisablePasswordAlert = true
                    } else {
                        passwordEnabledRaw = true
                    }
                }
            ))
            .toggleStyle(.switch)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.text)

            if !passwordConfigured {
                SecureField("Create password", text: $newPasswordInput)
                    .textFieldStyle(.roundedBorder)
                SecureField("Confirm password", text: $confirmPasswordInput)
                    .textFieldStyle(.roundedBorder)
                if !newPasswordInput.isEmpty {
                    let strength = securityPasswordStrength(newPasswordInput)
                    HStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { i in
                            Capsule()
                                .fill(i < strength.score
                                    ? (strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                                    : Theme.surface)
                                .frame(height: 4)
                        }
                        Text(strength.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                    }
                }
                Button("SAVE PASSWORD", action: savePassword)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.gold)
                    .cornerRadius(6)
            } else {
                SecureField("Current password", text: $currentPasswordInput)
                    .textFieldStyle(.roundedBorder)
                SecureField("New password", text: $newPasswordInput)
                    .textFieldStyle(.roundedBorder)
                SecureField("Confirm new password", text: $confirmPasswordInput)
                    .textFieldStyle(.roundedBorder)
                if !newPasswordInput.isEmpty {
                    let strength = securityPasswordStrength(newPasswordInput)
                    HStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { i in
                            Capsule()
                                .fill(i < strength.score
                                    ? (strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                                    : Theme.surface)
                                .frame(height: 4)
                        }
                        Text(strength.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                    }
                }
                Button("UPDATE PASSWORD", action: updatePassword)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent)
                    .cornerRadius(6)
            }

            Divider().background(Theme.border)

            Toggle("Use \(biometricLabel) when available", isOn: Binding(
                get: { biometricEnabledRaw },
                set: { value in
                    biometricEnabledRaw = value
                    appendSecurityAudit(value ? "Enabled \(biometricLabel) unlock" : "Disabled \(biometricLabel) unlock")
                    postStatus(value ? "\(biometricLabel) unlock enabled." : "\(biometricLabel) unlock disabled.")
                }
            ))
            .toggleStyle(.switch)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.text)
            .disabled(!passwordProtectionEnabled || !biometricAvailable)

            if !biometricAvailable {
                Text("Biometric unlock is not available on this device.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            HStack {
                Toggle("Idle auto-lock", isOn: Binding(
                    get: { idleLockEnabledRaw },
                    set: { value in
                        idleLockEnabledRaw = value
                        appendSecurityAudit(value ? "Enabled idle auto-lock" : "Disabled idle auto-lock")
                        postStatus(value ? "Idle auto-lock enabled." : "Idle auto-lock disabled.")
                    }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.text)
                .disabled(!passwordProtectionEnabled)

                Spacer()

                Picker("Timeout", selection: $idleLockMinutesRaw) {
                    Text("1 min").tag(1)
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                }
                .pickerStyle(.menu)
                .frame(width: 110)
                .disabled(!idleLockEnabledRaw || !passwordProtectionEnabled)
            }

            HStack {
                Text("Trusted device")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.text)

                Spacer()

                Picker("Duration", selection: $trustedDeviceHoursRaw) {
                    Text("1 hr").tag(1)
                    Text("8 hr").tag(8)
                    Text("24 hr").tag(24)
                    Text("72 hr").tag(72)
                }
                .pickerStyle(.menu)
                .frame(width: 110)
                .disabled(!passwordProtectionEnabled)
            }

            HStack(spacing: 10) {
                Button(trustedDeviceActive ? "EXTEND TRUST" : "TRUST DEVICE") { trustCurrentDevice() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.cyan)
                    .disabled(!passwordProtectionEnabled)

                Button("LOCK NOW") { lockNow() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.red)
                    .disabled(!passwordProtectionEnabled)

                if trustedDeviceActive {
                    Button("REVOKE TRUST") { revokeTrustedDevice() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                }

                Spacer()
            }

            if trustedDeviceActive {
                Text("Trusted until \(trustedUntilLabel). Background/return unlock is skipped until expiry, unless the session is manually locked or auto-locked.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            Divider().background(Theme.border)

            VStack(alignment: .leading, spacing: 6) {
                Text("Authenticator Profile")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.cyan)
                TextField("Account label", text: $authAccountNameRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                TextField("Issuer", text: $authIssuerRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                Text("These labels are embedded into the QR and otpauth URI for authenticator app branding.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Out-of-Band Verification")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.gold)
                TextField("SMS number", text: $smsNumberRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                TextField("Email destination", text: $emailDestinationRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                Text("Use these destinations when the 2FA method is set to SMS OTP or Email OTP.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            HStack {
                Toggle("Enable 2FA", isOn: Binding(
                    get: { twoFactorEnabledRaw },
                    set: { setTwoFactor($0) }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.text)
                .disabled(!passwordProtectionEnabled)

                Spacer()

                Picker("Method", selection: Binding(
                    get: { twoFactorMethodRaw },
                    set: { value in
                        twoFactorMethodRaw = value
                        appendSecurityAudit("Set 2FA method to \(SecurityTwoFactorMethod(rawValue: value)?.display ?? value)")
                        postStatus("2FA method updated.")
                    }
                )) {
                    ForEach(SecurityTwoFactorMethod.allCases, id: \.rawValue) { method in
                        Text(method.display).tag(method.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 170)
            }

            if twoFactorReady {
                twoFactorSetupSection

                Text("TOTP codes refresh every 30 seconds. The setup URI is included so another device can provision the same authenticator profile if needed.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)

                if twoFactorMethod != .authenticator {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Button("SEND DEMO \(twoFactorMethod == .sms ? "SMS" : "EMAIL") CODE") { sendDemoTwoFactorCode() }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(twoFactorMethod == .sms ? Theme.cyan : Theme.gold)
                                .cornerRadius(6)
                                .disabled(outOfBandDestination.isEmpty)
                            if outOfBandCodeExpiresIn > 0 {
                                Text("Expires in \(outOfBandCodeExpiresIn)s")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                            if outOfBandLastSentAgo > 0 {
                                Text("Sent \(outOfBandLastSentAgo)s ago")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                        }
                        Text(twoFactorMethod == .sms
                             ? "SMS mode now uses a short-lived out-of-band code instead of the TOTP shown above."
                             : "Email mode now uses a short-lived out-of-band code instead of the TOTP shown above.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Theme.muted)
                        if outOfBandDestination.isEmpty {
                            Text(twoFactorMethod == .sms
                                 ? "Add a verified SMS destination before operators can request a code."
                                 : "Add a delivery email before operators can request a code.")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.red)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("REGEN EMERGENCY CODES") { regenerateEmergencyCodes() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.red)
                        .disabled(!twoFactorReady)
                    Button("COPY EMERGENCY CODES") { copyEmergencyCodePack() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.purple)
                        .disabled(!twoFactorReady)
                    Button("ROTATE 2FA SECRET") { showRotateConfirmation = true }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.red)
                        .disabled(!twoFactorReady)
                    Button("EXPORT RECOVERY KIT") { exportRecoveryKit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .disabled(!twoFactorReady)
                    Button("EXPORT AUDIT") { exportSecurityAudit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                }
            } else {
                HStack(spacing: 12) {
                    Button("EXPORT RECOVERY KIT") { exportRecoveryKit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .disabled(!twoFactorReady)
                    Button("EXPORT AUDIT") { exportSecurityAudit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.green)
            }

            if isLockedOut {
                Text("Unlocks resume in \(lockoutRemainingSeconds)s.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.red)
            } else if failedUnlockAttempts > 0 {
                Text("Failed unlock attempts: \(failedUnlockAttempts)/5")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.red)
            }

            if !auditEntries.isEmpty {
                Divider().background(Theme.border)
                Text("SECURITY AUDIT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.cyan)

                ForEach(Array(auditEntries.enumerated()), id: \.offset) { _, entry in
                    Text(entry)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Theme.surface.opacity(0.7))
                        .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.gold)
        .padding(.horizontal, 16)
        .onReceive(ticker) { now = $0 }
        .onAppear { refreshState() }
        .onChange(of: passwordEnabledRaw) { _, _ in refreshState() }
        .onChange(of: twoFactorEnabledRaw) { _, _ in refreshState() }
        .onChange(of: biometricEnabledRaw) { _, _ in refreshState() }
        .onChange(of: idleLockEnabledRaw) { _, _ in refreshState() }
        .onChange(of: idleLockMinutesRaw) { _, _ in refreshState() }
        .onChange(of: trustedUntilEpoch) { _, _ in refreshState() }
        .onChange(of: emergencyCodesRaw) { _, _ in refreshState() }
        .onChange(of: authAccountNameRaw) { _, _ in refreshState() }
        .onChange(of: authIssuerRaw) { _, _ in refreshState() }
        .alert("Rotate 2FA Secret?", isPresented: $showRotateConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Rotate", role: .destructive) { rotateTwoFactorSecret() }
        } message: {
            Text("This immediately invalidates existing authenticator enrollments and forces re-login.")
        }
        .alert("Disable Password Protection?", isPresented: $showDisablePasswordAlert) {
            SecureField("Current password", text: $reauthInput)
            Button("Cancel", role: .cancel) { reauthInput = "" }
            Button("Disable", role: .destructive) { confirmDisablePassword() }
        } message: {
            Text("Enter your current password to confirm. This will also disable 2FA, biometrics, and idle lock.")
        }
        .alert("Disable Two-Factor Authentication?", isPresented: $showDisable2FAAlert) {
            SecureField("Current password", text: $reauthInput)
            Button("Cancel", role: .cancel) { reauthInput = "" }
            Button("Disable", role: .destructive) { confirmDisable2FA() }
        } message: {
            Text("Enter your current password to confirm disabling 2FA.")
        }
    }
}

struct SecurityLockOverlay: View {
    let requiresTwoFactor: Bool
    let twoFactorMethodLabel: String
    let biometricEnabled: Bool
    let biometricLabel: String
    let lockoutUntilEpoch: Double
    @Binding var passwordInput: String
    @Binding var twoFactorInput: String
    let errorMessage: String?
    let onUnlock: () -> Void
    let onSendTwoFactorCode: () -> Void
    let verificationDestination: String
    let usingOutOfBandCode: Bool
    let onBiometricUnlock: () -> Void

    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isLockedOut: Bool {
        now.timeIntervalSince1970 < lockoutUntilEpoch
    }

    private var lockoutRemainingSeconds: Int {
        max(0, Int(ceil(lockoutUntilEpoch - now.timeIntervalSince1970)))
    }

    private var resendCooldownRemaining: Int {
        max(0, Int(ceil(20 - (Date().timeIntervalSince1970 - currentOutOfBandLastSentAt()))))
    }

    private var sendCodeButtonLabel: String {
        resendCooldownRemaining > 0 ? "WAIT \(resendCooldownRemaining)S" : "SEND CODE"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text("SECURE ACCESS")
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
                    .foregroundColor(Theme.gold)
                Text(lockPrompt)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Theme.muted)
                if requiresTwoFactor {
                    Text(usingOutOfBandCode
                         ? "Request a fresh \(twoFactorMethodLabel.lowercased()) challenge or use a one-time emergency unlock code."
                         : "You can use your current 2FA code or a one-time emergency unlock code.")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Theme.muted)
                }

                SecureField("Password", text: $passwordInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLockedOut)

                if requiresTwoFactor {
                    SecureField("\(twoFactorMethodLabel) or emergency code", text: $twoFactorInput)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLockedOut)

                    if usingOutOfBandCode {
                        HStack(spacing: 8) {
                            Button(sendCodeButtonLabel, action: onSendTwoFactorCode)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Theme.cyan)
                                .cornerRadius(6)
                                .disabled(isLockedOut || resendCooldownRemaining > 0 || verificationDestination.isEmpty)

                            Text(verificationDestination)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.muted)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }

                if biometricEnabled {
                    Button("UNLOCK WITH \(biometricLabel.uppercased())", action: onBiometricUnlock)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cyan.opacity(0.4), lineWidth: 1))
                        .cornerRadius(8)
                        .disabled(isLockedOut)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.red)
                }

                if isLockedOut {
                    Text("Retry available in \(lockoutRemainingSeconds)s")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.red)
                }

                Button("UNLOCK", action: onUnlock)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Theme.gold)
                    .cornerRadius(8)
                    .disabled(isLockedOut)
            }
            .padding(18)
            .background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.35), lineWidth: 1))
            .cornerRadius(12)
            .frame(maxWidth: 370)
            .padding(.horizontal, 20)
        }
        .onReceive(timer) { now = $0 }
    }

    private var lockPrompt: String {
        guard requiresTwoFactor else {
            return "Enter your security password to continue."
        }

        if usingOutOfBandCode {
            return "Enter your security password and the \(twoFactorMethodLabel.lowercased()) code sent to \(verificationDestination)."
        }

        return "Enter your security password and TOTP code to continue."
    }
}

// MARK: - Pricing Helpers

struct PricingBadge: View {
    let title: String; let description: String; let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(color)
                Text(description).font(.system(size: 10)).foregroundColor(Theme.muted)
            }
        }.padding(10).background(color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.2), lineWidth: 0.8)).cornerRadius(8)
    }
}

struct SectionHeading: View {
    let eyebrow: String; let title: String; let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow).font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            Text(title).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.text)
            Text(detail).font(.system(size: 11)).foregroundColor(Theme.muted)
        }
    }
}

struct FeatureCardSmall: View {
    let icon: String; let title: String; let desc: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(icon).font(.system(size: 20))
            Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(desc).font(.system(size: 10)).foregroundColor(Theme.muted).lineLimit(3)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 0.8)).cornerRadius(10)
    }
}
