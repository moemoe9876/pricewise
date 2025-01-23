import Foundation
import UIKit

// MARK: - Item Details
struct ItemDetails: Codable, Identifiable {
    let id = UUID()
    let brand: String
    let productName: String
    let condition: String
    let barcode: String?
    let sizes: [String]?
    let estimatedValue: Double
    var image: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case brand
        case productName
        case condition
        case barcode
        case sizes
        case estimatedValue
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

struct ItemAnalysis: Codable, Identifiable {
    let id = UUID()
    let details: ItemDetails
    let timestamp: Date
    let imageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id
        case details
        case timestamp
        case imageData
    }
} 