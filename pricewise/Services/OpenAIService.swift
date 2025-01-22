import Foundation
import UIKit

actor OpenAIService {
    static let shared = OpenAIService()
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let keychainManager = KeychainManager.shared
    
    private init() {}
    
    // MARK: - Image Analysis
    func analyzeImage(_ image: UIImage) async throws -> ItemDetails {
        guard let apiKey = try? keychainManager.getAPIKey(service: "openai") else {
            throw AnalysisError.invalidAPIKey
        }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7),
              let base64Image = String(data: imageData.base64EncodedData(), encoding: .utf8) else {
            throw AnalysisError.parsingError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"]))
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "clothing_product_identifier",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "properties": [
                            "metadata": [
                                "type": "object",
                                "description": "Metadata related to the identified clothing or product.",
                                "properties": [
                                    "brand": [
                                        "type": "string",
                                        "description": "The name of the brand associated with the item."
                                    ],
                                    "product_name": [
                                        "type": "string",
                                        "nullable": true
                                    ],
                                    "barcode": [
                                        "type": "string",
                                        "nullable": true
                                    ],
                                    "condition": [
                                        "type": "string",
                                        "enum": [
                                            "new",
                                            "like_new",
                                            "good",
                                            "fair",
                                            "poor"
                                        ],
                                        "nullable": true
                                    ],
                                    "sizes": [
                                        "type": "array",
                                        "items": [
                                            "type": "string"
                                        ],
                                        "nullable": true
                                    ]
                                ],
                                "required": [
                                    "brand"
                                ],
                                "additionalProperties": false
                            ]
                        ],
                        "required": [
                            "metadata"
                        ],
                        "additionalProperties": false
                    ]
                ]
            ],
            "temperature": 1,
            "max_completion_tokens": 2048,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0
        ]
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw AnalysisError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AnalysisError.parsingError(error)
        }
        
        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let firstChoice = openAIResponse.choices.first,
                      let responseData = firstChoice.message.content.data(using: .utf8) else {
                    throw AnalysisError.noResponse
                }
                
                let itemDetails = try JSONDecoder().decode(ItemDetails.self, from: responseData)
                return itemDetails
            } catch {
                throw AnalysisError.parsingError(error)
            }
        case 401:
            throw AnalysisError.invalidAPIKey
        case 429:
            throw AnalysisError.rateLimitExceeded
        case 500...599:
            throw AnalysisError.serverError
        default:
            throw AnalysisError.networkError(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected status code: \(httpResponse.statusCode)"]))
        }
    }
    
    // MARK: - Batch Analysis
    func analyzeImages(_ images: [UIImage]) async throws -> [ItemDetails] {
        var results: [ItemDetails] = []
        
        // Process images sequentially to avoid rate limiting
        for image in images {
            do {
                let itemDetails = try await analyzeImage(image)
                results.append(itemDetails)
            } catch {
                // Log error but continue processing other images
                print("Error analyzing image: \(error.localizedDescription)")
                continue
            }
        }
        
        return results
    }
} 