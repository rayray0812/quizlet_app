-- Phase 0 Hotfix: extend review_logs to carry non-SRS modality data
-- Background: local ReviewLog model has reviewType ('srs' / 'speaking' /
-- 'conversation') and speakingScore, but the original schema dropped them
-- silently on sync. Result: switching devices erased speaking/conversation
-- detail; Supabase analytics could only see SRS.
--
-- This migration is the minimum surface to stop data loss. Phase A will
-- add session_id, response_latency_ms, chosen_distractor_id, predicted_*,
-- and a review_sessions table.

alter table public.review_logs
  add column if not exists review_type text not null default 'srs',
  add column if not exists speaking_score smallint null;

-- Index for analytics queries that filter by modality
create index if not exists idx_review_logs_user_review_type
  on public.review_logs (user_id, review_type);

comment on column public.review_logs.review_type is
  'Modality of the review event: srs | speaking | conversation. Defaults to srs for backward compatibility.';
comment on column public.review_logs.speaking_score is
  'Score 0-100 for speaking/conversation modes; null for srs.';
