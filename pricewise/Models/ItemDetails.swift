import Foundation

struct ItemMetadata: Codable {
    let brand: String
    let product_name: String?
    let condition: String?
    let sizes: [String]?
}

struct ItemDetails: Identifiable, Codable {
    let id: UUID
    let brand: String
    let product_name: String?
    let condition: String?
    let sizes: [String]?
    let barcode: String?
    let market_value: Double?
    let estimated_value: Double?
    let date_analyzed: Date
    
    init(brand: String, 
         product_name: String? = nil,
         condition: String? = nil,
         barcode: String? = nil,
         sizes: [String]? = nil,
         market_value: Double? = nil,
         estimated_value: Double? = nil) {
        self.id = UUID()
        self.brand = brand
        self.product_name = product_name
        self.condition = condition
        self.barcode = barcode
        self.sizes = sizes
        self.market_value = market_value
        self.estimated_value = estimated_value
        self.date_analyzed = Date()
    }
    
    // Convenience initializer for preview/testing
    init(brand: String, product_name: String?, condition: String?, market_value: Double?) {
        self.id = UUID()
        self.brand = brand
        self.product_name = product_name
        self.condition = condition
        self.sizes = nil
        self.barcode = nil
        self.market_value = market_value
        self.estimated_value = nil
        self.date_analyzed = Date()
    }
} 