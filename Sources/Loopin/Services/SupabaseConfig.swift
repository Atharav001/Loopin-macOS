import Foundation

// MARK: - SupabaseConfig
@MainActor
public final class SupabaseConfig: ObservableObject, @unchecked Sendable {
    public static let shared = SupabaseConfig()
    
    private let urlKey = "Loopin_Supabase_URL"
    private let anonKey = "Loopin_Supabase_AnonKey"
    private let userEmailKey = "Loopin_User_Email"
    private let authTokenKey = "Loopin_Auth_Token"
    private let autoSyncKey = "Loopin_Auto_Sync_Enabled"
    
    @Published public var projectUrl: String {
        didSet { UserDefaults.standard.set(projectUrl, forKey: urlKey) }
    }
    
    @Published public var anonApiKey: String {
        didSet { UserDefaults.standard.set(anonApiKey, forKey: anonKey) }
    }
    
    @Published public var userEmail: String {
        didSet { UserDefaults.standard.set(userEmail, forKey: userEmailKey) }
    }
    
    @Published public var authToken: String? {
        didSet { UserDefaults.standard.set(authToken, forKey: authTokenKey) }
    }
    
    @Published public var isAutoSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(isAutoSyncEnabled, forKey: autoSyncKey) }
    }
    
    public init() {
        self.projectUrl = UserDefaults.standard.string(forKey: urlKey) ?? "https://your-project.supabase.co"
        self.anonApiKey = UserDefaults.standard.string(forKey: anonKey) ?? ""
        self.userEmail = UserDefaults.standard.string(forKey: userEmailKey) ?? ""
        self.authToken = UserDefaults.standard.string(forKey: authTokenKey)
        self.isAutoSyncEnabled = UserDefaults.standard.bool(forKey: autoSyncKey)
    }
    
    public var isConfigured: Bool {
        return !projectUrl.isEmpty &&
               projectUrl != "https://your-project.supabase.co" &&
               !anonApiKey.isEmpty
    }
    
    public var isSignedIn: Bool {
        return isConfigured && !(authToken ?? "").isEmpty
    }
    
    public func clearAuth() {
        authToken = nil
        userEmail = ""
    }
}
