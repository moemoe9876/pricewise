import SwiftUI

struct ItemDetailsView: View {
    @State var viewModel: ItemAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }
                
                if let details = viewModel.itemDetails {
                    ItemDetailsCard(details: details)
                } else if viewModel.isAnalyzing {
                    ProgressView("Analyzing image...")
                } else if let error = viewModel.analysisError {
                    ErrorView(error: error) {
                        // Retry button action
                        if let image = viewModel.selectedImage {
                            Task {
                                await viewModel.analyzeImage(image)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ItemDetailsCard: View {
    let details: ItemDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Brand and Product
            VStack(alignment: .leading, spacing: 8) {
                Text(details.brand)
                    .font(.title2)
                    .bold()
                
                if let productName = details.product_name {
                    Text(productName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Condition
            if let condition = details.condition {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Condition: \(condition.capitalized)")
                        .font(.subheadline)
                }
            }
            
            // Sizes
            if let sizes = details.sizes, !sizes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Sizes")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(sizes, id: \.self) { size in
                            Text(size)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Market Value
            if let marketValue = details.market_value {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                    Text("Estimated Value:")
                        .font(.headline)
                    Text(String(format: "$%.2f", marketValue))
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                }
            }
            
            // Analysis Date
            Text("Analyzed on \(formatDate(details.date_analyzed))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Analysis Failed")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? .infinity,
            height: rows.last?.maxY ?? 0
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for row in rows {
            let rowXOffset = (bounds.width - row.width) / 2
            for element in row.elements {
                element.view.place(
                    at: CGPoint(
                        x: element.x + rowXOffset + bounds.minX,
                        y: row.y + bounds.minY
                    ),
                    proposal: ProposedViewSize(element.size)
                )
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(y: 0)
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            
            if x + size.width > maxWidth {
                rows.append(currentRow)
                currentRow = Row(y: currentRow.maxY + spacing)
                x = 0
            }
            
            currentRow.add(view: subview, size: size, x: x)
            x += size.width + spacing
        }
        
        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var elements: [(view: LayoutSubview, size: CGSize, x: CGFloat)] = []
        var y: CGFloat
        
        var width: CGFloat {
            guard let last = elements.last else { return 0 }
            return last.x + last.size.width
        }
        
        var height: CGFloat {
            elements.map(\.size.height).max() ?? 0
        }
        
        var maxY: CGFloat {
            y + height
        }
        
        mutating func add(view: LayoutSubview, size: CGSize, x: CGFloat) {
            elements.append((view, size, x))
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ItemDetailsView(
            viewModel: {
                let vm = ItemAnalysisViewModel()
                vm.itemDetails = ItemDetails(
                    brand: "Nike",
                    product_name: "Air Max 270",
                    condition: "good",
                    barcode: nil,
                    sizes: ["US 9", "US 10"],
                    market_value: 120.00,
                    estimated_value: 115.00
                )
                return vm
            }()
        )
    }
}