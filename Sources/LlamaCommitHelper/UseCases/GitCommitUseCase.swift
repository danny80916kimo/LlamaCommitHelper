import Foundation
import ArgumentParser

struct GitCommitUseCase {
    func commit(with message: String) throws {
        print("正在創建 commit...")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["commit", "-m", message]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print(output)
        }
        
        if process.terminationStatus == 0 {
            print("Commit 已成功創建！")
        } else {
            print("錯誤：創建 commit 失敗")
            throw ValidationError("創建 commit 失敗")
        }
    }
} 
