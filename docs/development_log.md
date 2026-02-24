# Development Log
## 2026-02-22

### Learn / 刷題闖關 UX 重構（完成一輪）

### Summary
- 將 `LearnModeScreen` 從資訊堆疊型介面重構為「章節闖關」主線，畫面常駐資訊收斂為：
  - 章節
  - 本章進度條（含大百分比）
  - 題目區
- 強化台灣高中生在地化文案與情緒價值，整體語氣改為更貼近刷題／段考複習情境。
- 新增章節進度恢復（退出再進可回到上次章節）。
- 新增刷題闖關進入前的底部預備視窗，重點呈現：
  - 章節時間軸
  - 完成章節
  - 大進度百分比

### Why（這輪為什麼這樣改）
- 原本 Learn 介面資訊過多、重複提示太多，使用者注意力被切碎，降低繼續刷下一章意願。
- 「刷題闖關」的核心價值不是功能完整，而是讓使用者很自然地往下一題、下一章前進。
- 需要更清楚的進度回饋與更低摩擦的互動節奏（語音自動播、答題回饋、章節結算）。

### Key Changes（依體驗流程）

#### 1) 進入前：刷題闖關預備視窗（Bottom Sheet）
- 點擊模式卡後先開底部彈出視窗（與測驗模式一致，不再另外插卡片破壞版面節奏）。
- 重設資訊架構，刪除「建議」區塊，保留最重要內容：
  - 大進度百分比
  - 章節時間軸（目前章 / 已完成 / 未來章）
  - 完成章節列表
  - 必要統計（卡片數 / 章節數 / 每章張數）
- 補上時間軸元件與狀態 enum：
  - `_LearnTimelineNode`
  - `_LearnTimelineNodeState`

#### 2) LearnModeScreen 主畫面（極簡化 + 遊戲化）
- 常駐 UI 收斂成「章節 + 進度條 + 題目」。
- 移除重複資訊：
  - 底部固定提示列
  - 章節下方重複連擊/狀態文案
  - 重複的本章 `%` 文字
- 教練提示改為 Snackbar 彈出通知，避免常駐佔位。
- 章節完成改為自訂遊戲化彈窗（亮色、徽章感、動畫、明確 CTA）。

#### 3) 題目與輸入互動（填空題）
- 將英文填字改成較像 Duolingo 的互動形式，後續再改成更密的「底線填字」版，避免橫向拉太長。
- 調整填字排版：
  - 小寫顯示
  - 底線與字母距離優化
  - 移除多餘說明行，騰出題目區空間
  - 題目字體加大
- 重播題目按鈕移到題目右側，避免額外占一行。
- 修正鍵盤關閉後無法再開啟（點底線區可重新喚起鍵盤）。

#### 4) 語音、音效、回饋節奏
- 題目語音改為自動播放（保留重播按鈕）。
- 移除答案朗讀，避免提示過度與干擾作答。
- 新增答對 / 答錯音效（本地音檔），並多輪調整成較可愛、遊戲感版本。
- 新增底部貼底回饋條（答對/答錯）與動畫，改善切題突兀感。
- 題目卡回饋動畫細化：
  - 答對：輕微放大回彈
  - 答錯：小幅左右震動

#### 5) 出題公平性 / 提示策略
- 限制填空題使用情境：只在「看意思拼英文」出填空，避免定義題多義/詞性爭議。
- 提示優先顯示例句，並遮罩答案單字避免直接破梗。
- 多答案容錯（`/`、`、`、`；`、`,`、`|` 等分隔）支援，降低文字比對挫折感。

#### 6) 狀態保存與穩定性修正
- Learn 模式新增章節級進度暫存（退出再進不從頭開始）。
- 修正 `dispose()` 使用 `ref.read(...)` 造成 Riverpod `ConsumerStatefulElement._assertNotDisposed` crash：
  - 改為在 `initState()` 快取 `LocalStorageService`
  - `dispose()` 不再直接碰 `ref`

### Other Fixes（本日順手修正）
- `ProfileEditScreen`：儲存後 `context.pop()` 在某些路由狀態 crash，改成 `router.canPop()` 判斷後再 pop。
- `DashboardScreen`：
  - 未登入卻顯示 email 的判斷修正（只在 email 非空時視為已登入顯示）
  - 修正 `hasSignedInEmail` / `userEmail` 作用域錯誤（避免 undefined identifier）
- `StudyModePickerScreen`：
  - 補齊時間軸元件定義
  - 清除 `_StudyModeCard` 未使用的 `onInfoTap/infoTooltip` 參數

### Files Touched（重點）
- `lib/features/study/screens/learn_mode_screen.dart`
- `lib/features/study/widgets/text_input_question.dart`
- `lib/features/study/screens/study_mode_picker_screen.dart`
- `lib/features/study/utils/fuzzy_match.dart`
- `lib/services/local_storage_service.dart`
- `lib/features/profile/screens/profile_edit_screen.dart`
- `lib/features/home/screens/dashboard_screen.dart`
- `pubspec.yaml`（音效資產/播放相關調整）

### Verification Status
- 本地 `dart analyze` / `dart format` 在這個環境多次 timeout，未完成完整靜態驗證。
- 本日主要靠：
  - 逐點修 compiler/analyzer 錯誤
  - 局部檔案檢查
  - 使用者回報回歸測試（實機/模擬器互動）

### Risks / Follow-ups（下次優先）
- 仍建議補一輪完整 `flutter analyze` 與 smoke test，尤其是：
  - `LearnModeScreen` 大量動畫/狀態切換
  - `TextInputQuestion` 鍵盤與焦點行為
  - `StudyModePickerScreen` 預備視窗在不同卡片數量下的時間軸顯示
- 可再做的 UX 強化：
  - 預備視窗 CTA 固定貼底（內容可捲動、按鈕固定）
  - 章節內題目位置恢復（目前為章節級恢復）
  - 音效設定（開關/音量）入口

## 2026-02-18

### Conversation Voice Pipeline Stabilization (In Progress)
- Refactored conversation voice playback flow toward a deterministic single entry point in:
  - `lib/features/study/screens/conversation_practice_screen.dart`
- Added explicit runtime voice states and diagnostics:
  - state enum: `idle -> preparing -> playing -> completed/error`
  - guard panel badges now show voice state + latest voice path diagnostic.
- Unified playback entry to reduce mixed engine races:
  - first-line auto play
  - AI message tap replay
  - local coach AI-question playback
  all now route through one orchestrator (`_playAiMessage`).
- Tightened first-line replay contract:
  - replay of first line does not trigger remote generation
  - uses AI cache first, then immediate local TTS fallback when cache missing.
- First-line auto play behavior:
  - tries AI cache first
  - optionally attempts remote prepare once
  - falls back to local TTS without blocking UI.

### Verification Status
- Static formatting/analyze commands were attempted from CLI but timed out in this environment.
- Manual runtime verification is still required on device/emulator for:
  - session start first-line auto-play
  - repeated replay taps on first line
  - replay of non-first AI messages
  - back navigation and app background/foreground during playback.

### Storage/Sync Performance Pass (In Progress)
- Reduced repeated full-list reloads in `StudySetsNotifier`:
  - switched `add/update/remove` and small edits (`pin`, `lastStudied`, `folder`) to local state patching instead of full `_load()` each time.
  - added centralized local sorting helper to keep list order stable after local patch updates.
- Reduced startup reconcile write amplification:
  - `_ensureCardProgress` now accumulates missing progress rows and writes with one batch call.
  - orphaned card progress cleanup now batches deletes.
- Added LocalStorage batch APIs and used them in sync flow:
  - batch save/delete/mark-synced methods for study sets/card progress/review logs.
- Optimized sync push path:
  - `_pushUnsynced()` now runs delete/upsert operations in bounded parallel batches instead of fully serial loops.
  - synced-flag updates now use batch methods instead of per-item await loops.

### Security Hardening (Gemini API Key Storage)
- Migrated Gemini API key storage from plain Hive settings to `flutter_secure_storage`.
- Added one-time migration path in provider:
  - read secure storage first
  - if empty, migrate legacy Hive key to secure storage and delete old Hive value.
- Save path now writes to secure storage and cleans any legacy Hive slot.
- Added dependency and refreshed lockfile:
  - `pubspec.yaml`
  - `pubspec.lock`

## 2026-02-17

### Conversation Practice Overhaul (Ongoing)
- Reworked conversation practice into scenario-based roleplay with bilingual context (EN/ZH), role labels, and staged progress guidance.
- Expanded local daily-life scenario pool for more practical, varied sessions.
- Tightened AI prompt style to reduce filler greeting/small-talk and keep questions specific and answerable.
- Added reply-support UX:
  - `Help me reply` button
  - suggestion panel with short usable responses + zh hints
  - reply hint parsing/rendering

### API Guardrails, Quota/429 Handling, and Cost Controls
- Added API fallback and protection logic in conversation screen:
  - rate-limit cooldown
  - per-session chat API cap
  - suggestion API cap + cache
  - local coach fallback when API unstable
- Improved error classification and handling:
  - separate hard quota vs rate limit vs auth-style failures
  - avoid misreporting all failures as quota exhaustion
- Reduced token pressure by shortening chat/suggestion outputs and keeping responses compact.
- Added debug usage logs for rough token/cost visibility (`[AI_USAGE] ...`).

### Layout/Runtime Stability Fixes
- Fixed multiple keyboard overflow issues by constraining bottom composer area and hiding top info panels when keyboard is open.
- Added mounted/disposed guards around async callbacks (`postFrame`, snackbars, STT callbacks, scroll callbacks).
- Fixed end-of-session navigation instability:
  - removed fragile double-pop pattern
  - made summary flow safer to reduce framework assert on back/navigation transitions.
- Added safer input controller usage wrappers to reduce disposed-controller crash risk.

### AI Voice (First-Line) Integration Attempts
- Added new service: `lib/services/ai_tts_service.dart`.
- Added `audioplayers` dependency and implemented Gemini TTS request + audio parsing + playback.
- Implemented multiple fallback paths:
  - AI first-line voice attempt
  - fallback to Flutter TTS when AI voice fails
  - cache-based replay path for first line
- Added playback lock/debounce attempts to reduce TTS/AI player race conditions.

### Current Status (End of Day)
- Text conversation features are significantly improved and usable.
- API fallback/rate-limit handling is much better than before.
- Keyboard overflow is improved but should still be regression-tested on more device sizes.
- **Main unresolved blocker:** first-line AI voice behavior is still inconsistent across session start/replay (sometimes fallback TTS first, sometimes AI replay fails, sometimes no sound after mixed playback attempts).

### Next Session First Actions (Priority)
- Refactor voice pipeline to a single deterministic state machine:
  - one active audio engine at a time
  - explicit states: `idle -> preparing -> playing -> completed/error`
  - no mixed implicit fallback in parallel paths
- Add visible runtime diagnostics in UI for voice path:
  - `AI cache hit`, `AI fetch fail`, `Fallback TTS`, error code preview
- Lock down replay contract:
  - first message replay should never trigger remote generation
  - replay uses cached audio only; if missing, immediate TTS without waiting
- After stabilizing voice path, run focused test passes on:
  - start session
  - first auto-play
  - repeated replay taps
  - background/foreground transitions
  - back navigation during playback

## 2026-02-15

### UI Refactor (Stitch-style, layout-level)
- Reworked core home information architecture to be closer to stitch composition:
  - hero review block
  - quick-action grid
  - task cards
  - study set section
- Refactored major screens beyond color/theme-only changes:
  - `lib/features/home/screens/home_screen.dart`
  - `lib/features/home/screens/search_screen.dart`
  - `lib/features/stats/screens/stats_screen.dart`
  - `lib/features/study/screens/srs_review_screen.dart`
- Refactored key widgets for hierarchy/interaction parity:
  - `lib/features/home/widgets/today_review_card.dart`
  - `lib/features/home/widgets/study_set_card.dart`
  - `lib/features/home/widgets/revenge_card.dart`
  - `lib/features/study/widgets/rating_buttons.dart`
- Validation status:
  - `flutter analyze` passed (full project)
  - `flutter build web` passed

### Supabase Setup & Auth Progress
- Added local runtime define workflow (non-committed secrets):
  - `dart_defines.local.json` (gitignored)
  - `dart_defines.example.json`
  - `tool/run_web_local.ps1`
- Updated `.gitignore` to exclude local define file.
- Verified Supabase project endpoint is reachable and auth settings are active:
  - `disable_signup = false`
  - `email provider = true`
  - `mailer_autoconfirm = false` (email verification required)
- Added auth UX fallback for verification-required scenarios:
  - resend signup confirmation API in `SupabaseService`
  - `Resend` actions in signup/login flow snackbars
  - files:
    - `lib/services/supabase_service.dart`
    - `lib/features/auth/screens/signup_screen.dart`
    - `lib/features/auth/screens/login_screen.dart`

### Current Blocker
- User-reported runtime error: "Supabase 瘝?摰儔" when trying to login.
- Most likely cause: app started without `--dart-define-from-file=dart_defines.local.json` (or wrong launch command).
- Secondary expected behavior: unverified new accounts cannot password-login until email confirmation (because `mailer_autoconfirm = false`).

### Next Session First Actions
- Reproduce login path using exact command:
  - `powershell -ExecutionPolicy Bypass -File tool\\run_web_local.ps1`
- Confirm startup log does NOT print:
  - `Supabase not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.`
- If issue persists, capture and inspect:
  - browser console/network for auth calls
  - exact exception stack from app login submit handler
- Decide auth policy:
  - keep email verification flow
  - or enable autoconfirm in Supabase dashboard for immediate login after signup

## 2026-02-13

### Auth & Security
- Added route guard strategy with protected-route redirect and post-login return path.
- Added OAuth cancel/failure retry UX with explicit retry actions.
- Added centralized Supabase redirect URL handling and mobile deep-link callback wiring.
- Added app lifecycle auth gate:
  - startup session validation
  - auth event-triggered sync
  - biometric quick unlock on resume
- Added Security Center MVP:
  - sign out current device
  - sign out all devices
  - account deletion flow (with re-auth support)

### Data & Sync
- Added sync conflict detection/persistence for local-vs-remote set updates.
- Added conflict resolution actions:
  - Keep Local
  - Keep Remote
  - Merge
- Added encrypted full backup import/export:
  - AES-GCM encryption
  - PBKDF2-derived key from passphrase
  - includes study sets, card progress, review logs

### Verification & Tooling
- Added auth integration tests for login/signup/google/magic-link/guest/logout.
- Added analytics storage tests and sync-conflict service tests.
- Added RLS verification script and dashboard SQL checklist docs.

### Admin Management
- Added Admin Account Management Phase 1 foundation:
  - admin schema migration
  - admin service/provider layer
  - protected `/admin` route + admin console screen
- Added Admin phase 2/3 schema foundation:
  - risk alerts
  - approval requests
  - impersonation sessions
- Added admin runtime workflows in console:
  - pending approval queue with approve/reject actions
  - MFA enforcement approval request creation and approved-job enqueue
  - support impersonation session start/end with ticket id and audit trail
- Added admin phase 3 console workflows:
  - bulk job queue list with status filtering
  - bulk job retry/cancel actions
  - compliance snapshot export (audit/approvals/impersonation/jobs) as JSON payload
- Added admin phase 3 execution migration:
  - `admin_bulk_jobs` execution columns (`attempt_count`, `max_attempts`, `last_error`, `worker_id`, timestamps)
  - RPC helpers: `admin_claim_next_bulk_job(worker)` and `admin_complete_bulk_job(job_id, success, err)`
  - schema verification script for execution migration
- Added admin phase 3 worker execution path:
  - job handler SQL functions: `admin_worker_signout_user`, `admin_worker_enforce_mfa`, `admin_worker_delete_account`
  - edge worker function: `supabase/functions/admin-bulk-worker/index.ts`
  - run tooling and runbook: `scripts/run_admin_bulk_worker.sh`, `docs/admin_bulk_worker_runbook.md`
- Added admin governance automation:
  - SQL functions for stale approval expiry, impersonation expiry, and overdue approval risk alerts
  - edge worker function: `supabase/functions/admin-governance-worker/index.ts`
  - governance run tooling and runbook
- Added GitHub Actions scheduled worker orchestration:
  - `.github/workflows/admin-workers.yml`
  - every 5 minutes for bulk worker, hourly for governance worker
  - webhook alert hook on failures
- Added admin phase 3 hardening migration:
  - approval owner/SLA columns and escalation counters
  - notification route/outbox tables for escalation delivery
  - impersonation telemetry table and revoke function
  - compliance export registry table
- Added admin compliance export worker:
  - `supabase/functions/admin-compliance-export/index.ts`
  - signed JSON/CSV export payload with checksum and signature
  - metadata persistence to `admin_compliance_exports`
- Extended governance worker:
  - auto-assign approval owners
  - queue SLA escalation notifications
  - dispatch webhook outbox messages with sent/failed status updates
- Added compliance/governance operational tooling:
  - `scripts/run_admin_compliance_export.sh`
  - `scripts/check_admin_phase3_hardening_schema.sh`
  - updated runbooks and schedule to include daily compliance export job

### Operations & Handover
- Consolidated deployment run order for admin stack:
  - apply migrations up to `202602130007_admin_sla_telemetry_and_exports.sql`
  - deploy edge workers (`admin-bulk-worker`, `admin-governance-worker`, `admin-compliance-export`)
  - configure function/action secrets and alert webhook
- Documented manual execution commands for operators:
  - `scripts/run_admin_bulk_worker.sh`
  - `scripts/run_admin_governance_worker.sh`
  - `scripts/run_admin_compliance_export.sh`
- Documented admin console usage flow:
  - approvals, impersonation control, bulk jobs, and signed compliance export

## 2026-02-18 - Conversation Scenario Quality + Anti-dup

### Conversation UX/Parsing
- Fixed `conversation_practice_screen.dart` structural syntax corruption introduced by accidental literal text insertion.
- Improved scenario panel bilingual rendering:
  - Default EN display, optional ZH toggle.
  - Only render ZH blocks when content is truly Chinese and not identical to EN.
- Reduced prompt-leak exposure in AI turn parsing by filtering scenario/meta lines from candidate question text.

### Scenario Generation Reliability
- Strengthened generated scenario validation:
  - reject meta/prompt artifacts
  - reject invalid/duplicated role mappings
  - require usable zh fields
- Added AI-first anti-dup strategy:
  - `GeminiService.generateRandomScenario(..., avoidTitles: ...)`
  - recent title memory in provider (`_recentScenarioTitles`)
  - near-duplicate title rejection before accept
  - retry loop with decreasing term count before fallback
- Updated fallback scenario content to remain term-driven and bilingual.

### Notes
- Local sandbox analyze commands timed out during this session; full device-side verify is required in next pass.

## 2026-02-21 - Codex 續作（班級系統 + 學習模式 + 穩定性）

### 資料庫與後端（Classroom MVP）
- 新增 migration：
  - `supabase/migrations/202602210009_classroom_mvp_foundation.sql`
- 建立班級相關資料表：
  - `profiles`
  - `classes`
  - `class_members`
  - `class_sets`
  - `class_assignments`
  - `student_assignment_progress`
- 新增 RLS helper 與存取策略：
  - `is_class_teacher`
  - `is_class_member`
  - `can_access_class`
  - `is_assignment_teacher`
  - `is_assignment_student`
- 新增加入班級 RPC：
  - `join_class_by_invite_code(code text)`（`security definer`）

### Flutter 端（Classroom 功能）
- 新增常數與資料層：
  - `lib/core/constants/supabase_constants.dart`
  - `lib/models/classroom.dart`
  - `lib/services/classroom_service.dart`
  - `lib/providers/classroom_provider.dart`
- 新增頁面與路由：
  - `lib/features/classroom/screens/classes_screen.dart`
  - `lib/features/classroom/screens/class_detail_screen.dart`
  - `lib/features/classroom/screens/class_student_detail_screen.dart`
  - `/classes`
  - `/classes/:classId`
  - `/classes/:classId/student/:studentId`
- `dashboard_screen.dart` 已接入 classes 入口。

### 學習進度同步（作業模式）
- 學生進度狀態支援：
  - `not_started`
  - `in_progress`
  - `completed`
- 作業題組使用 class 專屬 setId 命名：
  - `class_<classId>_<classSetId>`
- Quiz / Match 完成時會回寫 `completed + score`。
- 相關頁面：
  - `lib/features/study/screens/quiz_complete_screen.dart`
  - `lib/features/study/screens/matching_complete_screen.dart`

### 學習模式與提示（Learn/Hint）
- `learn_mode_screen.dart` 調整：
  - 支援更穩定的提交流程與 checkpoint 邏輯。
  - 補強作答狀態與提示次數管理。
- `TextInputQuestion` 新增可配置提示：
  - `enableHint`
  - `maxHints`
  - `onHintUsed`
  - `hintBuilder`

### 穩定性修正
- 修正 conversation practice 的 Riverpod disposed read 問題：
  - `lib/features/study/screens/conversation_practice_screen.dart`
- 備註：本次 session 內 `flutter analyze` / `flutter test` 在 sandbox 有 timeout，需在本機再跑完整驗證。

## 2026-02-21 - 管理員後台：切換老師/學生（續）

### 新增
- 新增 migration：
  - `supabase/migrations/202602210011_admin_manage_classroom_roles.sql`
- 新增 admin RPC：
  - `admin_list_profiles(search_text, row_limit)`：管理員列出 profiles（含 role）
  - `admin_set_profile_role(target_user_id, new_role, reason)`：管理員設定 teacher/student
- 管理後台 UI 已新增：
  - 顯示 `Classroom role`
  - `Set Teacher` / `Set Student` 按鈕

### 程式碼調整
- `lib/services/admin_service.dart`
  - `fetchAccounts()` 改用 `admin_list_profiles`，避免 RLS 看不到他人 profile
  - 新增 `setUserClassroomRole()` 呼叫 `admin_set_profile_role`
- `lib/features/admin/screens/admin_management_screen.dart`
  - 帳號卡片加入角色切換操作
- `lib/models/admin_account_summary.dart`
  - 新增 `classroomRole` 欄位

## 2026-02-21 - 啟動自動關閉排查（Android）

### 今日結論（已定位）
- `F5` 自動關閉的主因不是 Flutter runtime crash，而是 Android 建置期資源編譯失敗。
- 錯誤點：`launch_background.xml` 使用了不合法語法：
  - `<item android:drawable="#F4FAF6" />`
- AAPT 錯誤：`'#F4FAF6' is incompatible with attribute drawable (attr) reference.`

### 今日修正（已完成）
- 已修正以下檔案為合法寫法（`shape + solid`）：
  - `android/app/src/main/res/drawable-v21/launch_background.xml`
  - `android/app/src/main/res/drawable/launch_background.xml`
- 另外補上啟動保護，避免 plugin 初始化失敗直接在 `runApp` 前退出：
  - `lib/main.dart`
  - `lib/services/widget_snapshot_service.dart`

### 你明天的作用（照這份跑即可）
- 你是「驗證者 + 決策者」，不用重寫程式。
- 你的任務只有三件事：
  - 重新 `F5`，確認是否已能啟動。
  - 若失敗，貼「第一段錯誤」與 `Exited (...)` 前 20 行。
  - 若成功，回報「已進首頁」並指定下一個要優先收斂的議題（例如 classroom、admin、learn UX）。

### 明天第一輪操作清單（最短路徑）
1. 在 VS Code 按 `F5`（使用 `Flutter (local defines)`）。
2. 若失敗：直接回貼 Debug Console 首段錯誤（不要摘要）。
3. 若成功：做一次冷啟動 + 熱重啟，確認都不會自動退出。
4. 回報結果，進入下一個修復項目。

### 完成條件（DoD）
- Android debug 可連續啟動 2 次不自動關閉。
- 不再出現 `processDebugResources` / `Android resource linking failed`。




