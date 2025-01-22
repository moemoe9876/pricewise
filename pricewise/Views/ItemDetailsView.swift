import SwiftUI

struct ItemDetailsView: View {
    let item: ItemDetails?
    let image: UIImage?
    let isLoading: Bool
    let error: AnalysisError?
    var onRetry: (() -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Section
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                }
                
                // Loading State
                if isLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing image...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                }
                
                // Error State
                else if let error = error {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        if let onRetry = onRetry {
                            Button(action: onRetry) {
                                Label("Retry Analysis", systemImage: "arrow.clockwise")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Results
                else if let item = item {
                    // Metadata Section
                    VStack(alignment: .leading, spacing: 15) {
                        MetadataRow(title: "Brand", value: item.metadata.brand)
                        
                        if let productName = item.metadata.product_name {
                            MetadataRow(title: "Product", value: productName)
                        }
                        
                        if let condition = item.metadata.condition?.rawValue.capitalized {
                            MetadataRow(title: "Condition", value: condition)
                        }
                        
                        if let barcode = item.metadata.barcode {
                            MetadataRow(title: "Barcode", value: barcode)
                        }
                        
                        if let sizes = item.metadata.sizes, !sizes.isEmpty {
                            MetadataRow(title: "Sizes", value: sizes.joined(separator: ", "))
                        }
                        
                        if let marketValue = item.market_value {
                            MetadataRow(title: "Estimated Value", value: String(format: "$%.2f", marketValue))
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Item Details")
    }
}

// MARK: - Supporting Views
struct MetadataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NavigationView {
        ItemDetailsView(
            item: ItemDetails(
                metadata: ItemDetails.Metadata(
                    brand: "Nike",
                    product_name: "Air Max 270",
                    barcode: "123456789",
                    condition: .good,
                    sizes: ["US 10", "EU 44"]
                ),
                market_value: 129.99
            ),
            image: nil,
            isLoading: false,
            error: nil
        )
    }
} 