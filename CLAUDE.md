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

### 待辦 / 下一步
- [ ] 在 `supabase_constants.dart` 填入真實的 Supabase URL 和 anon key
- [ ] 在 Supabase 建立 `study_sets` 資料表 + RLS 政策
- [ ] 實機測試驗證（Android/iOS/Web）
- [ ] WebView 匯入功能實測（Quizlet DOM 可能變動，需調整 JS 選擇器）

---

## 專案結構

```
quizlet_app/lib/
├── main.dart                         # 初始化 Hive, Supabase, ProviderScope
├── app.dart                          # MaterialApp.router + GoRouter + 主題
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # 應用常數
│   │   └── supabase_constants.dart   # Supabase URL + anon key（需替換）
│   ├── theme/
│   │   └── app_theme.dart            # Material 3 亮/暗主題
│   ├── router/
│   │   └── app_router.dart           # GoRouter 路由定義
│   └── l10n/
│       └── app_localizations.dart    # 多語系（中文/英文）
├── models/
│   ├── study_set.dart                # freezed 模型
│   ├── flashcard.dart                # freezed 模型
│   └── adapters/
│       ├── study_set_adapter.dart    # 手動 Hive 轉接器
│       └── flashcard_adapter.dart    # 手動 Hive 轉接器
├── services/
│   ├── local_storage_service.dart    # Hive CRUD 操作
│   ├── supabase_service.dart         # 驗證 + 資料同步
│   ├── sync_service.dart             # 離線優先同步邏輯
│   └── import_export_service.dart    # JSON/CSV 匯出入（F3）
├── providers/
│   ├── study_set_provider.dart       # StudySetsNotifier
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
    │   │   ├── home_screen.dart       # 學習集列表 + 建立/匯入/檔案匯入
    │   │   └── card_editor_screen.dart # 卡片編輯頁（F2）
    │   └── widgets/
    │       ├── study_set_card.dart    # 學習集卡片元件（含編輯按鈕）
    │       └── card_edit_row.dart     # 單張卡片輸入列（F2）
    ├── import/
    │   ├── screens/
    │   │   ├── web_import_screen.dart      # WebView + URL 輸入欄 + FAB 匯入（F1）
    │   │   └── review_import_screen.dart   # 預覽 & 編輯後儲存
    │   ├── widgets/
    │   │   └── import_preview_card.dart    # 匯入預覽卡片
    │   └── utils/
    │       └── js_scraper.dart             # JS 注入腳本（4 種備援選擇器）
    └── study/
        ├── screens/
        │   ├── study_mode_picker_screen.dart  # 選擇學習模式 + 匯出選單（F3）
        │   ├── flashcard_screen.dart          # Tinder 風格滑動翻卡（F5）
        │   ├── quiz_screen.dart               # 測驗（可選題數）（F4）
        │   └── matching_game_screen.dart      # 配對遊戲（可選組數）（F4）
        └── widgets/
            ├── flip_card.dart                 # 自製翻轉卡片動畫
            ├── swipe_card_stack.dart          # 滑動卡片堆疊元件（F5）
            ├── count_picker_dialog.dart       # 題數選擇 Dialog（F4）
            ├── quiz_option_tile.dart          # 測驗選項元件
            └── matching_tile.dart             # 配對方塊元件
```

---

## 關鍵架構決策
- **驗證為選用**：訪客模式完全離線可用，登入後啟用雲端同步
- **離線優先**：Hive 為主要儲存，Supabase 透過 `isSynced` 旗標同步
- **手動 Hive 轉接器**：因為 freezed 和 hive_generator 有衝突
- **Cards 存為 JSONB**：Supabase 單一欄位，500 張卡以內不需 join
- **WebView 僅限手機**：Flutter web 不支援 WebView，用 `kIsWeb` 擋掉
- **多重 JS 選擇器**：Quizlet 經常改 DOM，4 種備援策略提高穩定性
- **Tinder 風格翻卡**：右滑=記得、左滑=不記得，輪結束後可複習不記得的卡片
- **題數自選**：測驗和配對模式透過 `state.extra` 傳遞數量參數

## 路由表
| 路徑 | 畫面 |
|------|------|
| `/` | 首頁（學習集列表） |
| `/login` | 登入 |
| `/signup` | 註冊 |
| `/import` | WebView 匯入（含 URL 輸入欄） |
| `/import/review` | 匯入預覽編輯 |
| `/edit/:setId` | 卡片編輯頁 |
| `/study/:setId` | 學習模式選擇（含匯出選單） |
| `/study/:setId/flashcards` | Tinder 風格滑動翻卡 |
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

## 新增套件（F3）
- `file_picker` — 選擇 JSON/CSV 檔案匯入
- `share_plus` — 分享匯出的檔案
- `path_provider` — 暫存匯出檔案路徑

## 驗證清單
- [ ] `flutter run` 在 Android/iOS 模擬器上正常執行
- [ ] WebView 載入 Quizlet，URL 輸入欄可導航，FAB 在題組頁面出現
- [ ] 匯入流程：抓取 -> 預覽 -> 儲存 -> 出現在首頁
- [ ] 檔案匯入：選 JSON/CSV -> 預覽 -> 儲存
- [ ] 匯出：JSON/CSV 透過分享功能匯出
- [ ] 卡片編輯：建立學習集 -> 進入編輯頁 -> 新增/刪除卡片 -> 儲存
- [ ] 三種學習模式皆可正常運作
- [ ] 測驗選題數 -> 只出指定數量；配對選組數 -> 只出指定數量
- [ ] 翻卡片：滑動分類 -> 結束統計 -> 複習不記得的
- [ ] 驗證流程：註冊 -> 登入 -> 同步 -> 登出 -> 本地資料保留
- [ ] 離線測試：飛航模式下 app 正常使用 Hive 資料
- [ ] `flutter run -d chrome` 網頁版（匯入隱藏，其餘正常）
