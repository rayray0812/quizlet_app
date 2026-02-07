# Recall

A cross-platform flashcard app for efficient learning and review.

## Getting Started

1. Install Flutter SDK.
2. Run `flutter pub get`.
3. Run the app with `--dart-define` values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=UNSPLASH_ACCESS_KEY=YOUR_UNSPLASH_ACCESS_KEY
```

If Supabase defines are not provided, the app runs in local/offline mode.

## Supabase Schema

- Migration file: `supabase/migrations/202602070001_sync_schema.sql`
- Required tables with RLS:
  - `study_sets`
  - `card_progress`
  - `review_logs`

## Product Specs

- Review widgets (Duolingo-style): `docs/review_widgets_spec.md`

## Targets

- Android
- iOS
- Web
