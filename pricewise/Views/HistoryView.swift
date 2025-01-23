import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Daily Items List
                List {
                    ForEach(viewModel.groupedItems.keys.sorted(by: >), id: \.self) { date in
                        Section(header: DailySummaryHeader(date: date, items: viewModel.groupedItems[date] ?? [])) {
                            ForEach(viewModel.groupedItems[date] ?? []) { item in
                                NavigationLink {
                                    ItemDetailsView(
                                        item: item.details,
                                        image: item.imageData != nil ? UIImage(data: item.imageData!) : nil,
                                        isLoading: false,
                                        error: nil
                                    )
                                } label: {
                                    HistoryItemRow(item: item)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search items...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DailySummaryHeader: View {
    let date: Date
    let items: [ItemAnalysis]
    
    private var totalValue: Double {
        items.reduce(0) { $0 + $1.details.estimatedValue }
    }
    
    var body: some View {
        HStack {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            Spacer()
            Text(String(format: "Total: $%.2f", totalValue))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct HistoryItemRow: View {
    let item: ItemAnalysis
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.details.brand)
                    .font(.headline)
                Text(item.details.productName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.2f", item.details.estimatedValue))
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("From", selection: $viewModel.dateRange.start, displayedComponents: .date)
                    DatePicker("To", selection: $viewModel.dateRange.end, displayedComponents: .date)
                }
                
                Section(header: Text("Price Range")) {
                    HStack {
                        TextField("Min", value: $viewModel.priceRange.min, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                        Text("-")
                        TextField("Max", value: $viewModel.priceRange.max, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Filters")
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
}

#Preview {
    HistoryView()
}