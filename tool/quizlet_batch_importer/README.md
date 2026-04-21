# Quizlet Batch Importer

本機自用工具，用來批量整理 Quizlet 單字集，合併後輸出成 Recall app 可匯入的 JSON。

## 功能

- 一次貼上一個或多個 Quizlet 連結
- 逐個打開 Quizlet 頁面
- 如果遇到 Cloudflare 驗證，可先手動完成
- 用書籤腳本擷取目前頁面的單字資料回到本機網站
- 勾選多個單字集後合併匯出成 JSON

## 啟動

在 `quizlet_app` 目錄執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\quizlet_batch_importer\start_server.ps1
```

啟動後會開啟：

```text
http://127.0.0.1:47831
```

## 使用方式

1. 在頁面上貼入一個或多個 Quizlet 連結。
2. 點 `Open` 開啟某個 Quizlet。
3. 如果 Quizlet 出現 Cloudflare 驗證，先在該頁手動完成。
4. 頁面正常顯示單字後，點瀏覽器書籤列上的 `Quizlet -> Recall` 書籤腳本。
5. 本機網站會收到這份單字集。
6. 勾選要合併的單字集，輸入匯出標題後下載 JSON。
7. 在手機 app 用既有 JSON 匯入功能導入。

## Cloudflare 說明

這個工具不會硬闖或破解 Cloudflare。做法是：

- 你用自己的瀏覽器打開 Quizlet
- 需要時自己通過人機驗證
- 驗證通過、頁面已載入後，再由書籤腳本直接讀取頁面上的資料

這樣通常比後端爬蟲穩定，也比較適合本機自用。
