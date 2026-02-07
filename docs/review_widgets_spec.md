# Review Widgets Spec (Duolingo-style)

Version: v1  
Updated: 2026-02-07

## Goal
Build lively home-screen widgets that strongly nudge users to review due flashcards with clear CTA, emotional tone, and streak protection.

## Shared Data Contract
All widget variants should consume the same snapshot payload.

```json
{
  "generatedAt": "2026-02-07T12:00:00Z",
  "dueTotal": 18,
  "dueNew": 6,
  "dueLearning": 5,
  "dueReview": 7,
  "todayReviewed": 24,
  "streakDays": 5,
  "estimatedMinutes": 9,
  "topSets": [
    {"setId":"bio_1","title":"Biology","due":8},
    {"setId":"eng_2","title":"English","due":6},
    {"setId":"hist_3","title":"History","due":4}
  ],
  "nextDueCard": {
    "setId":"bio_1",
    "cardId":"c_101",
    "term":"photosynthesis",
    "definition":"process used by plants to convert light into energy"
  }
}
```

### Mapping (Existing App Sources)
- `dueTotal`: `dueCountProvider`
- `dueNew/dueLearning/dueReview`: `dueBreakdownProvider`
- `todayReviewed`: `todayReviewCountProvider`
- `streakDays`: `streakProvider`
- `topSets`: local aggregation from `studySetsProvider + dueCardsProvider`
- `nextDueCard`: first due card after deterministic shuffle (seed by day)

## Widget Family Designs

### W1. Daily Mission Card (Primary)
- Sizes:
  - Android: `2x2`, `4x2`
  - iOS: `systemSmall`, `systemMedium`
- UI:
  - Mascot mood + big due count
  - Subtext: estimated minutes + streak
  - Primary CTA button: `Review 5`
  - Secondary CTA: `Quick Review`
- Mood states:
  - `dueTotal = 0`: celebratory
  - `1..10`: normal alert
  - `>10`: urgent
- Deep links:
  - `recall://review?mode=quick&count=5`
  - `recall://review`

### W2. Pressure Progress Bar
- Sizes:
  - Android: `4x1`
  - iOS: `systemMedium`
- UI:
  - Bar for daily target completion
  - Remaining cards text: `3 left to finish today`
  - Single tap area opens `/review`
- Deep link:
  - `recall://review`

### W3. Surprise Word Card
- Sizes:
  - Android: `2x2`
  - iOS: `systemSmall`
- UI:
  - One due term + tiny hint
  - Two actions: `Know` / `Not sure`
- Behavior:
  - Tapping action opens app and preloads that card in SRS queue
- Deep link:
  - `recall://review?cardId={cardId}&setId={setId}`

### W4. Sprint Launcher
- Sizes:
  - Android: `4x2`
  - iOS: `systemMedium`, `systemLarge`
- UI:
  - Three blocks: `5m`, `10m`, `20m`
  - Show approximate card count for each sprint
- Deep links:
  - `recall://review?session=sprint5`
  - `recall://review?session=sprint10`
  - `recall://review?session=sprint20`

### W5. Set Priority Carousel
- Sizes:
  - Android: `4x2` (manual next/prev)
  - iOS: `systemLarge`
- UI:
  - Top 3 sets by due count
  - Badges: `New`, `Learning`, `Review`
- Deep links:
  - `recall://study/{setId}/srs`

### W6. Mood Pet Widget
- Sizes:
  - Android: `2x2`
  - iOS: `accessoryRectangular` + `systemSmall`
- UI:
  - Mascot + short line only
  - Urgency-based expression and copy
- Deep link:
  - `recall://review`

## Refresh Strategy

### Baseline Schedule
- Periodic refresh every 30 minutes.
- Additional refresh at local times:
  - 08:00
  - 12:30
  - 18:30
  - 21:00

### Event-driven Refresh
Trigger immediate widget reload when:
- SRS answer submitted (`_onRate` success path)
- Review session completed (`/review/summary` reached)
- Study set edited/imported
- Notification preference changed

### Staleness Rules
- If data older than 2 hours: show subtle stale badge.
- If no due cards: switch to celebration style + optional `Browse` CTA.

## Copy Tone Rules (Duolingo-style)
- Use short, imperative lines.
- Favor action verbs: `Review`, `Protect`, `Keep`, `Finish`.
- Keep max 18 characters for primary line in small widgets.
- Urgent copy only when `dueTotal > 10` or `streakDays > 0 && dueTotal > 0`.

### Example Copy Bank
- Calm:
  - `5 cards. Easy win.`
  - `2 minutes to keep streak.`
- Urgent:
  - `Streak in danger.`
  - `12 cards waiting.`
- Celebration:
  - `All clear today!`
  - `You nailed it.`

## Deep Link Contract

Use app scheme:
- `recall://review`
- `recall://review?mode=quick&count=5`
- `recall://review?session=sprint10`
- `recall://review?setId={setId}&cardId={cardId}`
- `recall://study/{setId}/srs`

Router requirement:
- Parse query params and route to existing screens:
  - `/review`
  - `/study/:setId/srs`

## Platform Split

### Android (AppWidget)
- Add:
  - `android/app/src/main/kotlin/.../widgets/`
  - `android/app/src/main/res/layout/` widget XMLs
  - `AndroidManifest.xml` receivers + intent filters
- Implement:
  - `DailyMissionWidgetProvider`
  - `PressureBarWidgetProvider`
  - `SprintWidgetProvider`
- Data bridge:
  - Persist snapshot JSON to `SharedPreferences`
  - Widget provider reads snapshot + binds `RemoteViews`
- Update triggers:
  - `AlarmManager` periodic
  - `BroadcastReceiver` on app event intents

### iOS (WidgetKit)
- Add iOS Widget Extension target (SwiftUI):
  - Timeline provider + intent configuration
- Implement widget families:
  - Small/Medium/Large + accessory variants
- Data bridge:
  - App Group shared container JSON file
- Update triggers:
  - `WidgetCenter.shared.reloadAllTimelines()`
  - timeline entries at scheduled times

## Flutter-side Task List

### Data Snapshot Service
- Create `lib/services/widget_snapshot_service.dart`
- Responsibilities:
  - read providers/services
  - compute payload
  - write payload to platform stores

### Widget Event Hooks
- Call snapshot refresh on:
  - SRS rating submit
  - Review summary enter
  - set add/edit/delete/import

### Platform Channel
- Add `WidgetBridge` API:
  - `saveSnapshot(String json)`
  - `requestRefresh()`

## Telemetry (Optional but Recommended)
- Track:
  - widget impressions
  - widget click-through
  - session starts from widget
  - same-day review completion after widget click

## Phased Rollout

### Phase 1 (1 week)
- Ship W1 + W2 only.
- Implement shared snapshot + deep links + refresh schedule.

### Phase 2 (1 week)
- Add W4 sprint launcher.
- Tune copy and urgency thresholds.

### Phase 3 (later)
- Add W3/W5/W6 with richer assets and personalization.

