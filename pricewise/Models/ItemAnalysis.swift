import Foundation

// MARK: - Item Details
struct ItemDetails: Codable, Identifiable {
    var id: UUID = UUID()
    var metadata: Metadata
    var market_value: Double?
    var date_analyzed: Date = Date()
    var image_url: String?
    var image: UIImage?
    
    struct Metadata: Codable {
        var brand: String
        var product_name: String?
        var barcode: String?
        var condition: ItemCondition?
        var sizes: [String]?
    }
}

// MARK: - Item Condition
enum ItemCondition: String, Codable {
    case new = "new"
    case likeNew = "like_new"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
}

// MARK: - OpenAI Response
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Analysis Error
enum AnalysisError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case parsingError(Error)
    case noResponse
    case rateLimitExceeded
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .noResponse:
            return "No response from the server"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        }
    }
} 