import Foundation
import SwiftUI

@Observable
class ItemAnalysisViewModel {
    // MARK: - Properties
    private let openAIService = OpenAIService.shared
    
    var selectedImage: UIImage?
    var analyzedItem: ItemDetails?
    var isAnalyzing = false
    var error: AnalysisError?
    
    // MARK: - Analysis
    func analyzeImage() async {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        error = nil
        
        do {
            analyzedItem = try await openAIService.analyzeImage(image)
        } catch let analysisError as AnalysisError {
            error = analysisError
        } catch {
            self.error = .networkError(error)
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Batch Analysis
    func analyzeImages(_ images: [UIImage]) async -> [ItemDetails] {
        isAnalyzing = true
        error = nil
        
        do {
            let results = try await openAIService.analyzeImages(images)
            isAnalyzing = false
            return results
        } catch let analysisError as AnalysisError {
            error = analysisError
            isAnalyzing = false
            return []
        } catch {
            self.error = .networkError(error)
            isAnalyzing = false
            return []
        }
    }
    
    // MARK: - Reset
    func reset() {
        selectedImage = nil
        analyzedItem = nil
        error = nil
        isAnalyzing = false
    }
} 