import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData
}

enum KeychainKeys {
    static let openAIKey = "openai_api_key"
    static let tavilyKey = "tavily_api_key"
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - API Key Management
    func saveAPIKey(_ key: String, service: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unknown(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    func getAPIKey(service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return key
    }
    
    func deleteAPIKey(service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - Convenience Methods for Specific API Keys
    func saveOpenAIAPIKey(_ key: String) throws {
        try saveAPIKey(key, service: KeychainKeys.openAIKey)
    }
    
    func getOpenAIAPIKey() throws -> String {
        try getAPIKey(service: KeychainKeys.openAIKey)
    }
    
    func saveTavilyAPIKey(_ key: String) throws {
        try saveAPIKey(key, service: KeychainKeys.tavilyKey)
    }
    
    func getTavilyAPIKey() throws -> String {
        try getAPIKey(service: KeychainKeys.tavilyKey)
    }
    
    func deleteOpenAIAPIKey() throws {
        try deleteAPIKey(service: KeychainKeys.openAIKey)
    }
    
    func deleteTavilyAPIKey() throws {
        try deleteAPIKey(service: KeychainKeys.tavilyKey)
    }
}