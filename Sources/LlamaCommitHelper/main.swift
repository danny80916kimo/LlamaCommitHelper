import Foundation
import ArgumentParser

struct LlamaCommitHelper: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "llama-commit",
        abstract: "Generate commit messages using LLM Studio"
    )
    
    @Option(name: .long, help: "LLM Studio API URL")
    var apiURL: String = "http://localhost:1234"
    
    @Option(name: .long, help: "LLM Studio API Key (optional, only if your LLM Studio requires it)")
    var apiKey: String?
    
    @Flag(name: .long, help: "Show the generated commit message without committing")
    var dryRun: Bool = false
    
    func run() throws {
        print("正在檢查 LLM Studio 服務...")
        
        // 檢查 LLM Studio 服務是否在運行（同步 + timeout）
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
        
        let semaphore = DispatchSemaphore(value: 0)
        var isServiceAvailable = false
        var serviceError: Error?
        var statusCode: Int? = nil
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                isServiceAvailable = (200...299).contains(httpResponse.statusCode)
            }
            serviceError = error
            semaphore.signal()
        }
        task.resume()
        let timeoutResult = semaphore.wait(timeout: .now() + 5)
        
        if timeoutResult == .timedOut {
            print("錯誤：連線 LLM Studio 服務逾時 (timeout)")
            print("請確保 LLM Studio 服務正在運行於 \(apiURL)")
            throw ValidationError("LLM Studio 服務逾時")
        }
        
        if !isServiceAvailable {
            print("錯誤：無法連接到 LLM Studio 服務")
            print("請確保 LLM Studio 服務正在運行於 \(apiURL)")
            if let code = statusCode {
                print("HTTP 狀態碼：\(code)")
            }
            if let error = serviceError {
                print("詳細錯誤：\(error.localizedDescription)")
            }
            throw ValidationError("LLM Studio 服務不可用")
        }
        
        // 檢查 git 是否在 git 倉庫中
        let gitCheckProcess = Process()
        gitCheckProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitCheckProcess.arguments = ["rev-parse", "--is-inside-work-tree"]
        
        let gitCheckPipe = Pipe()
        gitCheckProcess.standardOutput = gitCheckPipe
        gitCheckProcess.standardError = gitCheckPipe
        
        try gitCheckProcess.run()
        gitCheckProcess.waitUntilExit()
        
        if gitCheckProcess.terminationStatus != 0 {
            print("錯誤：當前目錄不是 git 倉庫")
            throw ValidationError("當前目錄不是 git 倉庫")
        }
        
        // Get git diff
        print("正在讀取暫存的更改...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["diff", "--staged"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let diff = String(data: data, encoding: .utf8) else {
            print("錯誤：無法讀取 git diff")
            throw ValidationError("無法讀取 git diff")
        }
        
        if diff.isEmpty {
            print("錯誤：沒有找到暫存的更改")
            print("請先使用 'git add' 將要提交的檔案加入暫存區")
            return
        }
        
        print("正在連接 LLM Studio 服務...")
        let llmSemaphore = DispatchSemaphore(value: 0)
        var commitMessage: String? = nil
        var errorMessage: String? = nil
        Task {
            do {
                let llmService = LLMService(baseURL: apiURL, apiKey: apiKey)
                print("正在生成 commit message...")
                let msg = try await llmService.generateCommitMessage(from: diff)
                commitMessage = msg
            } catch {
                errorMessage = String(describing: error)
            }
            llmSemaphore.signal()
        }
        llmSemaphore.wait()
        
        if let errorMessage {
            print("錯誤：無法連接到 LLM Studio 服務")
            print("請確保 LLM Studio 服務正在運行於 \(apiURL)")
            print("詳細錯誤：\(errorMessage)")
            throw ValidationError(errorMessage)
        }
        commitMessage = commitMessage?
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let commitMessage else {
            print("錯誤：無法生成 commit message")
            throw ValidationError("無法生成 commit message")
        }
        
        
        
        print("\n生成的 commit message:")
        print(commitMessage)
        
        if dryRun {
            return
        }

        print("\n你要繼續用這個 message commit 嗎？ (y/N): ", terminator: "")
        guard let userInput = readLine(), userInput.lowercased() == "y" else {
            print("已取消 commit。")
            return
        }
        
        // Create commit
        print("正在創建 commit...")
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", commitMessage]
        
        let commitPipe = Pipe()
        commitProcess.standardOutput = commitPipe
        commitProcess.standardError = commitPipe
        
        try commitProcess.run()
        commitProcess.waitUntilExit()
        
        let commitData = commitPipe.fileHandleForReading.readDataToEndOfFile()
        if let commitOutput = String(data: commitData, encoding: .utf8) {
            print(commitOutput)
        }
        
        if commitProcess.terminationStatus == 0 {
            print("Commit 已成功創建！")
        } else {
            print("錯誤：創建 commit 失敗")
        }
    }
}

LlamaCommitHelper.main()
