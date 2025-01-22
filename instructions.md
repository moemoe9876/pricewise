Okay, here is the updated full PRD for the "PriceWise" iOS app, incorporating all the suggested improvements for enhanced clarity, actionability, and completeness:

# Product Requirements Document (PRD) for "PriceWise" iOS App - v1.2 - Detailed and Improved

---

## 1. Project Overview

**PriceWise** is an iOS application designed to help users determine the fair market value of clothing items and objects using AI multimodal capabilities. The app allows users to:

- **Capture or upload images** of items.
- **Analyze items individually or in batches** using OpenAI's latest multimodal LLM `gpt-4o` with structured output.
- **Retrieve market values** from various online marketplaces using the Tavily Search API.
- **Display results** to users and allow them to edit item details.
- **Maintain a history** of analyzed items, organized by date, with totals for each day.

**Technologies Used**:

- **Frontend**: Swift (iOS)
- **Backend Services**: Firebase (Authentication, Cloud Firestore, Storage)
- **AI Services**:
    - OpenAI `gpt-4o` with structured output functions
    - Tavily Search API for market value retrieval

---

## 2. Features

1.  **Implement Image Capture and Upload Functionality**
2.  **Implement Item Analysis using Multimodal LLM (`gpt-4o`) with Batch Processing**
3.  **Implement Market Value Retrieval via Tavily Search API with Batch Processing and Rate Limiting**
4.  **Implement Display Results and User Editing Interface**
5.  **Implement History View and Logging with Firebase Firestore**
6.  **Implement User Authentication and Secure Data Storage using Firebase**
7.  **Implement Batch Processing of Multiple Items Workflow**

---

## 3. Requirements for Each Feature

### **Feature 1: Implement Image Capture and Upload Functionality**

**Description**: Allow users to take photos or upload existing images of items.

**Requirements**:

- **1.1. Implement Camera Access for Image Capture**:
    - **UI Element**: A button labeled `takePhotoButton` in the main view (`CameraViewController`).
    - **Action**: On button tap, initiate device camera access.
    - **Permission**: Request camera permission from the user if not already granted (using `Info.plist` configuration and permission request code). Keys: `NSCameraUsageDescription`.
    - **Camera View**: Display a live camera preview in a designated `UIView` (`cameraPreviewView`).
    - **Capture Button**: A button within the camera view to trigger image capture (`captureButton`).
    - **Image Capture Action**: On `captureButton` tap, capture a high-resolution still image from the camera preview.
    - **User Flow**: User taps "Take Photo" -> Camera view appears -> User captures image -> Image is ready for processing.

    ```swift
    let takePhotoButton = UIButton(type: .system)
    takePhotoButton.setTitle("Take Photo", for: .normal)
    takePhotoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
    ```

- **1.2. Implement Photo Library Upload for Image Selection**:
    - **UI Element**: A button labeled `uploadPhotoButton` (or icon) for accessing the photo library.
    - **Action**: On button tap, present the device's photo library to the user using `UIImagePickerController`.
    - **Selection**: Allow the user to select one or more images (for the same item - for batch processing). Enable `allowsMultipleSelection` in `UIImagePickerController`.
    - **Image Handling**: Upon image selection, retrieve the `UIImage` data for each selected image.
    - **User Flow**: User taps "Upload Photos" -> Photo library appears -> User selects image(s) -> Selected image(s) are ready for processing.

    ```swift
    let uploadPhotoButton = UIButton(type: .system)
    uploadPhotoButton.setTitle("Upload Photos", for: .normal)
    uploadPhotoButton.addTarget(self, action: #selector(uploadPhotos), for: .touchUpInside)
    ```

- **1.3. Implement Optimized Image Handling**:
    - **Supported Formats**: Support image formats: JPEG (preferred for upload efficiency), PNG.
    - **Image Compression**: Ensure images are compressed to an optimal size for faster uploads without significant loss of quality. Target compressed image size: Under 500KB (ideally). Use `compressionQuality: 0.6-0.8` for JPEG compression.

    ```swift
    func compressImage(_ image: UIImage) -> Data? {
        let compressionQuality: CGFloat = 0.7 // Target quality level for compression
        return image.jpegData(compressionQuality: compressionQuality)
    }
    ```

    - **Temporary Storage**: Store selected images temporarily in a variable `itemImages: [UIImage]` - Array to store images selected by the user for processing.

    ```swift
    var itemImages: [UIImage] = [] // Array to store images selected by the user for processing.
    ```

**Dependencies**:

- **Frameworks**:
    - UIKit or SwiftUI for UI components.
    - Photos framework for image access.
- **Permissions**:
    - Request camera and photo library access in `Info.plist`. Keys: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.

    ```xml
    <key>NSCameraUsageDescription</key>
    <string>This app requires access to the camera to take photos of items.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app requires access to the photo library to select images of items.</string>
    ```

---

### **Feature 2: Implement Item Analysis using Multimodal LLM (`gpt-4o`) with Batch Processing**

**Description**: Send the item images to OpenAI's multimodal LLM `gpt-4o` to extract item details with structured output. Support batch processing of items for efficiency.

**Requirements**:

- **2.1. Integrate OpenAI `gpt-4o` API for Item Analysis**:
    - **API Integration**: Utilize OpenAI's `gpt-4o` model with structured output functions.
    - **API Endpoint**: `https://api.openai.com/v1/chat/completions`
    - **API Key Security**: **API key (`openAIApiKey: String`) MUST be stored securely in iOS Keychain.** Do not store API keys directly in code or UserDefaults.
    - **Data Extraction**: Extract the following details based on the provided JSON schema in a structured format.
        - `brand`: String (Brand name of the item)
        - `product_name`: String (nullable) (Specific product name, if identifiable)
        - `barcode`: String (nullable) (Barcode number, if detected)
        - `condition`: String (enum: ["new", "like_new", "good", "fair", "poor"], nullable) (Condition of the item)
        - `sizes`: Array of Strings (nullable) (Sizes available, if applicable)
    - **Image Encoding**: Convert `UIImage` to base64-encoded strings (JPEG format preferred).

    ```swift
    func encodeImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
        return imageData.base64EncodedString()
    }
    ```

- **2.2. Implement Batch Processing for OpenAI API Requests**:
    - **Batch Support**: Support sending multiple images (for different items) in a single API request to `gpt-4o` for efficiency.
    - **API Request Structure for Batch Processing**: (As detailed in the previous PRD version - ensure correct JSON structure and prompt). Refer to code example below for `batchMessages` construction.
    - **Swift Code for Batch API Call**: (As detailed in the previous PRD version - ensure correct function structure, error handling, and JSON parsing). See code example below.
    - **Error Handling - OpenAI API Specific Errors**: Implement robust error handling for OpenAI API calls. Anticipate and handle errors such as:
        - `invalid_api_key`: Prompt user to check their API key setup.
        - `rate_limit_exceeded`: Implement exponential backoff retry logic.
        - `model_error`: Log the error for debugging and potentially inform the user of a temporary AI service issue.
        - `network_error`: Display a user-friendly "Network Error" message and suggest checking internet connection.
    - **Response Format - Example Success/Failure**: Provide example JSON responses for both successful metadata extraction and API error cases in API Contract section (Section 5).

    ```swift
    var batchMessages: [[String: Any]] = [] // Array to build messages for batch OpenAI API call

    for image in itemImages {
        if let base64Image = encodeImageToBase64(image) {
            let message: [String: Any] = [
                "role": "user",
                "content": [
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
            batchMessages.append(message)
        }
    }
    ```

    ```swift
```swift
    func analyzeItemsWithOpenAI(images: [UIImage], completion: @escaping (Result<[ItemDetails], Error>) -> Void) {
        var batchMessages: [[String: Any]] = []

        for image in images {
            if let base64Image = encodeImageToBase64(image) {
                let message: [String: Any] = [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ]
            batchMessages.append(message)
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API Endpoint URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Response format for structured output using JSON Schema as defined in PRD
        let responseFormat: [String: Any] = [
            "type": "json_schema",
            "json_schema": [
              "name": "clothing_product_identifier",
              "strict": true,
              "schema": [
                "type": "object",
                "properties": [
                  "metadata": [
                    "type": "object",
                    "description": "Metadata related to the identified clothing or product.",
                    "properties": [
                      "brand": [
                        "type": "string",
                        "description": "The name of the brand associated with the item."
                      ],
                      "product_name": [
                        "type": "string",
                        "nullable": true
                      ],
                      "barcode": [
                        "type": "string",
                        "nullable": true
                      ],
                      "condition": [
                        "type": "string",
                        "enum": [
                          "new",
                          "like_new",
                          "good",
                          "fair",
                          "poor"
                        ],
                        "nullable": true
                      ],
                      "sizes": [
                        "type": "array",
                        "items": [
                          "type": "string"
                        ],
                        "nullable": true
                      ]
                    ],
                    "required": [
                      "brand"
                    ],
                    "additionalProperties": false
                  ]
                ],
                "required": [
                  "metadata"
                ],
                "additionalProperties": false
              ]
            ]
          ]
        ]


        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": batchMessages,
            "response_format": responseFormat, // Include the response format here
            "temperature": 1,
            "max_completion_tokens": 2048,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error)) // JSON Serialization error
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error)) // Network error
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from OpenAI API."]))) // No data error
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BatchOpenAIResponse.self, from: data)
                let itemDetailsList = response.toItemDetailsList()
                completion(.success(itemDetailsList)) // Success with ItemDetails list
            } catch {
                completion(.failure(error)) // JSON Decoding error
            }
        }
        task.resume()
    }
    ```

```swift
    struct BatchOpenAIResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]

        func toItemDetailsList() -> [ItemDetails] {
            var itemDetailsList: [ItemDetails] = []
            for choice in choices {
                do {
                    if let contentData = choice.message.content.data(using: .utf8) {
                        let decodedResponse = try JSONDecoder().decode([String: [String:  [String:  [String: String?]]]] .self, from: contentData)


                        if let metadataDict = decodedResponse["metadata"] as? [String: Any],
                           let brand = metadataDict["brand"] as? String {


                            let productName = metadataDict["product_name"] as? String
                            let barcode = metadataDict["barcode"] as? String
                            let condition = metadataDict["condition"] as? String
                            let sizesArray = metadataDict["sizes"] as? [String]

                            let metadata = ItemDetails.Metadata(brand: brand, product_name: productName, barcode: barcode, condition: condition, sizes: sizesArray)
                            let itemDetail = ItemDetails(metadata: metadata)
                            itemDetailsList.append(itemDetail)
                        }
                    }
                } catch {
                    print("Error decoding JSON for a choice: \(error)")
                    // Handle decoding error for individual choice, e.g., append a default ItemDetails or skip
                    // For now, skipping item in case of decode error
                }
            }
            return itemDetailsList
        }
    }
    ```

```swift
    struct ItemDetails: Codable, Identifiable {
        var id: UUID = UUID()
        struct Metadata: Codable {
            var brand: String
            var product_name: String?
            var barcode: String?
            var condition: String?
            var sizes: [String]?
        }
        var metadata: Metadata
        var market_value: Double?
        var date_analyzed: Date = Date()
        var image_url: String? // URL to image stored in Firebase Storage (optional for MVP)
        var image: UIImage? // Local UIImage reference (not stored in Firestore)

        // Example initializer for easier ItemDetails object creation
        init(brand: String, product_name: String? = nil, barcode: String? = nil, condition: String? = nil, sizes: [String]? = nil, market_value: Double? = nil, image: UIImage? = nil, image_url: String? = nil) {
            self.metadata = Metadata(brand: brand, product_name: product_name, barcode: barcode, condition: condition, sizes: sizes)
            self.market_value = market_value
            self.image = image
            self.image_url = image_url
        }
    }
```

**Key points in the code:**

*   **`analyzeItemsWithOpenAI` function**: Includes URL construction, request setup with headers and body (using `batchMessages` and `responseFormat`). Error handling for network errors, no data, and JSON serialization/decoding errors are in place, calling the `completion` handler with `Result`.
*   **`BatchOpenAIResponse` struct**: Defines the structure to decode the JSON response from OpenAI's API. The `toItemDetailsList()` function now iterates through `choices`, attempts to decode the `content` of each message into `ItemDetails`, and handles potential decoding errors for individual choices gracefully (by skipping the item in case of error and printing an error message).
*   **`ItemDetails` struct**:  The `ItemDetails` struct definition from the PRD is provided for completeness.

**Remember to:**

*   Replace `"YOUR_API_KEY"` placeholder with your actual OpenAI API key, and ensure it's securely stored in the Keychain as emphasized in the PRD.
*   Adapt the JSON parsing logic within `toItemDetailsList()` if the actual OpenAI API response structure differs slightly. You might need to adjust the decoding based on the real-world API response you receive.
*   Implement proper error handling in your UI to display user-friendly messages based on the different error cases handled in the `analyzeItemsWithOpenAI` function (network errors, API errors, decoding errors).

This code should provide a solid starting point for implementing the OpenAI API integration for batch item analysis in your PriceWise app.
    ```

- **2.4. Variable Names**:
    - `openAIApiKey: String` (Your OpenAI API key, **MUST be stored securely in Keychain**)
    - `itemImages: [UIImage]` (Array of selected item images)
    - `extractedItemDetailsList: [ItemDetails]` (Array to store extracted item details from OpenAI API)
    - `visionAnalysisResponse: GeminiVisionResponse?` (Variable to hold the response from Gemini Vision API -  *(Note: Variable name from previous PRD version, update to `openAIAnalysisResponse` for clarity if needed)*)

**Dependencies**:

- **Networking**:
    - Use `URLSession` for API calls.
- **Data Models**:
    - Define `ItemDetails` and `BatchOpenAIResponse` structs as shown in Data Models section (Section 4).
- **Error Handling**: Implement comprehensive error handling for API failures.

---

### **Feature 3: Implement Market Value Retrieval via Tavily Search API with Batch Processing and Rate Limiting**

**Description**: Use the extracted item details to find items' current market values from online marketplaces using the Tavily Search API. Implement batch processing and rate limiting for efficient and reliable value retrieval.

**Requirements**:

- **3.1. Integrate Tavily Search API for Market Value Retrieval**:
    - **API Integration**: Use the Tavily Search API to perform web searches and extract market value information.
    - **API Endpoint**: `https://api.tavily.com/search`
    - **API Key Security**: API key (`tavilyApiKey: String`) **MUST be stored securely in iOS Keychain.** Do not store API keys directly in code or UserDefaults.

- **3.2. Implement Batch Processing for Tavily API Calls**:
    - **Batch Support**: Construct search queries for each item and send them in parallel or sequentially, considering API rate limits.
    - **API Request Structure**: (As detailed in previous PRD version - ensure correct JSON structure and query parameter). Refer to code example below for `constructSearchQuery` and request body.
    - **Swift Code for Batch API Calls**: (As detailed in previous PRD version - ensure correct function structure, DispatchGroup usage for concurrency, error handling, and JSON parsing). See code example below.

    ```swift
    func constructSearchQuery(from details: ItemDetails) -> String {
        var query = "What is the average selling price of a "

        if let condition = details.metadata.condition {
            query += "\(condition) condition "
        } else {
            query += "used " // Default to "used" if condition is not available
        }

        if let brand = details.metadata.brand {
            query += "\(brand) "
        }

        if let productName = details.metadata.product_name {
            query += "\(productName) "
        } else {
            query += "\(details.metadata.itemType ?? "item") " // Fallback to itemType if product_name is missing, or just "item"
        }

        if let sizes = details.metadata.sizes, !sizes.isEmpty {
            query += "size\(sizes.count > 1 ? "s" : ""): \(sizes.joined(separator: ", ")) "
        }

        query += "on eBay, Amazon, and Facebook Marketplace?" // Target marketplaces

        return query
    }
    ```

```swift
    func retrieveMarketValues(for items: [ItemDetails], completion: @escaping (Result<[Double?], Error>) -> Void) {
        let group = DispatchGroup()
        var marketValues: [Double?] = Array(repeating: nil, count: items.count) // Initialize with nil for each item
        var errors: [Error] = []

        for (index, item) in items.enumerated() {
            group.enter()
            let query = constructSearchQuery(from: item)

            retrieveMarketValue(with: query) { result in
                defer { group.leave() } // Ensure group.leave() is always called

                switch result {
                case .success(let marketValue):
                    marketValues[index] = marketValue // Assign market value to the correct index
                case .failure(let error):
                    errors.append(error)
                    print("Error retrieving market value for item \(index): \(error.localizedDescription)") // Log individual item error
                    // marketValues[index] remains nil, indicating failure for this item
                }
            }
        }

        group.notify(queue: .main) {
            if !errors.isEmpty {
                completion(.failure(errors.first!)) // Return the first error if any occurred
            } else {
                completion(.success(marketValues)) // Return array of market values (some might be nil if individual lookups failed)
            }
        }
    }


    private func retrieveMarketValue(with query: String, completion: @escaping (Result<Double?, Error>) -> Void) {
        guard let url = URL(string: "https://api.tavily.com/search") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Tavily API Endpoint URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(tavilyApiKey)", forHTTPHeaderField: "Authorization") // Secure API Key

        let requestBody: [String: Any] = ["query": query]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error)) // JSON serialization error
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error)) // Network error
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let errorMessage = "Tavily API request failed with status code: \(statusCode)"
                completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))) // API error status code
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from Tavily API."]))) // No data error
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                // Basic parsing - adapt based on actual Tavily API response structure in API Contract
                if let results = jsonResponse?["results"] as? [[String: Any]], !results.isEmpty {
                    // For MVP, take the first result's content and try to extract a price (very basic)
                    if let firstResultContent = results[0]["content"] as? String {
                        let price = extractPriceFromContent(firstResultContent) // Implement price extraction logic
                        completion(.success(price)) // Success with extracted price (could be nil if not found)
                        return
                    }
                }
                completion(.success(nil)) // No price found in results, but API call was successful
            } catch {
                completion(.failure(error)) // JSON decoding error
            }
        }
        task.resume()
    }


    private func extractPriceFromContent( _ content: String) -> Double? {
        // Implement more sophisticated price extraction logic based on Tavily API response content.
        // This is a very basic example - improve based on real-world Tavily responses and desired accuracy.
        let priceRegex = try? NSRegularExpression(pattern: "\\$\\d+(\\.\\d{2})?", options: .caseInsensitive) // Basic regex for $USD prices
        if let match = priceRegex?.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) {
            let priceString = String(content[Range(match.range, in: content)!])
            return Double(priceString.trimmingCharacters(in: CharacterSet.nonBaseCharacters).replacingOccurrences(of: "$", with: "")) // Remove $ and convert to Double
        }
        return nil // Price not found
    }
    ```

- **3.3. Implement Rate Limiting for Tavily API**:
    - **Rate Limiting:** Be mindful of Tavily API rate limits. Implement a rate limiting strategy to avoid exceeding limits and causing API blocks. A simple strategy is to introduce a delay between API calls in batch processing or use a request queue.
    - **Error Handling - Tavily API Specific Errors**: Implement robust error handling for Tavily API calls. Anticipate and handle errors such as:
        - `429 Too Many Requests`: Implement exponential backoff retry logic.
        - `invalid_api_key`: Prompt user to check their API key setup.
        - `network_error`: Display a user-friendly "Network Error" message.

- **3.4. Variable Names**:
    - `tavilyApiKey: String` (Your Tavily API key, **MUST be stored securely in Keychain**)
    - `constructedQueries: [String]` (Array to store constructed search queries)
    - `marketValues: [Double]` (Array to store retrieved market values)

**Dependencies**:

- **Networking**:
    - Use `URLSession` to make API calls to Tavily.
- **Data Parsing**:
    - Use `JSONSerialization` to parse the JSON response.
- **Concurrency**: Implement concurrency using `DispatchGroup` (or similar) for efficient batch processing.

**Error Handling**: Implement comprehensive error handling, including rate limit management and user feedback for errors.

---

### **Feature 4: Implement Display Results and User Editing Interface**

**Description**: Present the extracted item details and market values in a user-friendly interface. Allow users to review, edit, and recalculate market values.

**Requirements**:

- **4.1. Implement Display of Item Details and Market Values**:
    - **UI Display**: Use a `UITableView` or SwiftUI `List` to display a list of processed items.
    - **Item List Display**: Each item in the list should visually present:
        - Item image (`UIImageView` or `Image` in SwiftUI, `itemImageView`)
        - Brand name (`brandLabel: UILabel` or `Text` in SwiftUI)
        - Product name (`productNameLabel: UILabel` or `Text` in SwiftUI)
        - Barcode (`barcodeLabel: UILabel` or `Text` in SwiftUI)
        - Sizes (`sizesLabel: UILabel` or `Text` in SwiftUI)
        - Condition (`conditionLabel: UILabel` or `Text` in SwiftUI)
        - Market Value (`marketValueLabel: UILabel` or `Text` in SwiftUI)
    - **UI Update - Loading Indicator**: When fetching market values or recalculating, display a `loadingIndicator: UIActivityIndicatorView` to inform the user of background activity.

    ```swift
    // Example using SwiftUI List (Conceptual)
    List {
        ForEach(items) { item in
            HStack {
                Image(uiImage: item.image) // item.image is a UIImage
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text("Brand: \(item.metadata.brand)") // Access metadata from ItemDetails struct
                    Text("Product: \(item.metadata.product_name ?? "N/A")")
                    Text("Market Value: $\(item.market_value ?? 0.0)")
                }
            }
        }
    }
    ```

- **4.2. Implement User Editing of Item Details**:
    - **Editable Fields**: Allow users to tap on an item to navigate to a detail view for editing. Editable fields in the detail view should include:
        - Brand ( `brandTextField: UITextField` or `TextField` in SwiftUI)
        - Product Name (`productNameTextField: UITextField` or `TextField` in SwiftUI)
        - Barcode (`barcodeTextField: UITextField` or `TextField` in SwiftUI)
        - Sizes (`sizesTextField: UITextField` or Tag/Token field for sizes - potentially a custom component or library)
        - Condition (`conditionPicker: UIPickerView` or `Picker` in SwiftUI using the condition enum values)
    - **Validation Rules**: Implement client-side validation in the detail view to ensure:
        - Brand and Product Name fields are mandatory.
        - Condition must be selected from the predefined enum values (["new", "like_new", "good", "fair", "poor"]).
    - **Data Persistence - Local & Firebase (Future Iteration - MVP Focus on Local Editing)**: For MVP, focus on local editing within the current app session. Data persistence to Firebase for edited values will be a future enhancement.

- **4.3. Implement Market Value Recalculation**:
    - **Recalculate Button**: Provide a "Recalculate Value" button (`recalculateValueButton: UIButton` or `Button` in SwiftUI) in the item detail view.
    - **Recalculation Trigger**: On `recalculateValueButton` tap:
        - Display `loadingIndicator` to show processing.
        - Trigger Feature 3 (Market Value Retrieval) again, using the *edited* item details from the UI.
        - Update the `marketValueLabel` in the detail view with the newly fetched market value.
    - **UI Update - Loading Indicator during Recalculation**: Display `loadingIndicator` while fetching the new market value and hide it once the update is complete.

- **4.4. Variable Names**:
    - `itemListView: UITableView` or `List` in SwiftUI (For displaying item list)
    - `brandLabel: UILabel` or `Text` (For brand display)
    - `productNameLabel: UILabel` or `Text` (For product name display)
    - `barcodeLabel: UILabel` or `Text` (For barcode display)
    - `sizesLabel: UILabel` or `Text` (For sizes display)
    - `conditionLabel: UILabel` or `Text` (For condition display)
    - `marketValueLabel: UILabel` or `Text` (For market value display)
    - `brandTextField: UITextField` or `TextField` (For brand editing)
    - `productNameTextField: UITextField` or `TextField` (For product name editing)
    - `barcodeTextField: UITextField` or `TextField` (For barcode editing)
    - `sizesTextField: UITextField` or Tag/Token field (For sizes editing)
    - `conditionPicker: UIPickerView` or `Picker` (For condition selection)
    - `recalculateValueButton: UIButton` or `Button` (For triggering recalculation)
    - `loadingIndicator: UIActivityIndicatorView` (For loading indication)

**Dependencies**:

- **UI Components**: UIKit or SwiftUI components (labels, text fields, buttons, pickers, lists, activity indicators).
- **Data Binding**: Mechanisms for updating UI elements with data changes (e.g., SwiftUI state management, UIKit data source/delegate patterns).
- **Validation**: Logic for validating user input in edit views.

---

### **Feature 5: Implement History View and Logging with Firebase Firestore**

**Description**: Maintain a log of all analyzed items, stored in Firebase Firestore, with a history view organized by date and daily summaries.

**Requirements**:

- **5.1. Implement Data Storage in Firebase Cloud Firestore**:
    - **Data Storage**: Use Firebase Cloud Firestore to store `AnalyzedItem` data.
    - **Data Model - `AnalyzedItem` Class (Firebase Model)**: Define `AnalyzedItem` data model (as detailed in Data Models section - Section 4) for storing data in Firestore.
    - **Collection Structure**: Store data in a Firestore collection named `analyzedItems` under each user's document (user ID as document ID). Nested collection structure example: `users/{userId}/analyzedItems/{itemId}`.
    - **Data Fields in Firestore**: Store the following fields for each `AnalyzedItem`:
        - `metadata`: Map (containing brand, product_name, barcode, condition, sizes from `ItemDetails.Metadata`)
        - `market_value`: Number (Double)
        - `date_analyzed`: Timestamp (Firestore Timestamp)
        - `image_url`: String (URL to image stored in Firebase Storage - *Future Enhancement for MVP, may skip image saving to Firebase Storage for initial MVP if it simplifies development*)
    - **Firebase Security Rules**: **Define and implement Firebase Security Rules for Firestore to ensure that only authenticated users can access and modify their own data.** Rules should prevent unauthorized access and ensure data integrity.

    ```swift
    struct AnalyzedItem: Codable, Identifiable {
        var id: String // Document ID in Firestore (auto-generated by Firestore)
        var metadata: ItemDetails.Metadata // Metadata, reusing the nested Metadata struct
        var market_value: Double? // Market value
        var date_analyzed: Timestamp // Firestore Timestamp for analysis date
        var image_url: String? // URL to image in Firebase Storage (optional for MVP)

        // Default initializer (required for Codable in some cases)
        init(id: String = UUID().uuidString, metadata: ItemDetails.Metadata, market_value: Double?, date_analyzed: Timestamp, image_url: String?) {
            self.id = id
            self.metadata = metadata
            self.market_value = market_value
            self.date_analyzed = date_analyzed
            self.image_url = image_url
        }

        // CodingKeys to map Swift property names to Firestore field names (if needed, for customization)
        enum CodingKeys: String, CodingKey {
            case id
            case metadata
            case market_value = "marketValue" // Example of mapping market_value to marketValue in Firestore
            case date_analyzed = "dateAnalyzed" // Example of mapping date_analyzed to dateAnalyzed in Firestore
            case image_url = "imageUrl" // Example of mapping image_url to imageUrl in Firestore
        }
    }
    ```

- **5.2. Implement History View Interface**:
    - **History View UI**: Display a history view in the app's homepage or a dedicated "History" tab.
    - **Date List Display**: Display a list of dates in a `UITableView` or SwiftUI `List` (`historyDateListView`). Each cell should represent a date with a summary of items priced on that date (e.g., number of items, total market value).
    - **Date Selection**: Allow users to select a date (`selectedDate: Date`) from the list to view detailed item logs for that day.
    - **Daily Item List**: When a date is selected, display a detailed list of `AnalyzedItem` objects priced on that `selectedDate` in a separate view or section (`dailyItemListView`). Use a similar UI as in Feature 4 to display item details.
    - **Daily Total Value**: Display the total market value for all items priced on the `selectedDate` (`dailyTotalValueLabel: UILabel` or `Text` in SwiftUI) in the date-selected view.
    - **Data Querying and Display - Efficiency**: For the History View, implement efficient querying of Firestore data, potentially using pagination or date-range queries to handle large datasets and ensure smooth scrolling performance.

- **5.3. Implement Item Logging Functionality**:
    - **Logging on Save**: When a user "saves" a priced item (in Feature 4, or automatically after pricing in batch processing), save the `AnalyzedItem` data to Firestore under the current user's ID. Include all relevant data: `metadata`, `market_value`, `date_analyzed`, and `image_url` (if image saving to Firebase Storage is implemented).

- **5.4. Variable Names**:
    - `historyItems: [AnalyzedItem]` (Array to hold history items for display)
    - `dailyItems: [AnalyzedItem]` (Array to hold items for a selected date)
    - `selectedDate: Date` (Currently selected date in history view)
    - `dailyTotalValueLabel: UILabel` or `Text` (For displaying daily total market value)
    - `historyDateListView: UITableView` or `List` (For displaying list of dates in history)
    - `dailyItemListView: UITableView` or `List` (For displaying list of items for a selected date)

**Dependencies**:

- **Firebase Integration**: Firebase SDKs (Firebase Firestore).
- **Data Models**: `AnalyzedItem` data model.
- **UI Components**: UIKit or SwiftUI components for lists, labels, date pickers (if date filtering/selection is more advanced).
- **Authentication**: Feature 6 (User Authentication) must be implemented to associate data with users.

---

### **Feature 6: Implement User Authentication and Secure Data Storage using Firebase**

**Description**: Implement user authentication using Firebase Authentication and secure data storage in Firebase Cloud Firestore and Storage.

**Requirements**:

- **6.1. Implement User Authentication with Firebase Authentication**:
    - **Authentication Methods - MVP Scope**: For MVP, focus on email/password authentication. Social logins (Google, Facebook, Apple ID) can be considered for future iterations.
    - **User Interface**: Create dedicated screens or modal views for:
        - User registration (`RegistrationViewController` or SwiftUI View) with fields for email and password. Implement email validation and strong password requirements.
        - User login (`LoginViewController` or SwiftUI View) with fields for email and password.
        - "Forgot Password" functionality (using Firebase Authentication's password reset flow).
        - "Logout" functionality in the app's settings or profile section.
    - **Firebase Authentication Integration**: Use Firebase Authentication SDK to handle user creation, login, logout, and password management.
    - **Authentication State Management**: Implement logic to manage user authentication state within the app. Check for user login status on app launch and redirect to login screen if not authenticated.
    - **Secure API Key Storage**:  Ensure Firebase configuration files (e.g., `GoogleService-Info.plist`) are properly secured and not exposed in the codebase.

- **6.2. Secure Data Storage in Firebase**:
    - **Firebase Cloud Firestore**: Use Firestore to store structured data, including `AnalyzedItem` data, user profiles (if needed beyond basic auth user info), and history logs.
    - **Firebase Storage** (*Future Enhancement for MVP - Optional for initial MVP*): For future iterations, if image saving to Firebase Storage is implemented, use Firebase Storage to store item images. Store URLs to images in Firestore `AnalyzedItem` documents. For MVP, you might skip image saving to Firebase Storage to simplify initial development and focus on metadata and pricing data.
    - **Firebase Security Rules**: **Firebase Security Rules MUST be defined and implemented for both Firestore and Storage (if used) to enforce data access control and security.** Rules should ensure that users can only access and modify their own data and prevent unauthorized access or data breaches.

- **6.3. Variable Names**:
    - `auth: Auth = Auth.auth()` (Firebase Auth instance)
    - `databaseRef: Firestore = Firestore.firestore()` (Firestore database reference)
    - `storageRef: StorageReference = Storage.storage().reference()` (Firebase Storage reference - if Firebase Storage is used for image saving)
    - `currentUser: User? = Auth.auth().currentUser` (Variable to track currently logged-in user)

**Dependencies**:

- **Firebase SDKs**:
    - Firebase Authentication (`FirebaseAuth`)
    - Firebase Cloud Firestore (`FirebaseFirestore`)
    - Firebase Storage (`FirebaseStorage` - if image saving to Firebase Storage is implemented)
- **UI Components**: UIKit or SwiftUI components for login/registration forms, alerts, etc.
- **Data Validation**: Input validation for email and password fields.
- **Keychain**: iOS Keychain Services for secure API key storage (though Firebase SDK handles user credentials securely).

---

### **Feature 7: Implement Batch Processing of Multiple Items Workflow**

**Description**: Orchestrate the workflow for batch processing of multiple items, ensuring a seamless user experience and efficient handling of API calls and data.

**Requirements**:

- **7.1. Enhance Image Selection for Batch Input**:
    - **Multiple Image Selection**:  Ensure that the "Image Capture and Upload" feature (Feature 1) allows users to select multiple images at once from the photo library. Use `UIImagePickerController`'s `allowsMultipleSelection = true` or a custom multi-image selection component.
    - **Visual Cues for Batch Processing**:  Enhance the UI to visually indicate batch processing mode. This could include:
        - Displaying a counter showing "Items Selected: X" during image selection.
        - Using a distinct UI element or label to indicate "Batch Processing Mode" is active.
        - Displaying thumbnails of selected images in a preview area before processing begins.

- **7.2. Orchestrate Batch API Calls for OpenAI and Tavily**:
    - **Sequential Workflow**: Implement a workflow that sequentially calls the OpenAI API (Feature 2) for batch analysis *first*, and then, upon successful AI analysis for all items, triggers the Tavily API calls (Feature 3) for market value retrieval for *all* items.
    - **Data Flow Management**: Ensure proper data flow between features. Pass the `extractedItemDetailsList` from Feature 2 as input to Feature 3 for market value retrieval.
    - **Concurrency Strategy for Tavily API in Batch**: Since Tavily API might not support direct batch queries, use concurrency (e.g., `DispatchGroup`) to send Tavily API requests for multiple items in parallel to improve performance. Rationale: `DispatchGroup` is chosen for managing concurrent Tavily API requests because it allows waiting for all requests to complete before proceeding to the next step (UI update) and provides mechanisms for error aggregation.

- **7.3. Implement Batch Processing Progress Indication**:
    - **Progress Indicator**:  Display a progress indicator (`UIProgressView` or custom progress UI) during batch processing to show users the progress of item analysis and market value retrieval.
    - **Progress Updates**: Update the progress indicator as each item is analyzed by OpenAI and as market values are retrieved by Tavily. Display progress as "Analyzing Item X of Y", "Retrieving Value for Item X of Y", or a percentage-based progress.

- **7.4. Implement Error Handling for Batch Workflow**:
    - **Individual Item Error Handling**: If API calls fail for a *specific item* during batch processing (either OpenAI or Tavily API), the app should gracefully handle the error *for that item* and continue processing the remaining items in the batch. Do not halt the entire batch process due to a single item error.
    - **Error Reporting for Individual Items**:  In the UI, provide visual cues or error messages *specifically for items* that failed processing in the batch. This could be an error icon next to the item in the list, or a summary error message at the end indicating "X out of Y items processed successfully. Errors occurred for items: [Item Names/Indices]". Allow users to retry processing failed items individually if possible.
    - **Overall Batch Error Summary**: If a critical error occurs that prevents batch processing from completing at all (e.g., network failure, authentication error), display a general error message to the user explaining the issue and suggesting troubleshooting steps (e.g., "Batch processing failed due to a network error. Please check your internet connection and try again.").

- **7.5. Variable Names**:
    - `batchItemDetails: [ItemDetails]` (Array to hold item details during batch processing)
    - `batchProgressView: UIProgressView` or Custom Progress UI (For displaying batch processing progress)
    - `batchProcessingStatusLabel: UILabel` or `Text` (For displaying status messages during batch processing)

**Dependencies**:

- **Concurrency**: `DispatchGroup` (or similar concurrency mechanisms like `OperationQueue`, Swift Concurrency `async/await` if targeting iOS 15+).
- **UI Components**: Progress indicators, labels, lists to display batch processing status and individual item errors.
- **Features 2 & 3**:  Batch processing workflow depends on the successful implementation of Feature 2 (OpenAI Batch Analysis) and Feature 3 (Tavily Batch Value Retrieval).

---

## 4. Data Models

### **ItemDetails Struct**

```swift
struct ItemDetails: Codable, Identifiable {
    var id: UUID = UUID() // Unique identifier for each item
    struct Metadata: Codable { // Nested struct for item metadata
        var brand: String // Brand name
        var product_name: String? // Product name (optional)
        var barcode: String? // Barcode (optional)
        var condition: String? // Condition (optional, enum: ["new", "like_new", "good", "fair", "poor"])
        var sizes: [String]? // Sizes (optional, array of strings)
    }
    var metadata: Metadata // Property to hold item metadata
    var market_value: Double? // Market value of the item (optional initially)
    var date_analyzed: Date = Date() // Date and time of analysis, default to current date
    var image_url: String? // URL to image stored in Firebase Storage (optional for MVP)
    var image: UIImage? // Local UIImage reference (not stored in Firestore)

    // Example initializer for easier ItemDetails object creation
    init(brand: String, product_name: String? = nil, barcode: String? = nil, condition: String? = nil, sizes: [String]? = nil, market_value: Double? = nil, image: UIImage? = nil, image_url: String? = nil) {
        self.metadata = Metadata(brand: brand, product_name: product_name, barcode: barcode, condition: condition, sizes: sizes)
        self.market_value = market_value
        self.image = image
        self.image_url = image_url
    }
}
```

### **AnalyzedItem Struct (Firebase Model)**

```swift
struct AnalyzedItem: Codable, Identifiable {
    var id: String // Document ID in Firestore (auto-generated by Firestore)
    var metadata: ItemDetails.Metadata // Metadata, reusing the nested Metadata struct
    var market_value: Double? // Market value
    var date_analyzed: Timestamp // Firestore Timestamp for analysis date
    var image_url: String? // URL to image in Firebase Storage (optional for MVP)

    // Default initializer (required for Codable in some cases)
    init(id: String = UUID().uuidString, metadata: ItemDetails.Metadata, market_value: Double?, date_analyzed: Timestamp, image_url: String?) {
        self.id = id
        self.metadata = metadata
        self.market_value = market_value
        self.date_analyzed = date_analyzed
        self.image_url = image_url
    }

    // CodingKeys to map Swift property names to Firestore field names (if needed, for customization)
    enum CodingKeys: String, CodingKey {
        case id
        case metadata
        case market_value = "marketValue" // Example of mapping market_value to marketValue in Firestore
        case date_analyzed = "dateAnalyzed" // Example of mapping date_analyzed to dateAnalyzed in Firestore
        case image_url = "imageUrl" // Example of mapping image_url to imageUrl in Firestore
    }
}
```

---

## 5. API Contracts

### **5.1. API 1: Multimodal LLM Image Analysis (OpenAI `gpt-4o`)**

- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Method**: `POST`
- **Headers**:

    ```http
    Authorization: Bearer {openAIApiKey}
    Content-Type: application/json
    ```

- **Request Body (JSON Example for Batch Processing - Adapt to actual API format and Prompt):**

    ```json
    {
      "model": "gpt-4o",
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,BASE64_ENCODED_IMAGE_DATA_1_HERE"
              }
            }
          ]
        },
        {
          "role": "user",
          "content": [
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,BASE64_ENCODED_IMAGE_DATA_2_HERE"
              }
            }
          ]
        }
      ],
      "response_format": {
        "type": "json_schema",
        "json_schema": {
          "name": "clothing_product_identifier",
          "strict": true,
          "schema": {
            "type": "object",
            "properties": {
              "metadata": {
                "type": "object",
                "description": "Metadata related to the identified clothing or product.",
                "properties": {
                  "brand": {
                    "type": "string",
                    "description": "The name of the brand associated with the item."
                  },
                  "product_name": {
                    "type": "string",
                    "nullable": true
                  },
                  "barcode": {
                    "type": "string",
                    "nullable": true
                  },
                  "condition": {
                    "type": "string",
                    "enum": [
                      "new",
                      "like_new",
                      "good",
                      "fair",
                      "poor"
                    ],
                    "nullable": true
                  },
                  "sizes": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    },
                    "nullable": true
                  }
                },
                "required": [
                  "brand"
                ],
                "additionalProperties": false
              }
            },
            "required": [
              "metadata"
            ],
            "additionalProperties": false
          }
        }
      },
      "temperature": 1,
      "max_completion_tokens": 2048,
      "top_p": 1,
      "frequency_penalty": 0,
      "presence_penalty": 0
    }
    ```

- **Example Success Response (JSON - Adapt to actual API format):**

    ```json
    {
      "choices": [
        {
          "message": {
            "content": "{\"metadata\":{\"brand\":\"Levi Strauss & Co.\",\"product_name\":\"Levi's 550\",\"barcode\":null,\"condition\":\"good\",\"sizes\":[\"40W\",\"32L\"]}}"
          }
        },
        {
          "message": {
            "content": "{\"metadata\":{\"brand\":\"Nike\",\"product_name\":\"Air Max 270\",\"barcode\":73841379,\"condition\":\"like_new\",\"sizes\":[\"10\"]}}"
          }
        }
      ]
    }
    ```

- **Example Failure Response (JSON - OpenAI API Error - Adapt to actual API error format):**

    ```json
    {
      "error": {
        "message": "Incorrect API key provided: sk-...",
        "type": "invalid_request_error",
        "param": null,
        "code": "invalid_api_key"
      }
    }
    ```

### **5.2. API 2: Market Value Retrieval via Tavily Search API**

- **Endpoint**: `https://api.tavily.com/search`
- **Method**: `POST`
- **Headers**:

    ```http
    Content-Type: application/json
    Authorization: Bearer {tavilyApiKey}
    ```

- **Request Body (JSON Example - Adapt to actual API format):**

    ```json
    {
      "query": "What is the average price of a used good condition Nike Air Max 270, size(s): 10, on eBay, Amazon, and Facebook Marketplace?"
    }
    ```

- **Example Success Response (JSON - Adapt to actual API format):**

    ```json
    {
      "results": [
        {
          "url": "https://www.ebay.com/...",
          "title": "Nike Air Max 270 - Size 10 - Used - Good Condition - eBay",
          "content": "...Sold for $120..."
        },
        {
          "url": "https://www.amazon.com/...",
          "title": "Nike Air Max 270 - Size 10 - Used - Amazon Marketplace",
          "content": "...Price range $110 - $130..."
        }
      ]
    }
    ```

- **Example Failure Response (JSON - Tavily API Error - Adapt to actual API error format):**

    ```json
    {
      "error": "Invalid API key",
      "code": 401
    }
    ```

---

## 6. Explicit Dependencies and Variables

### **Dependencies**

- **Programming Language**: Swift 5.x
- **Minimum iOS Version**: iOS 14.0 (Consider iOS 15+ to leverage Swift Concurrency `async/await` if desired)
- **Frameworks**:
    - UIKit or SwiftUI (choose one for consistent UI development)
    - Photos
    - Foundation
- **Libraries**:
    - Firebase SDKs (Auth, Firestore, Storage - Firebase iOS SDK v9.x or later recommended)
    - CodableFirebase (Optional, for simplified Firestore data handling)
    - Google Generative AI Swift SDK (If available and simplifies Gemini API calls - otherwise, use `URLSession`)

### **Variables and Naming Conventions**

- **General**:
    - Use camelCase for variable and function names.
    - Prefix private variables with an underscore `_`.
- **Variables**:
    - `openAIApiKey: String` (**MUST be stored securely in Keychain**)
    - `tavilyApiKey: String` (**MUST be stored securely in Keychain**)
    - `takePhotoButton: UIButton` (Button to trigger camera access)
    - `uploadPhotoButton: UIButton` (Button to trigger photo library upload)
    - `itemImages: [UIImage]` (Array to store selected item images)
    - `extractedItemDetailsList: [ItemDetails]` (Array to store extracted item details from OpenAI API)
    - `constructedQueries: [String]` (Array to store constructed search queries for Tavily API)
    - `marketValues: [Double]` (Array to store retrieved market values from Tavily API)
    - `editButton: UIBarButtonItem` (Button for editing item details in UI)
    - `recalculateValueButton: UIButton` (Button to recalculate market value in UI)
    - `historyItems: [AnalyzedItem]` (Array to hold history items for display in History View)
    - `selectedDate: Date` (Currently selected date in History View)
    - `dailyTotalValueLabel: UILabel` (Label to display daily total market value in History View)
    - `auth: Auth` (Firebase Auth instance, initialized with `Auth.auth()`)
    - `databaseRef: Firestore` (Firestore database reference, initialized with `Firestore.firestore()`)
    - `storageRef: StorageReference` (Firebase Storage reference, initialized with `Storage.storage().reference()` - if Firebase Storage is used)
    - `currentUser: User?` (Variable to track currently logged-in user, get via `Auth.auth().currentUser`)
    - `batchItemDetails: [ItemDetails]` (Array to hold item details during batch processing)
    - `batchProgressView: UIProgressView` (Progress indicator for batch processing)
    - `batchProcessingStatusLabel: UILabel` (Label for displaying batch processing status messages)
    - `visionAnalysisResponse: GeminiVisionResponse?` *(Note: Consider renaming to `openAIAnalysisResponse` for clarity)* (Variable to hold response from OpenAI Vision API)

- **API Keys and Sensitive Data**:
    - `openAIApiKey`, `tavilyApiKey`: **MUST be stored securely using iOS Keychain services. Do not store API keys directly in code or UserDefaults.**
    - Ensure Firebase configuration files (`GoogleService-Info.plist`) are secured and not committed to public repositories.

---

## 7. API Error Handling and Edge Cases

- **HTTP Status Codes**:
    - `200 OK`: Success
    - `400 Bad Request`: Invalid request format. Handling: Log error details for debugging.
    - `401 Unauthorized`: Invalid or missing API key. Handling: Display an alert prompting the user to check their API key setup (if user-configurable), or log error for developer investigation if API key is app-managed.
    - `429 Too Many Requests`: Rate limiting. Handling: Implement exponential backoff retry logic with a delay. Inform user briefly that the app is temporarily slowing down due to high demand.
    - `500 Internal Server Error`: Server-side error. Handling: Display a general "Service Unavailable" message to the user. Log error details for developer investigation.

- **Error Messages**:
    - Display user-friendly error messages using `UIAlertController` (UIKit) or SwiftUI Alerts, categorized with titles like `Network Error`, `Authentication Error`, `AI Service Error`, `Data Retrieval Error`.

- **Retry Logic**:
    - Implement exponential backoff for transient errors (e.g., rate limits, temporary network glitches). For example, for `429 Too Many Requests`, retry after 2 seconds, then 4 seconds, then 8 seconds, up to a maximum number of retries.
    - Allow users to manually retry failed operations, especially for individual items in batch processing that encounter errors.

- **Edge Cases**:
    - **No Internet Connection**:
        - Detect network availability using `Reachability` or `NWPathMonitor`. If no network is available, gracefully handle API calls by displaying an alert to the user: "No Internet Connection. PriceWise requires an internet connection to analyze items and retrieve market data. Please check your network settings."
    - **Invalid Images**:
        - Perform basic client-side validation on selected images (e.g., check image size, format) before sending to the API. If images are invalid, display an error message: "Invalid Image Format or Size. Please select JPEG or PNG images under [Specify Size Limit, e.g., 5MB]." However, robust image validation will primarily rely on the AI API's response itself.
    - **Partial Data from AI Analysis**:
        - Handle cases where the OpenAI API might not be able to extract all metadata (e.g., `product_name` or `barcode` is `null` in the response). Design the UI to gracefully display "N/A" or "Unknown" for missing data. The app should still function even with partial metadata.
    - **No Market Value Found**:
        - Handle cases where the Tavily API might not find market value data for a given item. Display a message in the UI like "Market Value Not Found" or "Could not retrieve market value online." Consider displaying AI analysis data even if market value retrieval fails, allowing users to manually price based on AI-identified item details.
    - **Batch Processing Errors**:
        - If an error occurs for a single item within a batch, ensure that the error is handled *gracefully for that item only*, and the processing of other items in the batch continues. Collect error details for individual items and provide a summary to the user at the end of batch processing (e.g., "Processing completed for X out of Y items. Errors occurred for items: [Item Names/Indices].").

---

## 8. Security and Privacy

- **Data Protection**:
    - **API Key Security**: `openAIApiKey` and `tavilyApiKey` **MUST be stored securely in iOS Keychain services. Do not store API keys directly in code or UserDefaults.**
    - **Secure Communication**: Use HTTPS for all network communications to protect data in transit.
    - **Firebase Security Rules**: **Firebase Security Rules MUST be implemented for both Firestore and Storage (if used) to enforce data access control.** Configure rules to ensure that users can only access and modify their own data and prevent unauthorized access to user data and app backend.
    - **Data Encryption (Future Enhancement - MVP Focus on Secure Storage of Keys & Rules)**: For future iterations, consider implementing encryption for sensitive data stored locally on the device if any sensitive user data is cached offline. For MVP, focus on secure API key storage and Firebase Security Rules.

- **User Consent**:
    - **Camera and Photo Library Permissions**: Clearly explain to users *why* camera and photo library permissions are needed (using `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `Info.plist`).
    - **Data Privacy Policy**: For MVP pilot testing with real users, prepare a *basic privacy policy* that outlines:
        - What data the app collects (item images, item metadata, usage data - if any analytics are implemented).
        - How the data is used (for item pricing, improving app functionality).
        - Whether data is shared with third parties (OpenAI, Tavily, Firebase - and for what purposes).
        - User data deletion policy.
        - Contact information for privacy inquiries.

- **Compliance**:
    - **GDPR, CCPA, and other regulations**: While MVP is for initial testing, be mindful of data privacy regulations (GDPR, CCPA, etc.) relevant to your target user base. Design the app with privacy in mind and aim to comply with relevant regulations as you move beyond MVP.

- **Authentication Security**:
    - **Firebase Authentication Security**: Leverage Firebase Authentication's built-in security features for password hashing and secure user management.
    - **Strong Password Policies**: Encourage or enforce strong password policies during user registration (e.g., minimum length, complexity requirements).
    - **Email Verification**: Implement email verification flow after user registration to ensure valid email addresses and enhance account security.

---

## 9. Testing and Quality Assurance

- **Testing Framework**: Use `XCTest` framework for unit and UI testing in Xcode.
- **Test Cases**:
    - **Unit Testing**:
        - Data Model Tests: Verify data model encoding/decoding, data integrity.
        - Business Logic Tests: Test core logic functions (e.g., `constructSearchQuery`, price recommendation algorithms - if implemented in Swift code beyond API calls).
        - API Integration Mock Tests (for robustness): Create mock API responses and test API client functions' handling of success and error scenarios (for both OpenAI and Tavily APIs) *without making actual network calls* to ensure robustness and isolate testing.

    - **UI Testing**:
        - Basic UI Flow Tests: Test core user flows: image capture -> AI analysis -> result display -> saving item.
        - Batch Image Processing UI Tests:
            - Test selecting multiple images and initiating batch processing.
            - Verify progress indicator functionality during batch operations.
            - Check UI updates correctly after successful and partially failed batch processing.
        - User Editing UI Tests: Test navigation to edit view, data input in editable fields, validation error messages (if any), and recalculate value button functionality.

    - **Integration Testing (End-to-End Tests)**:
        - End-to-End Batch Processing Test: Perform end-to-end testing of batch image processing from image capture/upload -> OpenAI API call -> Tavily API calls -> result display. Verify correct data flow and overall workflow.
        - Firebase Integration Tests: Test saving and retrieving `AnalyzedItem` data to and from Firebase Firestore. Test user authentication flow (registration, login, logout).

    - **Performance Testing**:
        - Batch Processing Performance: Measure the time taken for batch processing with varying numbers of items (e.g., 1, 5, 10, 20 images).
        - UI Responsiveness Testing: Ensure UI remains responsive and does not freeze during API calls and data processing, especially during batch operations.

    - **Error Handling Test Cases**:
        - API Error Scenarios: Simulate network failures, invalid API keys, rate limit errors, and server errors for both OpenAI and Tavily APIs. Verify that the app handles these errors gracefully and displays appropriate user feedback (alerts, error messages).
        - Batch Item Error Handling: Test batch processing with a mix of images, some of which are intentionally designed to cause API errors (e.g., poor image quality, intentionally triggering rate limits). Verify that individual item errors are handled without stopping the entire batch, and error summaries are displayed.

---

## 10. Project Timeline and Milestones (Estimated - Subject to Change)

- **Week 1-2**:
    - **Milestone 1: Project Setup and User Authentication**.
    - Set up Xcode project, Firebase project, and integrate Firebase SDKs.
    - Implement user authentication (Feature 6) with email/password registration and login.
    - Basic UI setup for login/registration screens.

- **Week 3-4**:
    - **Milestone 2: Image Capture & Upload and OpenAI API Integration**.
    - Implement image capture and upload feature (Feature 1).
    - Integrate OpenAI `gpt-4o` API for item analysis (Feature 2) for single item processing *first*.
    - Basic UI to display AI analysis results for a single item.

- **Week 5-6**:
    - **Milestone 3: Batch Processing for OpenAI and Tavily API Integration**.
    - Implement batch processing for OpenAI API (Feature 2 - Batch Processing part).
    - Integrate Tavily Search API for market value retrieval (Feature 3) for single item processing *first*.
    - Basic UI to display market value for a single item.

- **Week 7-8**:
    - **Milestone 4: Batch Workflow and Result Display**.
    - Implement batch workflow orchestration (Feature 7) - linking OpenAI and Tavily API calls in sequence, progress indication.
    - Enhance UI to display results for multiple items in a list format (Feature 4 - Display Results part).
    - Implement basic user editing of item details (Feature 4 - User Editing part - local editing for MVP).

- **Week 9**:
    - **Milestone 5: History View and Logging (Basic)**.
    - Implement basic History View UI (Feature 5 - UI).
    - Implement logging of analyzed items to Firebase Firestore (Feature 5 - Data Storage).
    - Basic display of logged items in the History View (MVP - focus on display for a single date, basic list).

- **Week 10**:
    - **Milestone 6: Testing, Bug Fixing, and MVP Refinement**.
    - Comprehensive testing (Unit, UI, Integration, Error Handling, Performance) (Feature 9).
    - Bug fixing and code refinement.
    - Basic performance optimization.
    - Final review of MVP functionality and UI.
    - Prepare for internal testing or pilot user testing.

**Note:** This timeline is an estimate and is subject to change based on development progress, complexity of implementation, unforeseen issues, and feedback from testing.

---

## 11. Future Enhancements (Beyond MVP)

- **Third-Party Authentication**: Allow users to sign in with Google, Facebook, or Apple ID for easier onboarding.
- **Image Saving to Firebase Storage**: Implement saving item images to Firebase Storage and storing image URLs in Firestore `AnalyzedItem` documents.
- **Advanced Search and Filtering in History View**: Implement search functionality (by brand, product name, etc.) and more advanced filtering options (by date range, condition, etc.) in the History View.
- **Data Analytics and Reporting**: Provide basic analytics dashboards for users to track their pricing history, total value priced, and other relevant metrics.
- **Price Adjustment Recommendations**: Enhance the app to provide more sophisticated price adjustment recommendations based on item condition, market trends, and user preferences.
- **Localization**: Localize the app for multiple languages to expand user reach.
- **Android Version**: Expand to the Android platform based on user demand and market analysis.
- **Premium Features & Monetization**: Explore a subscription model for advanced or premium features (e.g., unlimited batch processing, advanced analytics, export data, priority support).

---

This updated PRD should be even more comprehensive and actionable for your development process. Remember to keep it as a living document and update it as needed throughout the project. Good luck building PriceWise!