import Foundation

struct CommitMessageGenerationUseCase {
    let llmService: LMStudioService
    
    func generate(from diff: String) async throws -> String {
        print("正在解析 git diff...")
        let parser = GitDiffParserUseCase()
        let fileDiffs = parser.parse(diff)
        
        print("正在為每個變更區塊生成說明...")
        var allHunkComments: [String] = []
        
        for file in fileDiffs {
            for hunk in file.hunks {
                let prompt = "以下是檔案 \(file.filePath) 的變更區塊（\(hunk.header)）：\n\(hunk.content)\n請用一句話說明這段變更的用途。"
                let hunkComment = try await llmService.generateMessage(token: prompt)
                print("檔案: \(file.filePath)")
                print("總結: \(hunkComment)")
                allHunkComments.append(hunkComment)
            }
        }
        
        print("正在生成最終的 commit message...")
        let commitMessage = try await llmService.generateCommitMessage(from: allHunkComments)
        
        return commitMessage
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 
