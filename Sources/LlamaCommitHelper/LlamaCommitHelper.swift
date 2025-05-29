//
//  LlamaCommitHelper.swift
//  meepoo
//
//  Created by 劉家瑋 on 2025/5/29.
//


import Foundation
import ArgumentParser

@main
struct LlamaCommitHelper: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "meepoo",
        abstract: "Generate commit messages using LLM Studio"
    )
    
    @Option(name: .long, help: "LLM Studio API URL")
    var apiURL: String = "http://localhost:1234"
    
    @Option(name: .long, help: "LLM Studio API Key (optional, only if your LLM Studio requires it)")
    var apiKey: String?
    
    @Flag(name: .long, help: "Show the generated commit message without committing")
    var dryRun: Bool = false
    
    func run() async throws {
        print("正在檢查 LLM Studio 服務...")
        try await LLMServiceCheckUseCase(apiURL: apiURL).check()
        try GitRepositoryCheckUseCase().check()
        let diff = try GitDiffUseCase().getStagedDiff()
        
        let lmStudioService = LMStudioService(baseURL: apiURL, apiKey: apiKey)
        
        var commitMessage: String? = nil
        var errorMessage: String? = nil

        do {
            commitMessage = try await CommitMessageGenerationUseCase(llmService: lmStudioService).generate(from: diff)
        } catch {
            errorMessage = String(describing: error)
        }
        
        if let errorMessage {
            print("錯誤：無法連接到 LLM Studio 服務")
            print("請確保 LLM Studio 服務正在運行於 \(apiURL)")
            print("詳細錯誤：\(errorMessage)")
            throw ValidationError(errorMessage)
        }
        
        
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
