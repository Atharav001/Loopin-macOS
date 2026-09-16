import Foundation
import AppKit
import Combine

// MARK: - GoogleUserProfile
public struct GoogleUserProfile: Codable, Sendable {
    public let id: String?
    public let email: String?
    public let verifiedEmail: Bool?
    public let name: String?
    public let givenName: String?
    public let familyName: String?
    public let picture: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, picture
        case verifiedEmail = "verified_email"
        case givenName = "given_name"
        case familyName = "family_name"
    }
}

// MARK: - GoogleCalendarListResponse
public struct GoogleCalendarListResponse: Codable, Sendable {
    public struct CalendarItem: Codable, Sendable {
        public let id: String
        public let summary: String
        public let primary: Bool?
    }
    public let items: [CalendarItem]?
}

// MARK: - GoogleAuthService
@MainActor
public final class GoogleAuthService: ObservableObject, @unchecked Sendable {
    public static let shared = GoogleAuthService()
    
    @Published public var isAuthenticating: Bool = false
    @Published public var authErrorMessage: String?
    @Published public var validationSuccessMessage: String?
    @Published public var userProfile: GoogleUserProfile?
    
    // Default desktop client ID for Loopin
    public static let defaultClientId = "948271038472-loopin-macos-client.apps.googleusercontent.com"
    public static let redirectUri = "https://127.0.0.1:8080/oauth2callback"
    public static let scopes = "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
    
    private let session = URLSession(configuration: .default)
    
    public init() {}
    
    // MARK: - Generate Google OAuth 2.0 URL
    public func buildAuthorizationUrl(clientId: String? = nil) -> URL? {
        let actualClientId = (clientId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? clientId!.trimmingCharacters(in: .whitespacesAndNewlines)
            : GoogleCalendarConfig.shared.clientId.isEmpty ? Self.defaultClientId : GoogleCalendarConfig.shared.clientId
        
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: actualClientId),
            URLQueryItem(name: "redirect_uri", value: Self.redirectUri),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope", value: Self.scopes),
            URLQueryItem(name: "access_type", value: "online"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components?.url
    }
    
    // MARK: - Open OAuth in System Browser
    public func openGoogleOAuthInBrowser(clientId: String? = nil) {
        if let url = buildAuthorizationUrl(clientId: clientId) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Verify Access Token with Google UserInfo API
    public func verifyTokenAndFetchProfile(token: String) async -> Result<GoogleUserProfile, Error> {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else {
            return .failure(NSError(domain: "GoogleAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Token cannot be empty."]))
        }
        
        guard let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else {
            return .failure(NSError(domain: "GoogleAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpRes = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "GoogleAuthService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid server response."]))
            }
            
            if httpRes.statusCode == 200 {
                let decoder = JSONDecoder()
                let profile = try decoder.decode(GoogleUserProfile.self, from: data)
                self.userProfile = profile
                
                // Store in config and AppState
                GoogleCalendarConfig.shared.accessToken = cleanToken
                AppState.shared.isSignedInWithGoogle = true
                if let email = profile.email { AppState.shared.googleUserEmail = email }
                if let name = profile.name { AppState.shared.googleUserName = name }
                AppState.shared.googleAuthToken = cleanToken
                
                // Also verify Calendar API access
                Task {
                    _ = await self.fetchCalendarList(token: cleanToken)
                }
                
                return .success(profile)
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "HTTP \(httpRes.statusCode)"
                return .failure(NSError(domain: "GoogleAuthService", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "Google returned HTTP \(httpRes.statusCode): \(errorBody)"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Fetch or Create Loopin Calendars
    public func fetchCalendarList(token: String) async -> [GoogleCalendarListResponse.CalendarItem] {
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        guard let (data, res) = try? await session.data(for: req),
              let httpRes = res as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return []
        }
        
        if let list = try? JSONDecoder().decode(GoogleCalendarListResponse.self, from: data),
           let items = list.items {
            for item in items {
                if item.summary.localizedCaseInsensitiveContains("Loopin Planned") {
                    GoogleCalendarConfig.shared.plannedCalendarId = item.id
                } else if item.summary.localizedCaseInsensitiveContains("Loopin Logged") {
                    GoogleCalendarConfig.shared.loggedCalendarId = item.id
                }
            }
            return items
        }
        return []
    }
    
    // MARK: - Disconnect Google Account
    public func disconnect() {
        GoogleCalendarConfig.shared.disconnect()
        AppState.shared.isSignedInWithGoogle = false
        AppState.shared.googleAuthToken = ""
        userProfile = nil
    }
}
