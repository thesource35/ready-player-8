import Foundation
import PhotosUI
import SwiftUI
import Combine
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


// MARK: - ========== SocialNetworkView.swift ==========


// MARK: - Network View

struct NetworkView: View {
    private let voipContacts: [Contact] = [
        Contact(name: "Avery Stone", title: "Site Superintendent", company: "NorthGrid Build", score: 92, connections: 81, projects: 14, initials: "AS"),
        Contact(name: "Jules Rivera", title: "PM", company: "Peakline", score: 88, connections: 63, projects: 9, initials: "JR"),
        Contact(name: "Mina Park", title: "Field Engineer", company: "BuildAxis", score: 85, connections: 57, projects: 11, initials: "MP"),
        Contact(name: "Theo Grant", title: "Owner Rep", company: "UrbanCore", score: 83, connections: 49, projects: 8, initials: "TG")
    ]

    @State private var selectedContactID: UUID?
    @State private var inCall = false
    @State private var groupMode = true
    @State private var activeStream = true
    @State private var multitaskMode = true
    @State private var audioEnabled = true
    @State private var videoEnabled = true
    @State private var speakerEnabled = true
    @State private var e2eeEnabled = true
    @State private var ephemeralMode = true
    @State private var ephemeralTTL = 15
    @State private var callStatus = "Ready"
    @State private var messageInput = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingPhotoData: Data?
    @State private var keyEpoch = 1
    @State private var apksEnabled = true
    @State private var apksAutoRotate = true
    @State private var apksPriority = 2
    @State private var photoMessagingTodoDone = true
    @State private var callEvents: [String] = []
    @State private var directMessages: [ChatMessage] = [
        ChatMessage(
            role: .ai,
            text: "Encrypted room initialized. Ephemeral mode active.",
            timestamp: Date().addingTimeInterval(-90),
            deliveryState: .read
        ),
        ChatMessage(
            role: .user,
            text: "Crew standup in 5. Bring Site Gamma into room.",
            timestamp: Date().addingTimeInterval(-45),
            deliveryState: .read
        )
    ]

    @State private var messageTicker = Date()
    private let messageTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var expiredEphemeralCount: Int {
        directMessages.filter { $0.deliveryState == .expired }.count
    }

    private var selectedContact: Contact {
        voipContacts.first { $0.id == selectedContactID } ?? voipContacts[0]
    }

    private var canSendMessage: Bool {
        !messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingPhotoData != nil
    }

    private func pushEvent(_ text: String) {
        callEvents.insert(text, at: 0)
        callEvents = Array(callEvents.prefix(8))
    }

    private func startCall() {
        inCall = true
        callStatus = groupMode ? "Group video live" : "Direct call live"
        if e2eeEnabled {
            keyEpoch += 1
            pushEvent("E2EE key epoch rotated to #\(keyEpoch)")
        }
        pushEvent("Call started with \(selectedContact.name)")
    }

    private func endCall() {
        inCall = false
        callStatus = "Call ended"
        pushEvent("Call ended")
    }

    private func sendMessage() {
        let trimmed = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || pendingPhotoData != nil else { return }
        let sentAt = Date()
        let expiry = ephemeralMode ? sentAt.addingTimeInterval(TimeInterval(ephemeralTTL)) : nil
        let outgoingPhoto = pendingPhotoData
        directMessages.append(ChatMessage(
            role: .user,
            text: trimmed.isEmpty ? "Photo attachment" : trimmed,
            timestamp: sentAt,
            deliveryState: .sending,
            expiresAt: expiry,
            encrypted: e2eeEnabled,
            photoData: outgoingPhoto
        ))
        if outgoingPhoto != nil {
            pushEvent("Photo message queued\(ephemeralMode ? " (TTL: \(ephemeralTTL)s)" : "")")
        } else if ephemeralMode {
            pushEvent("Ephemeral message queued (TTL: \(ephemeralTTL)s)")
        }
        refreshMessageStates(now: sentAt)
        messageInput = ""
        pendingPhotoData = nil
        selectedPhotoItem = nil
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            pendingPhotoData = nil
            return
        }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await MainActor.run {
                pendingPhotoData = data
                photoMessagingTodoDone = true
                pushEvent("Photo attached to draft")
            }
        }
    }

    private func chatImage(from data: Data) -> Image? {
#if os(iOS)
        guard let image = UIImage(data: data) else { return nil }
        return Image(uiImage: image)
#elseif os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        return Image(nsImage: image)
#else
        return nil
#endif
    }

    private func runAction(_ label: String) {
        switch label {
        case "MUTE CREW":
            audioEnabled = false
        case "PIN FOREMAN":
            activeStream = true
        case "LOCK ROOM":
            e2eeEnabled = true
            keyEpoch += 1
        case "ROTATE KEYS":
            keyEpoch += 1
        default:
            break
        }
        pushEvent("Action: \(label)")
    }

    private func refreshMessageStates(now: Date = Date()) {
        directMessages = directMessages.map { message in
            var updated = message

            if let expiresAt = updated.expiresAt, now >= expiresAt {
                updated.deliveryState = .expired
                return updated
            }

            guard updated.role == .user else { return updated }

            let age = now.timeIntervalSince(updated.timestamp)
            if age >= 4 {
                updated.deliveryState = .read
            } else if age >= 1.5 {
                updated.deliveryState = .delivered
            }

            return updated
        }
    }

    private func purgeExpiredMessages() {
        let expiredCount = expiredEphemeralCount
        guard expiredCount > 0 else { return }
        directMessages.removeAll { $0.deliveryState == .expired }
        pushEvent("Cleared \(expiredCount) expired message\(expiredCount == 1 ? "" : "s")")
    }

    private func messageMetaText(for message: ChatMessage) -> String {
        var components = [message.timestampLabel, message.deliveryState.rawValue]

        if message.encrypted {
            components.append("E2EE")
        }

        if let expiresAt = message.expiresAt {
            let remaining = max(0, Int(ceil(expiresAt.timeIntervalSince(messageTicker))))
            components.append(message.deliveryState == .expired ? "Expired" : "TTL \(remaining)s")
        }

        return components.joined(separator: " · ")
    }

    private var photoMessagingTodoPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TO-DO LIST")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.gold)
            HStack(spacing: 8) {
                Image(systemName: photoMessagingTodoDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(photoMessagingTodoDone ? Theme.green : Theme.muted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable picture messaging in room chat")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(photoMessagingTodoDone ? "Completed" : "Pending")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(photoMessagingTodoDone ? Theme.green : Theme.muted)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(Theme.surface.opacity(0.75))
        .cornerRadius(8)
    }

    private func directMessageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .ai { Spacer(minLength: 0) }
            VStack(alignment: .leading, spacing: 4) {
                if let photoData = message.photoData, let image = chatImage(from: photoData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 120)
                        .clipped()
                        .cornerRadius(6)
                }
                Text(message.text)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text(messageMetaText(for: message))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(message.deliveryState == .expired ? Theme.red : Theme.muted)
            }
            .padding(8)
            .background(message.role == .user ? Theme.panel : Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(message.deliveryState == .expired ? Theme.red.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(8)
            if message.role == .user { Spacer(minLength: 0) }
        }
    }

    private var directMessagePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("IN-CALL DIRECT MESSAGES")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Theme.cyan)
                Spacer()
                if ephemeralMode {
                    Text("AUTO-EXPIRE \(ephemeralTTL)S")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.gold)
                        .cornerRadius(4)
                }
                if expiredEphemeralCount > 0 {
                    Button("CLEAR EXPIRED", action: purgeExpiredMessages)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.red)
                        .buttonStyle(.plain)
                }
            }

            ForEach(directMessages) { message in
                directMessageBubble(message)
            }

            if let previewData = pendingPhotoData, let image = chatImage(from: previewData) {
                HStack(spacing: 8) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 50)
                        .clipped()
                        .cornerRadius(6)
                    Text("Photo attached")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Button("REMOVE") {
                        pendingPhotoData = nil
                        selectedPhotoItem = nil
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.red)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 2)
            }

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.gold)
                        .cornerRadius(6)
                }

                TextField("Message room", text: $messageInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.surface)
                    .cornerRadius(6)

                Button("SEND", action: sendMessage)
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(canSendMessage ? Theme.accent : Theme.muted)
                    .cornerRadius(6)
            }
            .disabled(!canSendMessage)
        }
        .padding(10)
        .background(Theme.surface.opacity(0.75))
        .cornerRadius(8)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("VOIP COMMAND")
                        .font(.system(size: 12, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.cyan)
                    Spacer()
                    Text(callStatus.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(inCall ? Theme.green.opacity(0.25) : Theme.surface)
                        .cornerRadius(6)
                        .foregroundColor(inCall ? Theme.green : Theme.muted)
                }

                HStack(spacing: 8) {
                    Toggle("GROUP VIDEO", isOn: $groupMode)
                        .toggleStyle(.button)
                    Toggle("ACTIVE STREAM", isOn: $activeStream)
                        .toggleStyle(.button)
                    Toggle("MULTITASK", isOn: $multitaskMode)
                        .toggleStyle(.button)
                }
                .font(.system(size: 8, weight: .bold))

                HStack(spacing: 8) {
                    Toggle("AUDIO", isOn: $audioEnabled)
                        .toggleStyle(.button)
                    Toggle("VIDEO", isOn: $videoEnabled)
                        .toggleStyle(.button)
                    Toggle("SPEAKER", isOn: $speakerEnabled)
                        .toggleStyle(.button)
                }
                .font(.system(size: 8, weight: .bold))

                HStack(spacing: 8) {
                    Toggle("E2EE", isOn: $e2eeEnabled)
                        .toggleStyle(.button)
                    Toggle("EPHEMERAL", isOn: $ephemeralMode)
                        .toggleStyle(.button)
                    if ephemeralMode {
                        Stepper("TTL \(ephemeralTTL)s", value: $ephemeralTTL, in: 5...120, step: 5)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("APKS")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundColor(Theme.gold)
                    HStack(spacing: 8) {
                        Toggle("ENABLE", isOn: $apksEnabled)
                            .toggleStyle(.button)
                        Toggle("AUTO-ROTATE", isOn: $apksAutoRotate)
                            .toggleStyle(.button)
                        Stepper("PRIORITY \(apksPriority)", value: $apksPriority, in: 1...5)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.muted)
                    }
                    .font(.system(size: 8, weight: .bold))
                }
                .padding(10)
                .background(Theme.surface.opacity(0.75))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("ROOM")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Theme.accent)
                    ForEach(voipContacts) { contact in
                        Button {
                            selectedContactID = contact.id
                        } label: {
                            HStack {
                                Text(contact.initials)
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.black)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.gold)
                                    .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.text)
                                    Text(contact.title)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(Theme.muted)
                                }
                                Spacer()
                                if selectedContactID == contact.id {
                                    Text("SELECTED")
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(Theme.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Theme.surface.opacity(0.75))
                .cornerRadius(8)

                HStack(spacing: 8) {
                    Button(inCall ? "END CALL" : "START CALL") {
                        inCall ? endCall() : startCall()
                    }
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(inCall ? Theme.red : Theme.green)
                    .cornerRadius(8)

                    Button("ROTATE E2EE") { runAction("ROTATE KEYS") }
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Theme.gold)
                        .cornerRadius(8)
                }

                HStack(spacing: 8) {
                    ForEach(["MUTE CREW", "PIN FOREMAN", "LOCK ROOM"], id: \.self) { action in
                        Button(action) { runAction(action) }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.panel)
                            .cornerRadius(6)
                    }
                }

                photoMessagingTodoPanel

                directMessagePanel

                VStack(alignment: .leading, spacing: 4) {
                    Text("EVENT LOG")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(Theme.gold)
                    Text("E2EE: \(e2eeEnabled ? "ON" : "OFF") · Key Epoch: #\(keyEpoch) · Ephemeral: \(ephemeralMode ? "ON" : "OFF")")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    ForEach(callEvents, id: \.self) { event in
                        Text("• \(event)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                }
                .padding(10)
                .background(Theme.surface.opacity(0.75))
                .cornerRadius(8)
            }
            .padding(14)
        }
        .background(Theme.bg)
        .onReceive(messageTimer) { now in
            messageTicker = now
            refreshMessageStates(now: now)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            loadSelectedPhoto(newValue)
        }
    }
}
