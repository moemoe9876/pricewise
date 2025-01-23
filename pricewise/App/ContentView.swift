//
//  ContentView.swift
//  pricewise
//
//  Created by Mohamed Mohamoud on 22/01/2025.
//

import SwiftUI
import PhotosUI
import UIKit

struct ContentView: View {
    // MARK: - State
    @State private var viewModel = ItemAnalysisViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false
    
    // MARK: - Constants
    private let maxImages = 5
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("PriceWise")
                .toolbar { toolbarContent }
                .onChange(of: selectedPhotos) { _, newItems in
                    handlePhotoSelection(newItems: newItems)
                }
                .sheet(isPresented: $showCamera) {
                    ImagePicker(sourceType: .camera) { image in
                        if let image = image {
                            addImage(image)
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { viewModel.showResults || viewModel.isAnalyzing },
                    set: { if !$0 { viewModel.reset() } }
                )) {
                    analysisSheetContent
                }
                .alert("Error", isPresented: .init(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    if let error = viewModel.error {
                        Text(error.localizedDescription)
                    }
                }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            imageGrid
                .frame(maxHeight: .infinity)
            
            if !selectedImages.isEmpty {
                analysisButton
                    .padding(.bottom, 5)
            }
            
            HStack(spacing: 20) {
                addImageButton
                photoSourceButtons
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }
    
    private var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    gridImageItem(at: index)
                }
            }
            .padding()
        }
    }
    
    private func gridImageItem(at index: Int) -> some View {
        Image(uiImage: selectedImages[index])
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                Button(action: {
                    selectedImages.remove(at: index)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                }
                .padding(5),
                alignment: .topTrailing
            )
    }
    
    private var addImageButton: some View {
        PhotosPicker(
            selection: $selectedPhotos,
            maxSelectionCount: maxImages - selectedImages.count,
            matching: .images
        ) {
            VStack {
                Image(systemName: "plus.circle")
                    .font(.system(size: 30))
                Text("Add Photos")
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var analysisButton: some View {
        Button(action: {
            Task {
                await viewModel.analyzeImages(selectedImages)
            }
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                Text("Analyze Items")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.purple.gradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal)
        .disabled(viewModel.isAnalyzing)
    }
    
    private var photoSourceButtons: some View {
        Button(action: {
            showCamera = true
        }) {
            VStack {
                Image(systemName: "camera")
                    .font(.system(size: 30))
                Text("Take Photo")
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(selectedImages.count >= maxImages)
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gear")
            }
        }
    }
    
    private var analysisSheetContent: some View {
        Group {
            if viewModel.isAnalyzing {
                ProgressView("Analyzing items...")
                    .onAppear {
                        print("ProgressView: Analyzing items...")
                    }
            } else {
                Text("Analysis Results Placeholder")
                    .padding()
            }
        }
    }
    
    private func addImage(_ image: UIImage) {
        guard selectedImages.count < maxImages else { return }
        selectedImages.append(image)
    }
    
    private func handlePhotoSelection(newItems: [PhotosPickerItem]) {
        Task {
            for item in newItems {
                if selectedImages.count >= maxImages { break }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    addImage(image)
                }
            }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            } else {
                onImagePicked(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ContentView()
}
