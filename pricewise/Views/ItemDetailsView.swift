import SwiftUI

struct ItemDetailsView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: ItemAnalysisViewModel
    let item: ItemDetails
    @State private var isEditing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Add state variables for editing
    @State private var editedBrand: String = ""
    @State private var editedProductName: String = ""
    @State private var editedCondition: String = ""
    @State private var editedSizes: String = ""
    @State private var editedBarcode: String = ""
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image Section
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
                
                // Item Details Section
                GroupBox(label: Text("Item Details").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        if isEditing {
                            EditableDetailRow(label: "Brand", value: $editedBrand)
                            EditableDetailRow(label: "Product", value: $editedProductName)
                            ConditionPicker(selectedCondition: $editedCondition)
                            EditableDetailRow(label: "Sizes", value: $editedSizes, placeholder: "Comma-separated sizes")
                            EditableDetailRow(label: "Barcode", value: $editedBarcode)
                        } else {
                            DetailRow(label: "Brand", value: item.metadata.brand)
                            if let productName = item.metadata.product_name {
                                DetailRow(label: "Product", value: productName)
                            }
                            if let condition = item.metadata.condition {
                                DetailRow(label: "Condition", value: condition.capitalized)
                            }
                            if let sizes = item.metadata.sizes, !sizes.isEmpty {
                                DetailRow(label: "Sizes", value: sizes.joined(separator: ", "))
                            }
                            if let barcode = item.metadata.barcode {
                                DetailRow(label: "Barcode", value: barcode)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Market Value Section
                GroupBox(label: Text("Market Value").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let marketValue = item.market_value {
                            Text("$\(String(format: "%.2f", marketValue))")
                                .font(.title2)
                                .foregroundColor(.green)
                        } else {
                            HStack {
                                Text("Pending...")
                                    .foregroundColor(.secondary)
                                ProgressView()
                            }
                        }
                        
                        Button(action: recalculateMarketValue) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Recalculate Value")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
        .navigationTitle("Item Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                    if isEditing {
                        // Initialize editing values when entering edit mode
                        editedBrand = item.metadata.brand
                        editedProductName = item.metadata.product_name ?? ""
                        editedCondition = item.metadata.condition ?? "good"
                        editedSizes = item.metadata.sizes?.joined(separator: ", ") ?? ""
                        editedBarcode = item.metadata.barcode ?? ""
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    private func recalculateMarketValue() {
        // This will be implemented when we integrate the Tavily API
        // For now, just show a placeholder error
        showingError = true
        errorMessage = "Market value recalculation will be available in the next update."
    }
    
    // Add these new functions after the existing recalculateMarketValue function
    private func saveChanges() {
        // Validate required fields
        guard !editedBrand.isEmpty else {
            showingError = true
            errorMessage = "Brand name is required"
            return
        }
        
        // Create new metadata
        let sizes = editedSizes.isEmpty ? nil : editedSizes.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        let newMetadata = ItemDetails.Metadata(
            brand: editedBrand,
            product_name: editedProductName.isEmpty ? nil : editedProductName,
            barcode: editedBarcode.isEmpty ? nil : editedBarcode,
            condition: editedCondition.isEmpty ? nil : editedCondition,
            sizes: sizes
        )
        
        // Update the item through the view model
        viewModel.updateItemMetadata(for: item.id, metadata: newMetadata)
    }
}

// Add these new supporting views after the existing DetailRow view
struct EditableDetailRow: View {
    let label: String
    @Binding var value: String
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(placeholder.isEmpty ? label : placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct ConditionPicker: View {
    @Binding var selectedCondition: String
    let conditions = ["new", "like_new", "good", "fair", "poor"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Condition")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("Condition", selection: $selectedCondition) {
                ForEach(conditions, id: \.self) { condition in
                    Text(condition.capitalized).tag(condition)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

// MARK: - Preview
struct ItemDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemDetailsView(
                viewModel: ItemAnalysisViewModel(),
                item: ItemDetails(
                    brand: "Nike",
                    product_name: "Air Max 270",
                    condition: "good",
                    sizes: ["10", "10.5"],
                    market_value: 129.99,
                    image: nil
                )
            )
        }
    }
}