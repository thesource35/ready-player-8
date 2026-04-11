import Foundation
import SwiftUI

// MARK: - ========== AngelicAIView.swift ==========

//
// Uses the Anthropic Messages API (claude-haiku-4-5-20251001) with MCP tools.
// API key is stored securely in Keychain.
// Conversation history is stored in Supabase (cs_ai_messages) when configured,
// falling back to in-memory only.


// MARK: - Message model

struct AIMessage: Identifiable, Codable, Equatable {
    var id: UUID
    let role: AIRole
    let content: String
    let timestamp: Date

    enum AIRole: String, Codable { case user, assistant }

    init(role: AIRole, content: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    var timestampLabel: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: timestamp)
    }

    static func == (lhs: AIMessage, rhs: AIMessage) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content
    }
}

// MARK: - View

struct AngelicAIView: View {
    @State private var apiKey: String = KeychainHelper.read(key: "AngelicAI.APIKey") ?? ""
    @AppStorage("ConstructOS.AngelicAI.SessionID") private var sessionID: String = UUID().uuidString

    @State private var messages: [AIMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var isUsingFallback = false
    @State private var errorMessage: String?
    @State private var lastFailedMessage: String?
    @State private var showKeySetup = false
    @State private var tempAPIKey = ""
    @State private var scrollID: UUID?

    private let supabase = SupabaseService.shared
    private let systemPrompt = """
    You are Angelic — an expert AI assistant for ConstructionOS, a unified construction operating system. \
    You have deep knowledge of construction project management, contract bidding, site safety, crew logistics, \
    RFI workflows, change orders, scheduling, budget management, and subcontractor coordination. \
    You provide clear, direct, actionable answers. Use construction industry terminology naturally. \
    When asked about specific projects, crews, or sites, acknowledge you can reference live data from \
    the platform modules. Keep responses concise and field-ready.
    """

    private let starterPrompts = [
        "Draft an RFI for a concrete delay on Site Alpha",
        "What's the standard retainage release process?",
        "Summarize best practices for daily crew standups",
        "How should I handle a subcontractor safety incident?",
        "What should be included in a change order package?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            angelicHeader
            Divider().overlay(Theme.border)
            if apiKey.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "key.slash")
                        .font(.system(size: 10))
                    Text("DEMO MODE — Configure API key in settings")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(Theme.gold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(6)
                apiKeySetupView
            } else {
                if isUsingFallback {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 10))
                        Text("OFFLINE MODE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(Theme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.surface.opacity(0.6))
                    .cornerRadius(6)
                }
                chatArea
                inputBar
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showKeySetup) {
            APIKeySheet(tempKey: $tempAPIKey) { key in
                apiKey = key
                KeychainHelper.save(key: "AngelicAI.APIKey", data: key)
                showKeySetup = false
            }
        }
        .task {
            // Migrate legacy UserDefaults API key to Keychain
            if apiKey.isEmpty {
                if let legacyKey = UserDefaults.standard.string(forKey: "ConstructOS.AngelicAI.APIKey"), !legacyKey.isEmpty {
                    apiKey = legacyKey
                    KeychainHelper.save(key: "AngelicAI.APIKey", data: legacyKey)
                    UserDefaults.standard.removeObject(forKey: "ConstructOS.AngelicAI.APIKey")
                }
            }
            // Load local messages first, then try remote
            let localKey = "ConstructOS.AngelicAI.Messages.\(sessionID)"
            let localMessages: [AIMessage] = loadJSON(localKey, default: [])
            if !localMessages.isEmpty {
                messages = localMessages
            }
            if !apiKey.isEmpty { await loadHistory() }
        }
        .onChange(of: messages) { _, newValue in
            let localKey = "ConstructOS.AngelicAI.Messages.\(sessionID)"
            saveJSON(localKey, value: newValue)
        }
    }

    // MARK: - Header

    private var angelicHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("✦")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.purple)
                    Text("ANGELIC AI")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(4)
                        .foregroundColor(Theme.purple)
                }
                Text("Construction Intelligence")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Theme.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if !apiKey.isEmpty {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.green).frame(width: 6, height: 6)
                        Text("claude-haiku-4-5")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.muted)
                    }
                }
                HStack(spacing: 8) {
                    Button { showKeySetup = true } label: {
                        Image(systemName: "key")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                    }
                    .accessibilityLabel("API key settings")
                    Button {
                        messages = []
                        sessionID = UUID().uuidString
                        errorMessage = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                    }
                    .accessibilityLabel("Clear chat history")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface)
    }

    // MARK: - API Key Setup

    private var apiKeySetupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                VStack(spacing: 12) {
                    Text("✦")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.purple.opacity(0.7))
                    Text("Angelic AI")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(Theme.text)
                    Text("Your construction intelligence assistant. Connect your Anthropic API key to activate Angelic.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    SecureField("sk-ant-...", text: $tempAPIKey)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .accentColor(Theme.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.surface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 1))
                        .padding(.horizontal, 20)

                    Button {
                        if !tempAPIKey.isEmpty {
                            apiKey = tempAPIKey
                            KeychainHelper.save(key: "AngelicAI.APIKey", data: tempAPIKey)
                            tempAPIKey = ""
                        }
                    } label: {
                        Text("Activate Angelic")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(tempAPIKey.isEmpty ? Theme.muted : Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(tempAPIKey.isEmpty ? Theme.surface : Theme.purple)
                            .cornerRadius(10)
                    }
                    .disabled(tempAPIKey.isEmpty)
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("SAMPLE CAPABILITIES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.muted)
                        .padding(.horizontal, 20)
                    ForEach(starterPrompts, id: \.self) { prompt in
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle").font(.system(size: 10)).foregroundColor(Theme.purple)
                            Text(prompt).font(.system(size: 12)).foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Chat

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        starterPromptsView
                    } else {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isThinking {
                            ThinkingBubble()
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: isThinking) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    private var starterPromptsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 30)
            Text("✦ How can I help?")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("Tap a prompt or type your question below")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
            VStack(spacing: 8) {
                ForEach(starterPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        Task { await sendMessage() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.purple)
                            Text(prompt)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.surface)
                        .cornerRadius(10)
                        .premiumGlow(cornerRadius: 10, color: Theme.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            Spacer(minLength: 30)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Theme.border)
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            HStack(spacing: 10) {
                TextField("Ask Angelic...", text: $inputText, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.purple)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
                    .onSubmit { if !inputText.isEmpty && !isThinking { Task { await sendMessage() } } }

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: isThinking ? "ellipsis" : "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.bg)
                        .frame(width: 36, height: 36)
                        .background(inputText.isEmpty || isThinking ? Theme.muted.opacity(0.4) : Theme.purple)
                        .clipShape(Circle())
                }
                .accessibilityLabel(isThinking ? "Thinking" : "Send message")
                .disabled(inputText.isEmpty || isThinking)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bg)
        }
    }

    // MARK: - Send message

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        errorMessage = nil

        let userMsg = AIMessage(role: .user, content: text, timestamp: Date())
        messages.append(userMsg)
        isThinking = true

        await persistMessage(userMsg)

        // Retry with exponential backoff (max 2 retries)
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                if attempt > 0 { try await Task.sleep(for: .seconds(Double(attempt) * 2)) }
                let response = try await callClaude(userMessage: text)
                let aiMsg = AIMessage(role: .assistant, content: response, timestamp: Date())
                messages.append(aiMsg)
                await persistMessage(aiMsg)
                lastError = nil
                break
            } catch {
                lastError = error
            }
        }
        if let lastError {
            errorMessage = "\(lastError.localizedDescription). Tap to retry."
            lastFailedMessage = text
        }
        isThinking = false
    }

    // MARK: - Claude API with MCP Tool Use

    private let mcpServer = MCPToolServer.shared

    /// Anthropic API endpoint — configurable via UserDefaults for testing/proxy
    private var anthropicEndpoint: String {
        UserDefaults.standard.string(forKey: "ConstructOS.AngelicAI.Endpoint") ?? "https://api.anthropic.com/v1/messages"
    }

    private func callClaude(userMessage: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AngelicError.noAPIKey }
        guard let url = URL(string: anthropicEndpoint) else {
            throw AngelicError.invalidURL
        }

        let history: [[String: Any]] = messages.dropLast().map {
            ["role": $0.role == .user ? "user" : "assistant", "content": $0.content]
        }
        var messageList = history
        messageList.append(["role": "user", "content": userMessage])

        // Include MCP tools in the request
        var payload: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 2048,
            "system": systemPrompt + "\n\nYou have access to live ConstructionOS data through tools. Use them to answer questions about projects, sites, crews, equipment, budgets, and more. Always check live data before answering factual questions.\n\nYou can also generate draft RFI documents (generate_rfi), draft change orders (draft_change_order), and analyze bid competitiveness (analyze_bid). When generating documents, present the draft and ask the user to confirm.",
            "messages": messageList,
            "tools": mcpServer.toolDefinitions
        ]

        var finalText = ""
        var maxToolRounds = 5  // prevent infinite loops

        while maxToolRounds > 0 {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let body = String(data: data, encoding: .utf8) ?? "No body"
                if http.statusCode == 401 { throw AngelicError.invalidAPIKey }
                throw AngelicError.apiError(http.statusCode, body)
            }

            let jsonObject: Any
            do {
                jsonObject = try JSONSerialization.jsonObject(with: data)
            } catch {
                CrashReporter.shared.reportError("[AngelicAI] API response parse failed: \(error.localizedDescription)")
                isUsingFallback = true
                throw AngelicError.parseError
            }
            guard let json = jsonObject as? [String: Any],
                  let contentBlocks = json["content"] as? [[String: Any]],
                  let stopReason = json["stop_reason"] as? String
            else {
                throw AngelicError.parseError
            }
            isUsingFallback = false

            // Check if Claude wants to use tools
            if stopReason == "tool_use" {
                // Build tool results
                var toolResults: [[String: Any]] = []
                var assistantContent: [[String: Any]] = []

                for block in contentBlocks {
                    let blockType = block["type"] as? String ?? ""
                    if blockType == "text", let text = block["text"] as? String {
                        assistantContent.append(["type": "text", "text": text])
                        finalText += text
                    } else if blockType == "tool_use" {
                        let toolName = block["name"] as? String ?? ""
                        let toolID = block["id"] as? String ?? ""
                        let toolInput = block["input"] as? [String: Any] ?? [:]

                        assistantContent.append(block)

                        // Execute the tool via MCP server
                        let result = await mcpServer.executeTool(name: toolName, input: toolInput)

                        toolResults.append([
                            "type": "tool_result",
                            "tool_use_id": toolID,
                            "content": result
                        ])
                    }
                }

                // Add assistant message with tool use + tool results for next round
                messageList.append(["role": "assistant", "content": assistantContent])
                messageList.append(["role": "user", "content": toolResults])
                payload["messages"] = messageList
                maxToolRounds -= 1
                continue

            } else {
                // stop_reason == "end_turn" — collect text
                for block in contentBlocks {
                    if let text = block["text"] as? String {
                        finalText += text
                    }
                }
                break
            }
        }

        if finalText.isEmpty { throw AngelicError.parseError }
        return finalText
    }

    // MARK: - Persistence

    private func loadHistory() async {
        guard supabase.isConfigured else { return }
        do {
            let stored: [SupabaseAIMessage] = try await supabase.fetch(
                SupabaseTable.aiMessages,
                query: ["session_id": "eq.\(sessionID)", "order": "created_at.asc"]
            )
            messages = stored.map {
                AIMessage(
                    role: $0.role == "user" ? .user : .assistant,
                    content: $0.content,
                    timestamp: Date()
                )
            }
        } catch {
            // History load failures are non-critical — continue with empty chat
            CrashReporter.shared.reportError("[AngelicAI] History load error: \(error.localizedDescription)")
        }
    }

    private func persistMessage(_ message: AIMessage) async {
        guard supabase.isConfigured else { return }
        let record = SupabaseAIMessage(
            id: nil,
            sessionId: sessionID,
            role: message.role == .user ? "user" : "assistant",
            content: message.content,
            createdAt: nil
        )
        do { try await supabase.insert(SupabaseTable.aiMessages, record: record) }
        catch { CrashReporter.shared.reportError("[AngelicAI] Persist error: \(error.localizedDescription)") }
    }
}

// MARK: - Errors

private enum AngelicError: LocalizedError {
    case noAPIKey, invalidURL, invalidAPIKey, parseError
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key set. Tap the key icon to configure."
        case .invalidURL: return "Invalid API endpoint URL."
        case .invalidAPIKey: return "Invalid API key. Tap the key icon to update it."
        case .parseError: return "Could not parse the AI response."
        case .apiError(let code, let body): return "API error \(code): \(body)"
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                Text("✦")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.purple)
                    .padding(.bottom, 4)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 3) {
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(message.role == .user ? Theme.bg : Theme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Theme.accent : Theme.surface)
                    .cornerRadius(16)

                Text(message.timestampLabel)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.muted.opacity(0.7))
            }

            if message.role == .user {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
                    .padding(6)
                    .background(Theme.surface)
                    .clipShape(Circle())
                    .padding(.bottom, 4)
            } else {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Thinking Bubble

private struct ThinkingBubble: View {
    @State private var dot1 = false
    @State private var dot2 = false
    @State private var dot3 = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text("✦").font(.system(size: 14)).foregroundColor(Theme.purple).padding(.bottom, 4)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.muted.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(i == 0 ? (dot1 ? 1.4 : 0.8) : i == 1 ? (dot2 ? 1.4 : 0.8) : (dot3 ? 1.4 : 0.8))
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: dot1)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Theme.surface)
            .cornerRadius(16)
            Spacer(minLength: 40)
        }
        .onAppear {
            dot1 = true; dot2 = true; dot3 = true
        }
    }
}

// MARK: - API Key Sheet

private struct APIKeySheet: View {
    @Binding var tempKey: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your API key is stored securely in the device Keychain. It is never sent anywhere except directly to api.anthropic.com.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                        .padding(14)
                        .background(Theme.surface)
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ANTHROPIC API KEY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Theme.muted)
                        SecureField("sk-ant-...", text: $tempKey)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Theme.text)
                            .accentColor(Theme.purple)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(Theme.surface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Angelic AI Key")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if !tempKey.isEmpty { onSave(tempKey) } }
                        .foregroundColor(Theme.purple).fontWeight(.bold)
                        .disabled(tempKey.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
