# 專案：開源 Quizlet 替代方案（高中生適用）
# 技術棧：Flutter (Mobile + Web), Supabase (後端/驗證 + 雲端同步), Hive (本地離線儲存)
# 狀態管理：Riverpod | 資料模型：freezed | 路由：GoRouter

## 使用者決策（已確認）
- 獨立 app（不整合進 study_app）
- 從一開始就使用 Supabase + Hive
- 三種學習模式：翻卡片、測驗、配對遊戲
- 驗證為選用（支援訪客模式，離線優先）

---

## 目前進度

所有 10 個基礎步驟 + 5 個功能擴充已完成，程式碼已通過 `flutter analyze`（零新問題）和 `flutter test`（全部通過）。

### 基礎建設（Step 1–10）
- [x] Step 1：專案骨架 + 核心設定
- [x] Step 2：資料模型（freezed）+ Hive 轉接器
- [x] Step 3：本地儲存服務（Hive CRUD）
- [x] Step 4：Supabase 服務（驗證 + 同步）
- [x] Step 5：Riverpod 狀態管理
- [x] Step 6：驗證畫面（登入/註冊/訪客）
- [x] Step 7：首頁 + 學習集列表
- [x] Step 8：WebView 匯入器（JS 注入抓取 Quizlet）
- [x] Step 9：三種學習模式（翻卡片/測驗/配對）
- [x] Step 10：GoRouter 路由設定

### 功能擴充（Feature 1–5）
- [x] F1：Import 頁面 URL 輸入欄（TextField + 前往按鈕，自動補 https://，驗證 quizlet.com）
- [x] F2：手動新增/編輯單字卡（CardEditorScreen + CardEditRow，建立學習集後直接進入編輯）
- [x] F3：匯入與匯出 JSON/CSV（ImportExportService + file_picker + share_plus）
- [x] F4：測驗與配對可選題目數量（CountPickerDialog，Slider + 快捷按鈕 5/10/20/全部）
- [x] F5：Tinder 風格滑動翻卡片（SwipeCardStack，右滑=記得/左滑=不記得，輪結束統計 + 複習）

### FSRS 整合（Phase 1–6）
- [x] P1：資料層基礎（CardProgress + ReviewLog 模型 / Hive 轉接器 / tags 欄位）
- [x] P2：FSRS 引擎服務（fsrs 套件封裝 / FsrsService / Riverpod providers）
- [x] P3：SRS 複習畫面（翻卡 → 評分 Again/Hard/Good/Easy / 複習摘要）
- [x] P4：今日複習 + 首頁整合（TodayReviewCard banner / 到期數徽章 / 自動建立 CardProgress）
- [x] P5：統計儀表板（fl_chart 長條圖 / 熱力圖 / 圓餅圖 / 連續天數 streak）
- [x] P6：標籤與篩選（卡片標籤編輯 / 跨學習集搜尋 / 自訂學習範圍）

### 待辦 / 下一步
- [ ] 在 `supabase_constants.dart` 填入真實的 Supabase URL 和 anon key
- [ ] 在 Supabase 建立 `study_sets` + `card_progress` + `review_logs` 資料表 + RLS 政策
- [ ] 實機測試驗證（Android/iOS/Web）
- [ ] WebView 匯入功能實測（Quizlet DOM 可能變動，需調整 JS 選擇器）
- [ ] SRS 複習流程實測（新卡 → 複習 → 統計顯示正確）

---

## 專案結構

```
quizlet_app/lib/
├── main.dart                         # 初始化 Hive（4 boxes）, Supabase, ProviderScope
├── app.dart                          # MaterialApp.router + GoRouter + 主題
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # 應用常數（含 SRS box 名稱）
│   │   └── supabase_constants.dart   # Supabase URL + anon key（需替換）
│   ├── theme/
│   │   └── app_theme.dart            # Material 3 亮/暗主題
│   ├── router/
│   │   └── app_router.dart           # GoRouter 路由定義（含 SRS/統計/搜尋路由）
│   └── l10n/
│       └── app_localizations.dart    # 多語系（中文/英文，含 SRS/統計/標籤字串）
├── models/
│   ├── study_set.dart                # freezed 模型
│   ├── flashcard.dart                # freezed 模型（含 tags 欄位）
│   ├── card_progress.dart            # freezed 模型（SRS 進度：stability/difficulty/due...）
│   ├── review_log.dart               # freezed 模型（複習紀錄：rating/state/reviewedAt...）
│   └── adapters/
│       ├── study_set_adapter.dart    # 手動 Hive 轉接器（typeId: 0）
│       ├── flashcard_adapter.dart    # 手動 Hive 轉接器（typeId: 1，含 tags）
│       ├── card_progress_adapter.dart # 手動 Hive 轉接器（typeId: 2）
│       └── review_log_adapter.dart   # 手動 Hive 轉接器（typeId: 3）
├── services/
│   ├── local_storage_service.dart    # Hive CRUD（StudySet + CardProgress + ReviewLog）
│   ├── fsrs_service.dart             # FSRS 引擎封裝（reviewCard / getSchedulingPreview / getRetrievability）
│   ├── supabase_service.dart         # 驗證 + 資料同步
│   ├── sync_service.dart             # 離線優先同步邏輯
│   └── import_export_service.dart    # JSON/CSV 匯出入（F3）
├── providers/
│   ├── study_set_provider.dart       # StudySetsNotifier（含自動建立 CardProgress）
│   ├── fsrs_provider.dart            # dueCards / dueCount / dueBreakdown providers
│   ├── stats_provider.dart           # 統計聚合（todayCount / streak / dailyCounts / ratingCounts / heatmap）
│   ├── tag_provider.dart             # 標籤聚合（allTags）
│   ├── auth_provider.dart            # 驗證狀態串流
│   ├── sync_provider.dart            # 登入後觸發同步
│   └── locale_provider.dart          # 語言切換
└── features/
    ├── auth/
    │   ├── screens/
    │   │   ├── login_screen.dart      # 登入畫面
    │   │   └── signup_screen.dart     # 註冊畫面
    │   └── widgets/
    │       └── auth_form.dart         # 共用表單元件
    ├── home/
    │   ├── screens/
    │   │   ├── home_screen.dart       # 學習集列表 + 今日複習 Banner + 搜尋/統計按鈕
    │   │   ├── card_editor_screen.dart # 卡片編輯頁（含標籤編輯）
    │   │   └── search_screen.dart     # 跨學習集搜尋（term/definition/tags）
    │   └── widgets/
    │       ├── study_set_card.dart    # 學習集卡片元件（含到期數徽章）
    │       ├── card_edit_row.dart     # 單張卡片輸入列（含標籤）
    │       ├── today_review_card.dart # 今日複習 Banner（到期數 + 新卡/學習中/複習分類）
    │       └── tag_chips.dart         # 標籤顯示/編輯元件
    ├── import/
    │   ├── screens/
    │   │   ├── web_import_screen.dart      # WebView + URL 輸入欄 + FAB 匯入（F1）
    │   │   └── review_import_screen.dart   # 預覽 & 編輯後儲存
    │   ├── widgets/
    │   │   └── import_preview_card.dart    # 匯入預覽卡片
    │   └── utils/
    │       └── js_scraper.dart             # JS 注入腳本（4 種備援選擇器）
    ├── study/
    │   ├── screens/
    │   │   ├── study_mode_picker_screen.dart  # 選擇學習模式（SRS 複習 + 快速瀏覽 + 測驗 + 配對）
    │   │   ├── srs_review_screen.dart         # SRS 複習畫面（翻卡 → 評分 4 級）
    │   │   ├── review_summary_screen.dart     # 複習結束摘要
    │   │   ├── custom_study_screen.dart       # 標籤篩選複習
    │   │   ├── flashcard_screen.dart          # Tinder 風格滑動翻卡（快速瀏覽）
    │   │   ├── quiz_screen.dart               # 測驗（可選題數）
    │   │   └── matching_game_screen.dart      # 配對遊戲（可選組數）
    │   └── widgets/
    │       ├── flip_card.dart                 # 自製翻轉卡片動畫
    │       ├── swipe_card_stack.dart          # 滑動卡片堆疊元件
    │       ├── rating_buttons.dart            # Again/Hard/Good/Easy 四按鈕（含預計間隔）
    │       ├── count_picker_dialog.dart       # 題數選擇 Dialog
    │       ├── quiz_option_tile.dart          # 測驗選項元件
    │       └── matching_tile.dart             # 配對方塊元件
    └── stats/
        ├── screens/
        │   └── stats_screen.dart              # 統計主畫面（摘要卡片 + 圖表）
        └── widgets/
            ├── daily_chart.dart               # fl_chart 長條圖（近 30 天）
            ├── review_heatmap.dart            # GitHub 風格 7×52 熱力圖
            └── accuracy_donut.dart            # 評分比例圓餅圖
```

---

## 關鍵架構決策
- **驗證為選用**：訪客模式完全離線可用，登入後啟用雲端同步
- **離線優先**：Hive 為主要儲存，Supabase 透過 `isSynced` 旗標同步
- **手動 Hive 轉接器**：因為 freezed 和 hive_generator 有衝突
- **Cards 存為 JSONB**：Supabase 單一欄位，500 張卡以內不需 join
- **WebView 僅限手機**：Flutter web 不支援 WebView，用 `kIsWeb` 擋掉
- **多重 JS 選擇器**：Quizlet 經常改 DOM，4 種備援策略提高穩定性
- **Tinder 風格翻卡**：保留作為「快速瀏覽」選項，SRS 複習是獨立模式
- **題數自選**：測驗和配對模式透過 `state.extra` 傳遞數量參數
- **CardProgress 獨立儲存**：SRS 參數不嵌入 Flashcard，獨立 Hive box 避免每次複習重寫整個 StudySet
- **FSRS-5 演算法**：使用官方 `fsrs` Dart 套件（v2.0.1），不自己實作數學公式
- **ReviewLog 獨立 box**：append-only 紀錄，用日期索引支援統計查詢
- **所有 SRS DateTime 使用 UTC**：避免時區問題

## 路由表
| 路徑 | 畫面 |
|------|------|
| `/` | 首頁（學習集列表 + 今日複習 Banner） |
| `/login` | 登入 |
| `/signup` | 註冊 |
| `/import` | WebView 匯入（含 URL 輸入欄） |
| `/import/review` | 匯入預覽編輯 |
| `/review` | 跨學習集 SRS 複習 |
| `/review/summary` | 複習結束摘要 |
| `/stats` | 統計儀表板 |
| `/search` | 跨學習集搜尋 |
| `/study/custom` | 標籤篩選複習 |
| `/edit/:setId` | 卡片編輯頁（含標籤） |
| `/study/:setId` | 學習模式選擇（含匯出選單） |
| `/study/:setId/srs` | 單一學習集 SRS 複習 |
| `/study/:setId/flashcards` | 快速瀏覽（滑動翻卡） |
| `/study/:setId/quiz` | 測驗模式（extra: questionCount） |
| `/study/:setId/match` | 配對遊戲（extra: pairCount） |

## Supabase 資料表結構（待建立）
```sql
create table study_sets (
  id uuid primary key,
  user_id uuid references auth.users(id),
  title text not null,
  description text default '',
  cards jsonb default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS 政策：使用者只能存取自己的資料
alter table study_sets enable row level security;
create policy "Users can CRUD own sets"
  on study_sets for all
  using (auth.uid() = user_id);
```

## 新增套件
- `file_picker` — 選擇 JSON/CSV 檔案匯入
- `share_plus` — 分享匯出的檔案
- `path_provider` — 暫存匯出檔案路徑
- `fsrs` — FSRS-5 間隔重複演算法
- `fl_chart` — 統計圖表（長條圖/圓餅圖）

## 開發日誌（學習歷程）
- 位置：`D:\work\quizlet\portfolio\journal\YYYY-MM-DD.md`（不進 git）
- 每次開發結束時，幫我產生當天的日誌，聚焦在：
  1. **我做出的關鍵決策** — 為什麼選擇 A 而不是 B，背後的思考
  2. **決策造成的影響** — 對架構、UX、維護性的實際影響
  3. **人機協作觀察** — AI 做得好/不好的地方，我介入修正了什麼
  4. **遇到的問題與解法** — Bug、環境問題等
  5. **今天學到的事** — 技術層面的收穫
- 用途：高中學習歷程檔案，不是技術文件

## 驗證清單
- [ ] `flutter run` 在 Android/iOS 模擬器上正常執行
- [ ] WebView 載入 Quizlet，URL 輸入欄可導航，FAB 在題組頁面出現
- [ ] 匯入流程：抓取 -> 預覽 -> 儲存 -> 出現在首頁
- [ ] 檔案匯入：選 JSON/CSV -> 預覽 -> 儲存
- [ ] 匯出：JSON/CSV 透過分享功能匯出
- [ ] 卡片編輯：建立學習集 -> 進入編輯頁 -> 新增/刪除卡片 -> 加標籤 -> 儲存
- [ ] 三種學習模式皆可正常運作
- [ ] 測驗選題數 -> 只出指定數量；配對選組數 -> 只出指定數量
- [ ] 快速瀏覽：滑動分類 -> 結束統計 -> 複習不記得的
- [ ] SRS 複習：翻卡 -> 評分 -> 進度儲存 -> 結束摘要
- [ ] 今日複習 Banner：顯示到期數 -> 點擊進入跨學習集 SRS 複習
- [ ] 統計畫面：長條圖/熱力圖/圓餅圖 正常渲染
- [ ] 搜尋：跨學習集搜尋 term/definition/tags
- [ ] 驗證流程：註冊 -> 登入 -> 同步 -> 登出 -> 本地資料保留
- [ ] 離線測試：飛航模式下 app 正常使用 Hive 資料
- [ ] `flutter run -d chrome` 網頁版（匯入隱藏，其餘正常）
