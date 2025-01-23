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
                    ProgressView("Analyzing...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Error State
                if let error = error {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                        
                        if let onRetry = onRetry {
                            Button("Try Again", action: onRetry)
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
                
                // Results
                if let item = item {
                    VStack(alignment: .leading, spacing: 15) {
                        Group {
                            InfoRow(title: "Brand", value: item.brand)
                            InfoRow(title: "Product", value: item.productName)
                            InfoRow(title: "Condition", value: item.condition)
                            
                            if let barcode = item.barcode {
                                InfoRow(title: "Barcode", value: barcode)
                            }
                            
                            if let sizes = item.sizes, !sizes.isEmpty {
                                InfoRow(title: "Sizes", value: sizes.joined(separator: ", "))
                            }
                            
                            InfoRow(title: "Estimated Value", value: String(format: "$%.2f", item.estimatedValue))
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
            }
            .padding()
        }
        .navigationTitle("Item Details")
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                brand: "Nike",
                productName: "Air Max 90",
                condition: "Good",
                barcode: "123456789",
                sizes: ["US 9", "US 10"],
                estimatedValue: 129.99,
                image: nil
            ),
            image: nil,
            isLoading: false,
            error: nil
        )
    }
} 