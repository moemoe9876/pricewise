import SwiftUI
import UniformTypeIdentifiers

struct BatchResultsSummaryView: View {
    let items: [ItemDetails]
    let failedItems: [String] // Array of failed item descriptions/errors
    @State private var showingExportSheet = false
    @State private var exportError: Error?
    @State private var showingErrorAlert = false
    @State private var selectedFormat: ExportFormat = .csv
    @State private var showingFormatPicker = false
    @State private var exportURL: URL?
    
    private var successCount: Int {
        items.count
    }
    
    private var failureCount: Int {
        failedItems.count
    }
    
    private var totalValue: Double {
        items.compactMap { $0.market_value }.reduce(0, +)
    }
    
    private var averageValue: Double {
        guard successCount > 0 else { return 0 }
        return totalValue / Double(successCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Processed",
                        value: "\(successCount)/\(successCount + failureCount)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    SummaryCard(
                        title: "Total Value",
                        value: String(format: "$%.2f", totalValue),
                        icon: "dollarsign.circle.fill",
                        color: .blue
                    )
                }
                
                // Export Button
                Button(action: { showingFormatPicker = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Results")
                        Spacer()
                        Text(selectedFormat.rawValue)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .confirmationDialog(
                    "Export Format",
                    isPresented: $showingFormatPicker,
                    titleVisibility: .visible
                ) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(format.rawValue) {
                            selectedFormat = format
                            exportResults()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                if failureCount > 0 {
                    // Failed Items Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Failed Items")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        ForEach(failedItems, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                
                // Successful Items List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Processed Items")
                        .font(.headline)
                    
                    ForEach(items) { item in
                        ProcessedItemRow(item: item)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Batch Results")
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Error", isPresented: $showingErrorAlert) {
            Button("OK") {
                showingErrorAlert = false
            }
        } message: {
            Text(exportError?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    private func exportResults() {
        do {
            exportURL = try ExportManager.shared.exportResults(
                items: items,
                failedItems: failedItems,
                format: selectedFormat
            )
            showingExportSheet = true
        } catch {
            exportError = error
            showingErrorAlert = true
        }
    }
}

// MARK: - Supporting Views
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProcessedItemRow: View {
    let item: ItemDetails
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.metadata.brand)
                    .font(.headline)
                if let productName = item.metadata.product_name {
                    Text(productName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let marketValue = item.market_value {
                Text(String(format: "$%.2f", marketValue))
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Text("Pending")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        BatchResultsSummaryView(
            items: [
                ItemDetails(
                    brand: "Nike",
                    product_name: "Air Max 270",
                    condition: "good",
                    market_value: 120.00
                ),
                ItemDetails(
                    brand: "Adidas",
                    product_name: "Ultra Boost",
                    condition: "like_new",
                    market_value: 150.00
                )
            ],
            failedItems: [
                "Failed to process image: Invalid format",
                "Network error while analyzing item"
            ]
        )
    }
} 