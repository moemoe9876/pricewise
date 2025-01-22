import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var openAIKey: String = ""
    @State private var tavilyKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private let keychainManager = KeychainManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("API Keys")) {
                SecureField("OpenAI API Key", text: $openAIKey)
                    .textContentType(.password)
                    .autocapitalization(.none)
                
                SecureField("Tavily API Key", text: $tavilyKey)
                    .textContentType(.password)
                    .autocapitalization(.none)
                
                Button(action: saveAPIKeys) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save API Keys")
                    }
                }
                .disabled(openAIKey.isEmpty && tavilyKey.isEmpty)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Settings", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear(perform: loadAPIKeys)
    }
    
    private func saveAPIKeys() {
        isLoading = true
        
        do {
            if !openAIKey.isEmpty {
                try keychainManager.updateAPIKey(openAIKey, service: "openai")
            }
            
            if !tavilyKey.isEmpty {
                try keychainManager.updateAPIKey(tavilyKey, service: "tavily")
            }
            
            alertMessage = "API keys saved successfully!"
            showAlert = true
            
            // Clear the fields after successful save
            openAIKey = ""
            tavilyKey = ""
        } catch {
            alertMessage = "Failed to save API keys: \(error.localizedDescription)"
            showAlert = true
        }
        
        isLoading = false
    }
    
    private func loadAPIKeys() {
        do {
            if let openAIKey = try? keychainManager.getAPIKey(service: "openai") {
                self.openAIKey = openAIKey
            }
            
            if let tavilyKey = try? keychainManager.getAPIKey(service: "tavily") {
                self.tavilyKey = tavilyKey
            }
        }
    }
} 