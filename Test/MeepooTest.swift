//
//  MeepooTest.swift
//  meepoo
//
//  Created by 劉家瑋 on 2025/5/29.
//


import XCTest
@testable import meepoo

final class MeepooTests: XCTestCase {
    func testGenerateCommitMessage() async throws {
        // Arrange: 用假的 baseURL 模擬一個可測的情境
        let service = LMStudioService(baseURL: "http://localhost:1234", apiKey: nil)
        let dummyDiff = """
        diff --git a/file.txt b/file.txt
        index e69de29..4b825dc 100644
        --- a/file.txt
        +++ b/file.txt
        @@ -0,0 +1,2 @@
        +Hello
        +World
        """
        
        // Act & Assert: 測試這個 function 是否成功執行
        do {
            let message = try await service.generateCommitMessage(from: dummyDiff)
            print("測試LLM")
            print("\(message)")
            XCTAssertFalse(message.isEmpty, "Message should not be empty")
        } catch {
            XCTFail("generateCommitMessage threw an error: \(error)")
        }
    }
    
    func testParseGitDiff(){
        let diffString: String = """
        git diff --staged
        diff --git a/Package.swift b/Package.swift
        index 7803523..1f069d9 100644
        --- a/Package.swift
        +++ b/Package.swift
        @@ -4,7 +4,7 @@
         import PackageDescription
         
         let package = Package(
        -    name: "LlamaCommitHelper",
        +    name: "meepoo",
             platforms: [
                 .macOS(.v13)
             ],
        @@ -16,7 +16,7 @@ let package = Package(
                 // Targets are the basic building blocks of a package, defining a module or a test suite.
                 // Targets can depend on other targets in this package and products from dependencies.
                 .executableTarget(
        -            name: "LlamaCommitHelper",
        +            name: "meepoo",
                     dependencies: [
                         .product(name: "ArgumentParser", package: "swift-argument-parser"),
                         .product(name: "HTTPTypes", package: "swift-http-types"),
        diff --git a/Sources/LlamaCommitHelper/main.swift b/Sources/LlamaCommitHelper/main.swift
        index b32bf42..c2f8e21 100644
        --- a/Sources/LlamaCommitHelper/main.swift
        +++ b/Sources/LlamaCommitHelper/main.swift
        @@ -3,7 +3,7 @@ import ArgumentParser
         
         struct LlamaCommitHelper: ParsableCommand {
             static var configuration = CommandConfiguration(
        -        commandName: "llama-commit",
        +        commandName: "meepoo",
                 abstract: "Generate commit messages using LLM Studio"
             )
             
        @@ -100,7 +100,7 @@ struct LlamaCommitHelper: ParsableCommand {
                 
                 let data = pipe.fileHandleForReading.readDataToEndOfFile()
                 guard let diff = String(data: data, encoding: .utf8) else {
        -            print("錯誤：無法讀取 git diff")
        +            print("錯誤：無法讀取 git diff 請檢查git環境位置")
                     throw ValidationError("無法讀取 git diff")
        """
        
        let parsedDiff = meepoo.parseGitDiff(diffString)
        print("測試parsedDiff")
        parsedDiff.forEach { diff in
            print("Diff.filePath \(diff.filePath)")
            print("hunk----------------------------- ")
            diff.hunks.forEach { hunk in
                print("hunk  header----------------------------- ")
                print(hunk.header)
                print("hunk  content----------------------------- ")
                print(hunk.content)
            }
        }
        XCTAssertTrue(true)
    }
}

