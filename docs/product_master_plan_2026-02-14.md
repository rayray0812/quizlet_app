# 產品總規劃（2026-02-14）

## 1. 範圍與目標
- 產品：Quizlet 類型學習 App（Flutter + Riverpod + Supabase）。
- 核心目標：在確保同步、驗證、管理安全前提下，提升留存、學習效率與日活。
- 規劃期間：12 週（3 個階段，每階段 4 週）。
- 原則：每個功能都必須包含事件追蹤、測試、上線風險控管。

## 2. 北極星與成功指標
- 北極星指標：`每週有完成至少 1 次學習流程的活躍學習者數`。
- 核心產品 KPI：
  - D1 留存率。
  - D7 留存率。
  - 每活躍用戶每日學習場次。
  - 每場次平均複習卡數。
  - Daily Challenge 完成率。
  - 錯題恢復率（首次答錯後 7 天內答對）。
- 穩定性 KPI：
  - 無崩潰會話比率（Crash-free sessions）。
  - 同步衝突率。
  - 啟動時間 P95。
  - 複習頁載入時間 P95。
- 商業 KPI（若啟用訂閱）：
  - 試用啟動率。
  - 試用轉付費率。
  - 30 天付費留存率。

## 3. 交付原則
- 採垂直切片交付：UI + Provider/Service + Analytics + Test + Docs 一起完成。
- 資料庫採增量 migration，避免破壞性修改。
- Admin / 安全相關流程一律 fail-closed。
- 使用者可見文案一律優先 i18n。
- 品質門檻：
  - `flutter analyze` 無錯誤。
  - 相關測試通過。
  - Supabase migration / function 檢查腳本通過。

## 4. 三階段時程（12 週）

### 階段一（第 1-4 週）：學習核心 + 內容流程（P0）
- 目標：降低開始學習摩擦、提升每日完成量。
- 主軸：
  - 錯題復仇模式（Wrong Answer Revenge Mode）。
  - Daily Challenge 完整循環。
  - Quiz 模式強化。
  - 匯入與編輯流程打底。

### 階段二（第 5-8 週）：個人化 + 同步 + 留存（P1）
- 目標：提高跨日與跨裝置使用穩定性，增加回訪。
- 主軸：
  - 個人化推薦與弱點洞察。
  - 離線優先與衝突解決。
  - 智慧提醒與防打擾策略。

### 階段三（第 9-12 週）：成長 + 商業化 + 治理（P2）
- 目標：擴大流量來源，建立可持續商業模式。
- 主軸：
  - 公開題庫探索與分享。
  - Free/Pro 權益系統。
  - 管理治理與法遵收斂。

## 5. 功能詳規與待辦

### A. 學習核心

#### A1. 錯題復仇模式（P0）
- 問題：使用者反覆錯同一批卡，但沒有集中補強入口。
- 目標：一鍵進入只刷錯題流程，直到清除。
- 功能需求：
  - 錯題池來源：最近 7 天 review logs。
  - 排序規則：
    - 優先 `Again`。
    - 次優先 `Hard`。
    - 同級按最近錯誤時間優先。
  - Home 增加 `Revenge Mode` 入口。
  - `/review` 支援固定來源模式 `wrong_only`。
  - Summary 顯示「本次清除錯題數」。
- 技術拆分：
  - 新增 `wrong_answer_queue_provider.dart`。
  - 依賴 `allReviewLogsProvider` / `studySetsProvider` / `allCardProgressProvider`。
  - 路由 `extra` 帶入 mode 與 queue metadata。
  - 追蹤事件：
    - `revenge_mode_start`
    - `revenge_mode_complete`
    - `revenge_mode_clear_count`
- 測試：
  - Provider 篩選與排序單元測試。
  - Home 入口狀態 widget test。
  - 啟動到 summary 的整合測試。
- 驗收：
  - 僅包含符合條件錯題。
  - 排序規則正確。
  - 清除數統計正確。

#### A2. Daily Challenge 完整循環（P0）
- 問題：目前挑戰流程雖可用，但文案、獎勵循環與邊界行為不完整。
- 功能需求：
  - 挑戰相關文案全數 i18n。
  - 完成獎勵 UX（toast/confetti/badge）。
  - 同一天完成提示只觸發一次（冪等）。
  - 連續天數計算涵蓋邊界（今天未達標但昨天達標等）。
- 技術拆分：
  - Provider 維持挑戰狀態。
  - 本地儲存新增「今日獎勵是否已領取」旗標。
  - `app_localizations` 新增挑戰文案 keys。
- 測試：
  - completed / no due / playable 三狀態 widget test。
  - streak 邊界 unit test。
  - reward 冪等測試。
- 驗收：
  - 無硬編碼挑戰文案。
  - 當日完成提示只出現一次。

#### A3. Quiz 模式強化（P0）
- 功能需求：
  - 題型混合（選擇 / 輸入 / 判斷）。
  - 答題後即時解析。
  - 錯題自動進入後續補強回合。
- 指標：
  - Quiz 完成率。
  - 補強回合前後分數提升。
- 測試：
  - 計分邏輯單元測試。
  - 回饋 UI widget test。

### B. 內容建立與管理

#### B1. 統一匯入流程（P0）
- 來源：CSV、圖片 OCR、Web 匯入。
- 功能需求：
  - 統一 preview 與正規化流程。
  - 重複卡偵測與信心提示。
  - 標籤推斷擴充點。
- 驗收：
  - 各來源流程一致。
  - 失敗資料列有可操作錯誤訊息。

#### B2. 編輯器升級（P0/P1）
- 功能需求：
  - 批次編輯（標籤/欄位）。
  - 重複卡、空白卡防呆。
  - 編輯會話 undo/redo。
- 測試：
  - 批次邏輯單元測試。
  - 驗證流程 widget test。

### C. 個人化與成效分析（P1）

#### C1. 今日建議引擎
- 輸入：
  - 到期卡數。
  - 錯題待清除量。
  - 近期完成習慣。
- 輸出：
  - 今日建議任務（模式分配 + 預估時間）。
- 指標：
  - 建議採用率。
  - 預估與實際完成偏差。

#### C2. 弱點分析
- 功能需求：
  - 常錯詞。
  - 易混淆詞對。
  - 每週趨勢圖。
- 驗收：
  - 可從洞察頁一鍵跳轉到對應練習。

### D. 多裝置與離線（P1）

#### D1. 離線優先學習
- 功能需求：
  - 所有學習模式可離線執行。
  - 連線恢復後自動同步與重試。
  - 顯示同步狀態與最後成功時間。
- 驗收：
  - 離線 -> 上線過程無資料遺失。

#### D2. 衝突解決 UX
- 功能需求：
  - 欄位級差異對比。
  - 合併決策預覽。
  - 決策紀錄可追蹤。
- 指標：
  - 衝突解決完成率。
  - 重複開啟同衝突比例。

### E. 提醒與留存（P1）

#### E1. 智慧提醒系統
- 功能需求：
  - 依個人完成時間窗自動調整提醒時段。
  - 安靜時段與提醒頻率上限。
  - 3/7 天未學習用戶召回任務。
- 指標：
  - 通知開啟率。
  - 通知到學習啟動轉換率。

### F. 成長與社群（P2）

#### F1. 公開題庫探索
- 功能需求：
  - 依主題/語言/難度搜尋。
  - 依品質與互動排名。
  - 檢舉與審核流程。

#### F2. 分享與收藏
- 功能需求：
  - 唯讀分享連結。
  - 收藏夾與集合管理。
  - 作者頁與代表作呈現。

### G. 商業化（P2）

#### G1. Free/Pro 權益系統
- Pro 候選功能：
  - 進階成效分析。
  - AI 匯入清理。
  - 更高匯入/儲存上限。
  - 進階主題與桌面小工具。
- 功能需求：
  - 伺服器權益判定為準。
  - 試用寬限與恢復購買流程。
- 指標：
  - 付費牆點擊率。
  - 試用轉付費率。

### H. 安全與治理（持續，最高優先）

#### H1. Admin 權限收斂
- 功能需求：
  - App/Service 層角色檢查一致。
  - Edge function token 驗證 fail-closed。
  - 簽章匯出流程與審計留痕。
- 驗收：
  - 未授權請求被拒。
  - Audit logs append-only。

#### H2. 法遵作業
- 功能需求：
  - 刪帳/資料匯出 SLA 追蹤。
  - 治理 worker 遙測。
  - 事件處理 runbook 維護。

## 6. 架構與工程治理
- App 架構：
  - 維持 feature 分層（provider/service/widget）。
  - 拆解過大 service，避免 god class。
- 資料層：
  - 複雜過濾排序優先下放 SQL view/function。
  - 工作流 handler 需可重入、冪等。
- 可觀測性：
  - 事件 taxonomy 文件化。
  - sync/import/admin error code 標準化。
- 效能：
  - 隱藏分頁渲染改 `IndexedStack`。
  - Provider 計算熱點做 selector/memoization。

## 7. 測試與 QA 策略
- Unit：
  - 錯題排序、streak 計算、權限判定、sync merge。
- Widget：
  - Home 卡片狀態、summary 區塊、權限守衛。
- Integration：
  - Auth + deep link 冷啟動。
  - 離線學習後同步整合。
  - Admin 審批/批次流程（可行範圍內）。
- Release Gate：
  - P0 測試失敗不得上線。
  - migration/schema 檢查未過不得上線。

## 8. 上線策略
- 分階段發布：
  - Stage 1：內部/開發。
  - Stage 2：5-10%。
  - Stage 3：50%。
  - Stage 4：100%。
- Feature flags：
  - `feature_revenge_mode`
  - `feature_daily_reward`
  - `feature_quiz_mixed_mode`
  - `feature_public_discovery`
  - `feature_pro_entitlement`
- 回滾策略：
  - 每個新入口具備遠端關閉開關。
  - Provider/Service 異常時有安全降級 UI。

## 9. 風險與對策
- 風險：模式增加造成同步衝突上升。
  - 對策：強化 merge UX + 衝突遙測 + 有節制重試。
- 風險：通知過多造成疲勞。
  - 對策：頻率上限 + 安靜時段 + 自適應時段。
- 風險：Admin 權限漂移或誤用。
  - 對策：append-only 審計 + 審批軌跡 + 定期 schema 檢查。
- 風險：範圍膨脹導致延期。
  - 對策：每週範圍審查，第 3 週後凍結 P0 需求。

## 10. 每週運作節奏
- 週初：
  - 檢視 KPI 變化。
  - 依影響/風險重排優先順序。
- 週中：
  - 同步開發進度與阻塞。
- 週末：
  - Demo 當週交付。
  - 對比預期與實際數據。
  - 回寫本文件決策與調整。

## 11. 近期 2 週執行清單
- 第 1 週：
  - 上線 Revenge Mode provider + Home 入口 + review 啟動。
  - summary 顯示清除錯題數。
  - 補 provider/widget 測試。
- 第 2 週：
  - 完成 Daily Challenge i18n 與獎勵循環。
  - 補獎勵冪等儲存與測試。
  - 驗證 deep-link 冷啟動整合測試。

## 12. 文件維護規範
- 負責人：`quizlet_app` 產品/工程負責人。
- 更新規則：
  - 每週五固定更新，或重大範圍變更時即時更新。
  - 每次更新需附日期與變更章節。
