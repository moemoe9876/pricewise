func updateItemMetadata(for itemId: UUID, metadata: ItemDetails.Metadata) {
    if let index = items.firstIndex(where: { $0.id == itemId }) {
        // Create a new item with updated metadata
        var updatedItem = items[index]
        updatedItem.metadata = metadata
        
        // Update the items array
        items[index] = updatedItem
    }
}