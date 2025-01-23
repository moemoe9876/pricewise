import SwiftUI

struct AnalysisResultsView: View {
    let items: [ItemDetails]
    let images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(zip(items.indices, items)), id: \.0) { index, item in
                    NavigationLink {
                        ItemDetailsView(
                            item: item,
                            image: images[index],
                            isLoading: false,
                            error: nil
                        )
                    } label: {
                        HStack {
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text(item.brand)
                                    .font(.headline)
                                Text(item.productName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(String(format: "$%.2f", item.estimatedValue))
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Analysis Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AnalysisResultsView(
        items: [
            ItemDetails(
                brand: "Nike",
                productName: "Air Max 90",
                condition: "Good",
                barcode: "123456789",
                sizes: ["US 9", "US 10"],
                estimatedValue: 129.99,
                image: nil
            )
        ],
        images: [UIImage(systemName: "photo")!]
    )
} 