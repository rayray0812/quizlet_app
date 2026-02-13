# RLS Verification Guide

This project expects owner-only RLS policies for:
- `public.study_sets`
- `public.card_progress`
- `public.review_logs`

## 1) Static migration check

Run:

```bash
./scripts/check_rls_policies.sh
```

Expected output:

```text
RLS check passed for supabase/migrations/202602070001_sync_schema.sql
```

## 2) Dashboard SQL checks

Run in Supabase SQL editor:

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('study_sets', 'card_progress', 'review_logs')
order by tablename;
```

`rowsecurity` should be `true` for all three tables.

```sql
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('study_sets', 'card_progress', 'review_logs')
order by tablename, policyname;
```

Each table should have an owner policy with:
- `qual` containing `auth.uid() = user_id`
- `with_check` containing `auth.uid() = user_id`

## 3) Runtime smoke test checklist

1. Sign in as User A and create/update study data.
2. Sign in as User B and verify User A data is not readable.
3. Sign in as User B and verify writes cannot spoof `user_id` as User A.
4. Verify app sync calls succeed for own rows and fail for cross-user rows.
