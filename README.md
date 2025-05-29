# meepoo

一個使用 LLM Studio 來生成 Git commit messages 的命令行工具。

## 安裝

1. 確保你已經安裝了 Swift 5.9 或更高版本
2. Clone這個Repo
3. 在專案目錄中運行：
   ```bash
   swift build -c release
   ```
4. 將編譯好的執行檔複製到你的 PATH 目錄：
   ```bash
   sudo cp .build/release/meepoo /usr/local/bin/meepoo
   ```

## 使用方法

首先先開啟LM Studio
載入你想要的模型


基本用法：
先執行

```bash
git add .
```

```bash
meepoo 
```

選項：
- `--api-url`: LLM Studio API 的 URL（預設：http://localhost:1234）
- `--api-key`: LLM Studio API 的密鑰（必需）
- `--dry-run`: 只顯示生成的 commit message，不實際提交

## 工作流程

1. 使用 `git add` 將要提交的文件加入暫存區
2. 運行 `meepoo` 命令
3. 工具會自動：
   - 讀取暫存的更改
   - 使用 LLM Studio 生成 commit message
   - 創建 commit

## 注意事項

- 確保你的 LLM Studio 服務正在運行
- 需要有正確的 API 密鑰
- 需要 macOS 13.0 或更高版本
