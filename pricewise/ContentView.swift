//
//  ContentView.swift
//  pricewise
//
//  Created by Mohamed Mohamoud on 22/01/2025.
//

import SwiftUI

struct ContentView: View {
    // MARK: - State
    @State private var viewModel = ItemAnalysisViewModel()
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        isShowingCamera = true
                    }) {
                        Label("Take Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Label("Upload Photo", systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                if viewModel.selectedImage != nil {
                    Button(action: {
                        Task {
                            await viewModel.analyzeImage()
                        }
                    }) {
                        Label("Analyze Item", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("PriceWise")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
            }
            .sheet(
                isPresented: .init(
                    get: { viewModel.isAnalyzing || viewModel.analyzedItem != nil || viewModel.error != nil },
                    set: { if !$0 { viewModel.reset() } }
                )
            ) {
                NavigationView {
                    ItemDetailsView(
                        item: viewModel.analyzedItem,
                        image: viewModel.selectedImage,
                        isLoading: viewModel.isAnalyzing,
                        error: viewModel.error,
                        onRetry: {
                            Task {
                                await viewModel.analyzeImage()
                            }
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                viewModel.reset()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
