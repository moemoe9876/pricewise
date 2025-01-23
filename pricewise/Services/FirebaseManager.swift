import Firebase
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    @Published var items: [ItemAnalysis] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    
    func saveItem(_ item: ItemAnalysis) async throws {
        let data = try JSONEncoder().encode(item)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode item"])
        }
        
        try await db.collection("items").document(item.id.uuidString).setData(dict)
        
        if let imageData = item.imageData {
            let imageRef = storage.child("images/\(item.id.uuidString).jpg")
            _ = try await imageRef.putDataAsync(imageData)
        }
    }
    
    func loadItems(after date: Date? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        var query = db.collection("items")
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        lastDocument = snapshot.documents.last
        
        let newItems = try snapshot.documents.compactMap { document -> ItemAnalysis? in
            let data = document.data()
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(ItemAnalysis.self, from: jsonData)
        }
        
        await MainActor.run {
            if lastDocument == nil {
                items = newItems
            } else {
                items.append(contentsOf: newItems)
            }
        }
    }
    
    func deleteItem(_ item: ItemAnalysis) async throws {
        try await db.collection("items").document(item.id.uuidString).delete()
        if item.imageData != nil {
            try await storage.child("images/\(item.id.uuidString).jpg").delete()
        }
        await MainActor.run {
            items.removeAll { $0.id == item.id }
        }
    }
    
    func setupRealtimeUpdates() {
        db.collection("items")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                do {
                    let updatedItems = try snapshot.documents.compactMap { document -> ItemAnalysis? in
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(ItemAnalysis.self, from: jsonData)
                    }
                    
                    DispatchQueue.main.async {
                        self.items = updatedItems
                    }
                } catch {
                    self.error = error
                }
            }
    }
}