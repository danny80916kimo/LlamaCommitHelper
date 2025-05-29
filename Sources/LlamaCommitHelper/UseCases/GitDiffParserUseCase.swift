import Foundation

struct GitDiffParserUseCase {
    struct FileDiff {
        let filePath: String
        let hunks: [Hunk]
    }
    
    struct Hunk {
        let header: String
        let content: String
    }
    
    func parse(_ diff: String) -> [FileDiff] {
        var fileDiffs: [FileDiff] = []
        var currentFilePath: String?
        var currentHunks: [Hunk] = []
        var currentHunkHeader: String?
        var currentHunkContent = ""
        
        let lines = diff.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("diff --git") {
                // Save previous file if exists
                if let filePath = currentFilePath, !currentHunks.isEmpty {
                    fileDiffs.append(FileDiff(filePath: filePath, hunks: currentHunks))
                }
                
                // Start new file
                let components = line.components(separatedBy: " ")
                if components.count >= 3 {
                    currentFilePath = components[2].replacingOccurrences(of: "b/", with: "")
                }
                currentHunks = []
                currentHunkHeader = nil
                currentHunkContent = ""
            } else if line.hasPrefix("@@") {
                // Save previous hunk if exists
                if let header = currentHunkHeader, !currentHunkContent.isEmpty {
                    currentHunks.append(Hunk(header: header, content: currentHunkContent))
                }
                
                // Start new hunk
                currentHunkHeader = line
                currentHunkContent = ""
            } else if currentHunkHeader != nil {
                // Add line to current hunk content
                currentHunkContent += line + "\n"
            }
        }
        
        // Save last file and hunk
        if let filePath = currentFilePath, !currentHunks.isEmpty {
            if let header = currentHunkHeader, !currentHunkContent.isEmpty {
                currentHunks.append(Hunk(header: header, content: currentHunkContent))
            }
            fileDiffs.append(FileDiff(filePath: filePath, hunks: currentHunks))
        }
        
        return fileDiffs
    }
} 