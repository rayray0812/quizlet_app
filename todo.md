# 拾憶（Recall）開發進度

## 已完成 ✅

### 基礎建設 + 功能擴充
- [x] Step 1–10：專案骨架、資料模型、Hive、Supabase、Riverpod、驗證、首頁、WebView、學習模式、路由
- [x] F1–F6：URL 輸入、手動編輯、JSON/CSV 匯出入、題數選擇、Tinder 翻卡、拍照建卡

### FSRS 間隔重複
- [x] P1–P6：CardProgress/ReviewLog 模型、FSRS 演算法、SRS 複習畫面、首頁整合、統計儀表板、自訂學習

### 驗證系統強化
- [x] Email/password 登入/註冊 + 忘記密碼
- [x] Google/Apple OAuth + Magic Link
- [x] 路由守衛 + 深層連結 + session 驗證 + 生物辨識解鎖
- [x] Security Center（全域登出、刪除帳號、加密備份）
- [x] 同步衝突偵測 + 解決 UI
- [x] Auth 分析日誌 + 統一錯誤訊息

### 管理後台（Admin）
- [x] Phase 1：帳號管理 schema + admin service + console UI + 路由守衛
- [x] Phase 2：審核工作流 + MFA 強制 + 冒充登入
- [x] Phase 3：批次作業 + 合規匯出 + SLA 升級 + 治理自動化
- [x] 6 個 SQL migration + 3 個 Edge Function + GitHub Actions CI

### UI / 視覺
- [x] Liquid Glass 毛玻璃（iOS 限定）+ Adaptive Glass Card
- [x] TTS 語音品質升級
- [x] Home Screen Widgets（W1+W2）

### Daily Challenge（2026-02-14 完善）
- [x] l10n 字串（中/英 9 個 key：dailyChallenge, challengeStreak, challengeProgress...）
- [x] 完成獎勵 UX（SnackBar toast + 綠色漸層 + check icon）
- [x] Widget tests（3 個狀態：completed, no due cards, playable）
- [x] Provider streak edge-case tests（7 個：空 logs, 單日達標, 7 天長 streak, 超標 clamp...）

---

## 下一步

### Wrong Answer Revenge Mode（錯題複習模式）✅
- [x] 定義錯題池規則（最近 7 天，rating `Again` + `Hard`，依最近答錯時間排序）
- [x] 新增 `revengeCardIdsProvider` + `revengeCardCountProvider`
- [x] 首頁新增 `RevengeCard`（紫色漸層，顯示錯題數量，0 張時自動隱藏）
- [x] SrsReviewScreen 新增 `revengeCardIds` 參數，忽略 due 狀態直接載入指定卡片
- [x] Router `/review` 路由支援 `revengeCardIds` extra 參數
- [x] l10n 字串（`revengeMode`, `revengeCount`，中/英）
- [x] 8 個 unit tests（空 logs, Good/Easy 排除, Again/Hard 包含, 去重, 7 天過期, 排序, 混合評分）

### Technical Cleanup ✅
- [x] 檢視 summary/challenge 畫面中剩餘的硬編碼中英文字串，全部移到 l10n
- [x] 驗證 deep-link/global router helper 在 app cold start from widget tap 時的行為
  - 修復 iOS Info.plist 重複 CFBundleURLTypes（導致 recall:// scheme 失效）
  - 修復 cold start 時序競態（deep link 在 router 初始化前被呼叫導致遺失）
- [x] Sync 刪除同步強化（本地刪除 study set 會建立 tombstone 並推送雲端刪除）
- [x] Delta Pull 刪除對齊（遠端已刪除的已同步學習集會在本地清理）
- [x] 刪除學習集時同步清理 review logs，避免孤兒資料

### 部署準備
- [ ] 在 `supabase_constants.dart` 填入真實 Supabase URL 和 anon key
- [ ] 在 Supabase 建立資料表 + RLS 政策
- [ ] Verify Supabase Dashboard OAuth settings（Google/Apple provider + redirect URL whitelist）
- [ ] 實機測試驗證（Android/iOS/Web）

## Notes
- Product master plan（detailed）: `docs/product_master_plan_2026-02-14.md`
- Supabase redirect URI: `io.supabase.flutter://login-callback/`
- 確保同一 callback 已在 Supabase Auth URL config 中列入白名單
- `flutter analyze` 零問題、`flutter test` 92/92 通過（2026-02-15）
