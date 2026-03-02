//
//  GeminiService.swift
//  aWordaDay
//
//  REST client for Google Gemini API.
//

import Foundation
import Network

enum GeminiError: LocalizedError {
    case apiError(String)
    case networkError(Error)
    case noResponse
    case missingAPIKey
    case offline

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        case .networkError(let error): return error.localizedDescription
        case .noResponse: return "No response from Gemini."
        case .missingAPIKey:
            return "Missing Gemini API key. Provide GEMINI_API_KEY via build settings or environment, not a committed secret."
        case .offline:
            return "You're offline. Please check your internet connection."
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String {
        case user
        case assistant = "model"
    }
}

final class GeminiService {
    private let apiKey: String?
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent"

    private var lastRequestTime: Date?
    private var sessionRequestCount: Int = 0
    private static let minimumRequestInterval: TimeInterval = 1.5
    private static let maxSessionRequests: Int = 60

    private let networkMonitor = NWPathMonitor()
    private(set) var isConnected: Bool = true

    init() {
        let environmentKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
        self.apiKey = Self.sanitizedKey(environmentKey) ?? Self.sanitizedKey(plistKey)
        startMonitoring()
    }

    deinit {
        networkMonitor.cancel()
    }

    private func startMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    private static func sanitizedKey(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }

        let candidate = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = candidate.uppercased()

        if candidate.isEmpty { return nil }
        if candidate.contains("$(") { return nil }
        if upper.contains("PLACEHOLDER") { return nil }
        if upper == "YOUR_GEMINI_API_KEY" { return nil }

        return candidate
    }

    private func checkRateLimit() throws {
        if sessionRequestCount >= Self.maxSessionRequests {
            throw GeminiError.apiError("Session request limit reached. Please restart the app.")
        }
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < Self.minimumRequestInterval {
                // We'll still allow it but track it
            }
        }
    }

    func resetSessionCount() {
        sessionRequestCount = 0
    }

    func send(messages: [ChatMessage], systemPrompt: String, maxOutputTokens: Int = 320) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        guard isConnected else {
            throw GeminiError.offline
        }
        try checkRateLimit()
        sessionRequestCount += 1
        lastRequestTime = Date()
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw GeminiError.apiError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let contents: [[String: Any]] = messages.map { message in
            [
                "role": message.role.rawValue,
                "parts": [["text": message.content]]
            ]
        }

        let body: [String: Any] = [
            "contents": contents,
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": 0.5,
                "maxOutputTokens": maxOutputTokens
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.noResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
