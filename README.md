PriceWise iOS App

An iOS app that uses AI to analyze images of items and determine their fair market value through real-time market data scraping.
Features

Image capture and upload functionality
AI-powered item analysis using OpenAI GPT-4 Vision
Real-time market value retrieval
History tracking of analyzed items
User authentication and secure data storage

Installation

Clone the repository

bashCopygit clone https://github.com/yourusername/pricewise.git

Open the project in Xcode

bashCopycd pricewise
open pricewise.xcodeproj

Install dependencies


Add required packages in Xcode


Build and run


Select your device
Build (⌘B) and run (⌘R)

Requirements

iOS 17.0+
Xcode 15.0+
Swift 5.9+
Active Apple Developer account

Architecture

SwiftUI for UI
Firebase for backend
OpenAI GPT-4 Vision API for image analysis

Configuration

Add your API keys in Config.swift:

swiftCopystruct Config {
    static let openAIKey = "your-api-key"
    static let firebaseConfig = // your firebase config
}


License
This project is licensed under the MIT License - see the LICENSE.md file for details
