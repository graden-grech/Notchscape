import Combine
import Foundation
import Network

enum AgentActivityState: String, Codable {
    case working
    case needsInput
    case completed
    case interrupted
    case usageLimited

    var label: String {
        switch self {
        case .working: "Working"
        case .needsInput: "Needs input"
        case .completed: "Completed"
        case .interrupted: "Interrupted"
        case .usageLimited: "Usage limit reached"
        }
    }

    var symbol: String {
        switch self {
        case .working: "sparkles"
        case .needsInput: "person.crop.circle.badge.questionmark"
        case .completed: "checkmark.circle.fill"
        case .interrupted: "pause.circle.fill"
        case .usageLimited: "exclamationmark.circle.fill"
        }
    }
}

struct AgentActivity: Identifiable, Codable, Equatable {
    let id: String
    var provider: String
    var title: String
    var detail: String
    var state: AgentActivityState
    var updatedAt: Date
}

@MainActor
final class AgentStatusManager: ObservableObject {
    static let shared = AgentStatusManager()
    static let port: UInt16 = 43_765

    @Published private(set) var activities: [AgentActivity] = []
    @Published private(set) var isListening = false
    @Published private(set) var lastError: String?

    private var listener: NWListener?
    private var dismissalTasks: [String: Task<Void, Never>] = [:]

    private init() {
        start()
    }

    func start() {
        guard listener == nil else { return }

        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: Self.port)!)
            listener.newConnectionHandler = { [weak self] connection in
                self?.receive(connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self else { return }
                    switch state {
                    case .ready:
                        self.isListening = true
                        self.lastError = nil
                    case .failed(let error):
                        self.isListening = false
                        self.lastError = error.localizedDescription
                        self.listener = nil
                    case .cancelled:
                        self.isListening = false
                        self.listener = nil
                    default:
                        break
                    }
                }
            }
            self.listener = listener
            listener.start(queue: .global(qos: .utility))
        } catch {
            lastError = error.localizedDescription
        }
    }

    private nonisolated func receive(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        collect(on: connection, data: Data())
    }

    private nonisolated func collect(on connection: NWConnection, data: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] chunk, _, complete, error in
            var accumulated = data
            if let chunk { accumulated.append(chunk) }

            if complete || error != nil || accumulated.containsHTTPBody {
                let body = accumulated.httpBody
                if !body.isEmpty {
                    let provider = accumulated.httpRequestPath.contains("claude")
                        ? "Claude Code"
                        : "Codex"
                    Task { @MainActor in self?.ingest(body, provider: provider) }
                }
                let response = "HTTP/1.1 204 No Content\r\nConnection: close\r\nContent-Length: 0\r\n\r\n"
                connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                    connection.cancel()
                })
                return
            }

            self?.collect(on: connection, data: accumulated)
        }
    }

    private func ingest(_ data: Data, provider: String) {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let event = object["hook_event_name"] as? String
        else { return }

        let resolvedProvider = (object["provider"] as? String) ?? provider

        let sessionID = (object["session_id"] as? String) ?? UUID().uuidString
        let cwd = object["cwd"] as? String
        let project = cwd.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Codex task"
        let tool = object["tool_name"] as? String

        let searchablePayload = Self.flattenedStrings(in: object).joined(separator: " ").lowercased()
        let hitUsageLimit = Self.indicatesUsageLimitReached(
            event: event,
            payload: searchablePayload
        )

        let state: AgentActivityState
        if hitUsageLimit {
            state = .usageLimited
        } else {
            switch event {
            case "PermissionRequest": state = .needsInput
            case "Stop", "SessionEnd": state = .completed
            case "Interrupt": state = .interrupted
            default: state = .working
            }
        }

        let detail: String
        switch state {
        case .usageLimited: detail = "Usage limit reached"
        default: switch event {
        case "PermissionRequest": detail = "Waiting for approval"
        case "Stop": detail = "Turn finished"
        case "SessionEnd": detail = "Session finished"
        case "Interrupt": detail = "Turn interrupted"
        case "PreToolUse": detail = tool.map { "Using \($0)" } ?? "Using a tool"
        case "PostToolUse": detail = tool.map { "Finished \($0)" } ?? "Tool finished"
        case "SubagentStart": detail = "Subagent started"
        case "SubagentStop": detail = "Subagent finished"
        case "UserPromptSubmit": detail = "Thinking"
        default: detail = "Active"
        }
        }

        let activity = AgentActivity(
            id: "\(resolvedProvider):\(sessionID)",
            provider: resolvedProvider,
            title: project,
            detail: detail,
            state: state,
            updatedAt: .now
        )

        dismissalTasks[activity.id]?.cancel()
        activities.removeAll { $0.id == activity.id }
        activities.insert(activity, at: 0)
        activities = Array(activities.prefix(6))

        if state == .completed || state == .interrupted || state == .usageLimited {
            dismissalTasks[activity.id] = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(state == .usageLimited ? 3 : 4))
                guard !Task.isCancelled else { return }
                self?.activities.removeAll { $0.id == activity.id }
                self?.dismissalTasks[activity.id] = nil
            }
        } else if state == .working {
            // If an agent exits without a final hook (for example after a network
            // or quota failure), do not leave a permanent "working" activity.
            dismissalTasks[activity.id] = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(120))
                guard !Task.isCancelled else { return }
                self?.activities.removeAll { $0.id == activity.id }
                self?.dismissalTasks[activity.id] = nil
            }
        }

        let cutoff = Date().addingTimeInterval(-300)
        activities.removeAll { $0.state == .completed && $0.updatedAt < cutoff }
    }

    private static func flattenedStrings(in value: Any) -> [String] {
        switch value {
        case let string as String:
            return [string]
        case let dictionary as [String: Any]:
            return dictionary.flatMap { flattenedStrings(in: $0.value) }
        case let array as [Any]:
            return array.flatMap(flattenedStrings(in:))
        default:
            return []
        }
    }

    /// Low-usage notices such as "15% remaining" are advisory and must not
    /// replace an active task with the brief red limit-reached activity.
    private static func indicatesUsageLimitReached(event: String, payload: String) -> Bool {
        let normalizedEvent = event.lowercased()
        if normalizedEvent == "usagelimit" || normalizedEvent == "ratelimit" {
            return true
        }

        if containsNonzeroRemainingUsage(in: payload) {
            return false
        }

        let exhaustedPhrases = [
            "usage limit reached", "rate limit reached", "limit reached",
            "reached your usage limit", "reached your rate limit",
            "rate_limit_exceeded", "rate_limit_error", "quota exceeded",
            "too many requests", "limit has been reached", "limit was reached",
            "you've hit your", "you have hit your", "you hit your",
            "out of tokens", "tokens exhausted", "token budget exhausted",
            "usage has been exhausted", "no usage remaining", "no tokens remaining",
            "0% left", "0% remaining", "try again later"
        ]
        return exhaustedPhrases.contains { payload.contains($0) }
    }

    private static func containsNonzeroRemainingUsage(in payload: String) -> Bool {
        let pattern = #"\b(?:[1-9]|[1-9][0-9]|100)\s*%[^.\n]{0,100}\b(?:left|remaining)\b"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(payload.startIndex..., in: payload)
        return expression.firstMatch(in: payload, range: range) != nil
    }
}

private extension Data {
    var httpRequestPath: String {
        guard
            let request = String(data: self, encoding: .utf8),
            let firstLine = request.split(separator: "\n", maxSplits: 1).first
        else { return "/codex" }

        let parts = firstLine.split(separator: " ")
        return parts.count > 1 ? String(parts[1]) : "/codex"
    }

    var httpBody: Data {
        guard let range = range(of: Data("\r\n\r\n".utf8)) else { return self }
        return subdata(in: range.upperBound..<endIndex)
    }

    var containsHTTPBody: Bool {
        guard
            let headerRange = range(of: Data("\r\n\r\n".utf8)),
            let headers = String(data: self[..<headerRange.lowerBound], encoding: .utf8)
        else { return false }

        let contentLength = headers
            .split(separator: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }
            .flatMap { Int($0.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? "") }
            ?? 0
        return count - headerRange.upperBound >= contentLength
    }
}
