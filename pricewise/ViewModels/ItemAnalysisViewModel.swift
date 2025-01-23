import Foundation
import SwiftUI

@Observable
final class ItemAnalysisViewModel {
    var isAnalyzing = false
    var analysisError: Error?
    var itemDetails: ItemDetails?
    var selectedImage: UIImage?
    
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService = OpenAIService.shared) {
        self.openAIService = openAIService
    }
    
    func analyzeImage(_ image: UIImage) async {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisError = nil
        
        do {
            let details = try await openAIService.analyzeImage(image)
            await MainActor.run {
                self.itemDetails = details
                self.selectedImage = image
                self.isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                self.analysisError = error
                self.isAnalyzing = false
            }
        }
    }
    
    func reset() {
        isAnalyzing = false
        analysisError = nil
        itemDetails = nil
        selectedImage = nil
    }
} 