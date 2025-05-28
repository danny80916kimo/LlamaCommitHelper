import Foundation
import HTTPTypes

struct LLMService {
    private let baseURL: String
    private let apiKey: String?
    
    init(baseURL: String, apiKey: String?) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    func generateCommitMessage(from diff: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let prompt = """
        Please analyze the following git diff and generate a concise, descriptive commit message.
        Follow conventional commit format if possible.
        
        Git diff:
        \(diff)
        """
        
        let requestBody: [String: Any] = [
            "model": "qwen2.5-7b-instruct-1m",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that generates commit messages based on git diffs."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 150
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.badServerResponse)
        }
        
        return content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
} 
