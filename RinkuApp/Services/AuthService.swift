import Foundation
import SwiftUI

/// User session data
struct UserSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

/// Authenticated user
struct AuthUser: Codable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "user_metadata"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        
        // Extract full_name from user_metadata
        if let metadata = try? container.decodeIfPresent([String: String].self, forKey: .fullName) {
            fullName = metadata["full_name"]
        } else {
            fullName = nil
        }
        
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString)
        } else {
            createdAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        if let fullName = fullName {
            try container.encode(["full_name": fullName], forKey: .fullName)
        }
    }
    
    // Manual initializer for creating instances
    init(id: String, email: String?, fullName: String?, createdAt: Date?) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.createdAt = createdAt
    }
}

/// Authentication service using Supabase Auth
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: AuthUser?
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: AuthError?
    
    private let sessionKey = "supabase_session"
    private var session: UserSession?
    
    private init() {
        loadStoredSession()
    }
    
    // MARK: - Session Management
    
    private func loadStoredSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(UserSession.self, from: data) else {
            return
        }
        
        if !session.isExpired {
            self.session = session
            self.currentUser = session.user
            self.isSignedIn = true
        } else {
            // Try to refresh the session
            Task {
                await refreshSession(session.refreshToken)
            }
        }
    }
    
    private func saveSession(_ session: UserSession) {
        self.session = session
        self.currentUser = session.user
        self.isSignedIn = true
        
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }
    
    private func clearSession() {
        session = nil
        currentUser = nil
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
    
    // MARK: - Auth Actions
    
    /// Sign up with email and password
    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let url = SupabaseConfig.authURL.appendingPathComponent("signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let authResponse = try parseAuthResponse(data)
            saveSession(authResponse)
        } else {
            let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            throw AuthError.serverError(errorResponse?.message ?? "Sign up failed")
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let url = SupabaseConfig.authURL.appendingPathComponent("token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        // Add grant_type as query parameter
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        request.url = components.url
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        if httpResponse.statusCode == 200 {
            let authResponse = try parseAuthResponse(data)
            saveSession(authResponse)
        } else {
            let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            throw AuthError.serverError(errorResponse?.message ?? "Sign in failed")
        }
    }
    
    /// Sign out
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        // Call logout endpoint if we have a token
        if let accessToken = session?.accessToken {
            let url = SupabaseConfig.authURL.appendingPathComponent("logout")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            _ = try? await URLSession.shared.data(for: request)
        }
        
        clearSession()
    }
    
    /// Refresh the session
    func refreshSession(_ refreshToken: String) async {
        let url = SupabaseConfig.authURL.appendingPathComponent("token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        request.url = components.url
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try? JSONEncoder().encode(body)
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let authResponse = try? parseAuthResponse(data) else {
            clearSession()
            return
        }
        
        saveSession(authResponse)
    }
    
    /// Get current access token (refreshes if needed)
    func getAccessToken() async -> String? {
        guard let session = session else { return nil }
        
        if session.isExpired {
            await refreshSession(session.refreshToken)
        }
        
        return self.session?.accessToken
    }
    
    // MARK: - Helpers
    
    private func parseAuthResponse(_ data: Data) throws -> UserSession {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Int,
              let userJson = json["user"] as? [String: Any] else {
            throw AuthError.invalidResponse
        }
        
        let userData = try JSONSerialization.data(withJSONObject: userJson)
        let user = try JSONDecoder().decode(AuthUser.self, from: userData)
        
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        return UserSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: user
        )
    }
}

// MARK: - Error Types

enum AuthError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case serverError(String)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let message):
            return message
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        }
    }
}

struct AuthErrorResponse: Codable {
    let message: String
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case message = "msg"
        case error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try different keys for the message
        if let msg = try? container.decode(String.self, forKey: .message) {
            message = msg
        } else if let err = try? container.decode(String.self, forKey: .error) {
            message = err
        } else {
            message = "Unknown error"
        }
        error = try? container.decodeIfPresent(String.self, forKey: .error)
    }
}
