import Foundation
import SwiftUI
import UIKit

@Observable final class ItemAnalysisViewModel {
    // MARK: - Properties
    private let openAIService = OpenAIService.shared
    
    var selectedImage: UIImage?
    var analyzedItems: [ItemDetails] = []
    var isAnalyzing = false
    var error: AnalysisError?
    var showResults = false
    
    // MARK: - Analysis
    func analyzeImages(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        
        isAnalyzing = true
        error = nil
        analyzedItems = []
        
        do {
            analyzedItems = try await openAIService.analyzeImages(images)
            showResults = true
        } catch let analysisError as AnalysisError {
            error = analysisError
        } catch {
            self.error = .networkError(error)
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Reset
    func reset() {
        selectedImage = nil
        analyzedItems = []
        error = nil
        isAnalyzing = false
        showResults = false
    }
} 