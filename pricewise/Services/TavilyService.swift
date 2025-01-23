import Foundation

enum TavilyError: Error {
    case invalidAPIKey
    case rateLimitExceeded
    case networkError(Error)
    case invalidResponse
    case noDataReceived
    case priceExtractionFailed
}

class TavilyService {
    static let shared = TavilyService()
    private let baseURL = "https://api.tavily.com/search"
    private let keychainManager = KeychainManager.shared
    
    // Rate limiting properties
    private let requestsPerMinute = 60
    private var requestTimestamps: [Date] = []
    private let queue = DispatchQueue(label: "com.pricewise.tavily.ratelimit")
    
    private init() {}
    
    func constructSearchQuery(from item: ItemDetails) -> String {
        var query = "What is the current market value or average selling price of a "
        
        if let condition = item.condition {
            query += "\(condition) condition "
        }
        
        query += "\(item.brand) "
        
        if let productName = item.productName {
            query += "\(productName) "
        }
        
        if let sizes = item.sizes, !sizes.isEmpty {
            query += "size\(sizes.count > 1 ? "s" : ""): \(sizes.joined(separator: ", ")) "
        }
        
        query += "on eBay, Amazon, and Facebook Marketplace? Only include numerical price values in the response."
        
        return query
    }
    
    private func checkRateLimit() -> Bool {
        queue.sync {
            let now = Date()
            // Remove timestamps older than 1 minute
            requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < 60 }
            
            if requestTimestamps.count < requestsPerMinute {
                requestTimestamps.append(now)
                return true
            }
            return false
        }
    }
    
    private func extractPrice(from content: String) -> Double? {
        // Regular expression to match price patterns
        let patterns = [
            #"\$\s*(\d+(?:\.\d{2})?)"#,  // Matches $XX.XX
            #"(\d+(?:\.\d{2})?)\s*dollars"#,  // Matches XX.XX dollars
            #"price[:\s]+\$?\s*(\d+(?:\.\d{2})?)"#  // Matches price: $XX.XX
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) {
                if let range = Range(match.range(at: 1), in: content),
                   let price = Double(content[range].replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)) {
                    return price
                }
            }
        }
        return nil
    }
    
    func getMarketValue(for item: ItemDetails) async throws -> Double {
        guard checkRateLimit() else {
            throw TavilyError.rateLimitExceeded
        }
        
        guard let apiKey = try? keychainManager.getTavilyAPIKey() else {
            throw TavilyError.invalidAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            throw TavilyError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let query = constructSearchQuery(from: item)
        let requestBody = ["query": query]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavilyError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 401:
                throw TavilyError.invalidAPIKey
            case 429:
                throw TavilyError.rateLimitExceeded
            case 200...299:
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]] else {
                    throw TavilyError.invalidResponse
                }
                
                // Combine all content for price extraction
                let allContent = results.compactMap { $0["content"] as? String }.joined(separator: " ")
                
                if let price = extractPrice(from: allContent) {
                    return price
                } else {
                    throw TavilyError.priceExtractionFailed
                }
            default:
                throw TavilyError.invalidResponse
            }
        } catch {
            throw TavilyError.networkError(error)
        }
    }
}