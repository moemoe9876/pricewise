import Foundation

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    
    var fileExtension: String {
        rawValue.lowercased()
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        }
    }
}

class ExportManager {
    static let shared = ExportManager()
    private init() {}
    
    /// Exports batch processing results in the specified format
    /// - Parameters:
    ///   - items: Successfully processed items
    ///   - failedItems: Items that failed processing
    ///   - format: The desired export format
    /// - Returns: URL of the temporary export file
    func exportResults(items: [ItemDetails], failedItems: [String], format: ExportFormat) throws -> URL {
        let content = switch format {
        case .csv: generateCSV(items: items, failedItems: failedItems)
        case .json: try generateJSON(items: items, failedItems: failedItems)
        }
        
        return try createTemporaryFile(content: content, format: format)
    }
    
    // MARK: - Format Generators
    
    /// Generates a CSV string from the batch processing results
    /// - Parameters:
    ///   - items: Successfully processed items
    ///   - failedItems: Items that failed processing
    /// - Returns: CSV string containing the results
    func generateCSV(items: [ItemDetails], failedItems: [String]) -> String {
        var csv = "Status,Brand,Product Name,Condition,Sizes,Market Value,Date Analyzed\n"
        
        // Add successful items
        for item in items {
            let row = [
                "Success",
                item.metadata.brand,
                item.metadata.product_name ?? "N/A",
                item.metadata.condition ?? "N/A",
                item.metadata.sizes?.joined(separator: "|") ?? "N/A",
                String(format: "%.2f", item.market_value ?? 0.0),
                formatDate(item.date_analyzed)
            ].map { escapeCSVField($0) }.joined(separator: ",")
            
            csv += row + "\n"
        }
        
        // Add failed items
        for error in failedItems {
            let row = [
                "Failed",
                "N/A",
                "N/A",
                "N/A",
                "N/A",
                "0.00",
                formatDate(Date()),
                escapeCSVField(error)  // Add error message as last field
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    /// Generates a JSON string from the batch processing results
    private func generateJSON(items: [ItemDetails], failedItems: [String]) throws -> String {
        let exportData = [
            "timestamp": formatDate(Date()),
            "summary": [
                "total_items": items.count + failedItems.count,
                "successful_items": items.count,
                "failed_items": failedItems.count,
                "total_value": items.compactMap { $0.market_value }.reduce(0, +)
            ],
            "successful_items": items.map { item in
                [
                    "brand": item.metadata.brand,
                    "product_name": item.metadata.product_name ?? "N/A",
                    "condition": item.metadata.condition ?? "N/A",
                    "sizes": item.metadata.sizes ?? [],
                    "market_value": item.market_value ?? 0.0,
                    "date_analyzed": formatDate(item.date_analyzed)
                ]
            },
            "failed_items": failedItems
        ] as [String : Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted])
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    // MARK: - File Operations
    
    /// Creates a temporary file with the export content
    private func createTemporaryFile(content: String, format: ExportFormat) throws -> URL {
        let timestamp = formatDate(Date(), format: "yyyyMMdd_HHmmss")
        let filename = "pricewise_batch_results_\(timestamp).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    // MARK: - Helper Methods
    
    private func escapeCSVField(_ field: String) -> String {
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedField)\""
    }
    
    private func formatDate(_ date: Date, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
} 