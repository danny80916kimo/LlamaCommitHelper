import Foundation
import ArgumentParser

struct GitRepositoryCheckUseCase {
    func check() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--is-inside-work-tree"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            print("錯誤：當前目錄不是 git 倉庫")
            throw ValidationError("當前目錄不是 git 倉庫")
        }
    }
} 
