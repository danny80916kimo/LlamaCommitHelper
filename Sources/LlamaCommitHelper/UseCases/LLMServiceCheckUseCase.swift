import Foundation
import ArgumentParser

struct LLMServiceCheckUseCase {
    let apiURL: String
    
    func check() async throws {
        print("正在檢查 LLM Studio 服務...")
        
        guard let url = URL(string: "\(apiURL)/v1/chat/completions") else {
            print("錯誤：無效的 API URL")
            throw ValidationError("無效的 API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 3 // 3秒 timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 傳送一個最小合法 body
        let dummyBody: [String: Any] = [
            "model": "dummy",
            "messages": [["role": "user", "content": "ping"]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: dummyBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("錯誤：無法連接到 LLM Studio 服務")
            print("請確保 LLM Studio 服務正在運行於 \(apiURL)")
            throw ValidationError("無效的 HTTP 回應")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("錯誤：無法連接到 LLM Studio 服務")
            print("請確保 LLM Studio 服務正在運行於 \(apiURL)")
            print("HTTP 狀態碼：\(httpResponse.statusCode)")
            throw ValidationError("LLM Studio 服務回應錯誤")
        }
    }
} 
