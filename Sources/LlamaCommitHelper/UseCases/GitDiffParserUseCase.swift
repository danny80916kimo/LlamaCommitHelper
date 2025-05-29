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
        var results: [FileDiff] = []

        let lines = diff.components(separatedBy: .newlines)
        var currentFile: String?
        var hunks: [Hunk] = []
        var currentHunkHeader: String?
        var currentHunkLines: [String] = []

        for line in lines {
            if line.starts(with: "diff --git ") {
                // 存下前一個檔案的 diff
                if let file = currentFile, !hunks.isEmpty {
                    results.append(FileDiff(filePath: file, hunks: hunks))
                }

                // 取得檔案路徑
                if let fileMatch = line.components(separatedBy: " ").last {
                    currentFile = fileMatch.replacingOccurrences(of: "b/", with: "")
                }

                hunks = []
            } else if line.starts(with: "@@") {
                if let headerStart = line.range(of: "@@"), let headerEnd = line.range(of: "@@", options: .backwards), headerStart != headerEnd {
                    let header = String(line[headerStart.upperBound..<headerEnd.lowerBound]).trimmingCharacters(in: .whitespaces)
                    currentHunkHeader = header
                    let firstLineContent = String(line[headerEnd.upperBound..<line.endIndex])
                    currentHunkLines.append(firstLineContent)
                    hunks.append(Hunk(header: header, content: currentHunkLines.joined(separator: "\n")))
                    currentHunkLines = []
                } else {
                    currentHunkHeader = line
                }
            } else {
                currentHunkLines.append(line)
            }
        }

        // 加入最後一個 hunk 和檔案
        if let header = currentHunkHeader {
            hunks.append(Hunk(header: header, content: currentHunkLines.joined(separator: "\n")))
        }
        if let file = currentFile {
            results.append(FileDiff(filePath: file, hunks: hunks))
        }

        return results
    }
} 
