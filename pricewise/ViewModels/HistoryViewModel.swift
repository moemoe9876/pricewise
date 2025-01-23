import Foundation

class HistoryViewModel: ObservableObject {
    @Published var groupedItems: [Date: [ItemAnalysis]] = [:]
    @Published var dateRange = DateRange(start: .now.addingTimeInterval(-30*24*60*60), end: .now)
    @Published var priceRange = PriceRange(min: 0, max: 1000)
    
    struct DateRange {
        var start: Date
        var end: Date
    }
    
    struct PriceRange {
        var min: Double
        var max: Double
    }
    
    init() {
        loadItems()
    }
    
    func loadItems() {
        // TODO: Implement Firebase Firestore integration
        // For now, using mock data
        let mockItems = createMockData()
        groupItemsByDate(mockItems)
    }
    
    private func groupItemsByDate(_ items: [ItemAnalysis]) {
        let filtered = items.filter { item in
            let inDateRange = (dateRange.start...dateRange.end).contains(item.timestamp)
            let inPriceRange = (priceRange.min...priceRange.max).contains(item.details.estimatedValue)
            return inDateRange && inPriceRange
        }
        
        let grouped = Dictionary(grouping: filtered) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }
        
        groupedItems = grouped
    }
    
    private func createMockData() -> [ItemAnalysis] {
        // TODO: Remove this when Firebase integration is complete
        return []
    }
}