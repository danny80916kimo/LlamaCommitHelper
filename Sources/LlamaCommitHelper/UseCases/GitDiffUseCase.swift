import Foundation
import ArgumentParser

struct GitDiffUseCase {
    func getStagedDiff() throws -> String {
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
            throw ValidationError("沒有暫存的更改")
        }
        
        return diff
    }
} 
