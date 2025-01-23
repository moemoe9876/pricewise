import SwiftUI
import PhotosUI

struct BatchProcessingView: View {
    @StateObject private var viewModel = ItemAnalysisViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingResults = false
    @State private var processingProgress: Double = 0
    @State private var failedItems: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Selected Images Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 16)
                    ], spacing: 16) {
                        // Add Image Button
                        PhotosPicker(selection: $selectedPhotos,
                                   maxSelectionCount: 10,
                                   matching: .images) {
                            AddImageCell()
                        }
                        
                        // Selected Images
                        ForEach(selectedImages.indices, id: \.self) { index in
                            SelectedImageCell(image: selectedImages[index]) {
                                selectedImages.remove(at: index)
                            }
                        }
                    }
                    .padding()
                }
                
                // Progress Section
                if viewModel.isAnalyzing {
                    ProgressSection(progress: $processingProgress)
                }
                
                // Action Buttons
                ActionButtons(
                    selectedCount: selectedImages.count,
                    isAnalyzing: viewModel.isAnalyzing,
                    onProcess: processImages
                )
            }
            .navigationTitle("Batch Processing")
            .onChange(of: selectedPhotos) { _, newValue in
                Task {
                    await loadSelectedImages(from: newValue)
                }
            }
            .sheet(isPresented: $showingResults) {
                NavigationView {
                    BatchResultsSummaryView(
                        items: viewModel.analyzedItems,
                        failedItems: failedItems
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingResults = false
                                // Clear the state for next batch
                                selectedImages.removeAll()
                                selectedPhotos.removeAll()
                                failedItems.removeAll()
                                processingProgress = 0
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error occurred")
            }
        }
    }
    
    private func loadSelectedImages(from selections: [PhotosPickerItem]) async {
        for item in selections {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Compress image before adding
                if let compressedImage = compressImage(image) {
                    await MainActor.run {
                        selectedImages.append(compressedImage)
                    }
                } else {
                    await MainActor.run {
                        failedItems.append("Failed to compress image")
                    }
                }
            } else {
                await MainActor.run {
                    failedItems.append("Failed to load image")
                }
            }
        }
    }
    
    private func compressImage(_ image: UIImage) -> UIImage? {
        let maxSize: CGFloat = 1024 // Maximum dimension size
        let scale = min(maxSize/image.size.width, maxSize/image.size.height)
        
        if scale < 1 {
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let compressedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return compressedImage
        }
        
        return image
    }
    
    private func processImages() {
        guard !selectedImages.isEmpty else { return }
        
        // Reset state
        failedItems.removeAll()
        processingProgress = 0
        
        Task {
            // Process images in batches of 5
            let batchSize = 5
            let totalBatches = Int(ceil(Double(selectedImages.count) / Double(batchSize)))
            
            for batchIndex in 0..<totalBatches {
                let start = batchIndex * batchSize
                let end = min(start + batchSize, selectedImages.count)
                let batch = Array(selectedImages[start..<end])
                
                do {
                    try await viewModel.analyzeImages(batch)
                } catch {
                    for _ in batch {
                        failedItems.append("Failed to analyze image: \(error.localizedDescription)")
                    }
                }
                
                await MainActor.run {
                    processingProgress = Double(end) / Double(selectedImages.count)
                }
            }
            
            await MainActor.run {
                showingResults = true
            }
        }
    }
}

// MARK: - Supporting Views
struct AddImageCell: View {
    var body: some View {
        VStack {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 30))
            Text("Add Photos")
                .font(.caption)
        }
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SelectedImageCell: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Circle().fill(Color.white))
            }
            .padding(4)
        }
    }
}

struct ProgressSection: View {
    @Binding var progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct ActionButtons: View {
    let selectedCount: Int
    let isAnalyzing: Bool
    let onProcess: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onProcess) {
                if isAnalyzing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Process \(selectedCount) Images")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedCount > 0 ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(selectedCount == 0 || isAnalyzing)
            
            if selectedCount > 0 {
                Text("\(selectedCount) images selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    BatchProcessingView()
}