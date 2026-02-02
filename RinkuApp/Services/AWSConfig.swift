import Foundation

/// AWS Configuration for Rekognition
/// Reads credentials from Secrets.plist (which is gitignored)
struct AWSConfig {
    
    private static var secrets: [String: Any]? = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("⚠️ Secrets.plist not found. Copy Secrets.template.plist to Secrets.plist and add your credentials.")
            return nil
        }
        return dict
    }()
    
    static var accessKeyId: String {
        secrets?["AWS_ACCESS_KEY_ID"] as? String ?? ""
    }
    
    static var secretAccessKey: String {
        secrets?["AWS_SECRET_ACCESS_KEY"] as? String ?? ""
    }
    
    static var region: String {
        secrets?["AWS_REGION"] as? String ?? "us-east-1"
    }
    
    /// Check if credentials are configured
    static var isConfigured: Bool {
        !accessKeyId.isEmpty && 
        !secretAccessKey.isEmpty &&
        accessKeyId != "YOUR_AWS_ACCESS_KEY_ID" && 
        secretAccessKey != "YOUR_AWS_SECRET_ACCESS_KEY"
    }
    
    /// Rekognition endpoint URL
    static var rekognitionEndpoint: URL {
        URL(string: "https://rekognition.\(region).amazonaws.com")!
    }
}
