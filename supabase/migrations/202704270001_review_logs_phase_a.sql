-- Phase A: extend review_logs with session linkage and telemetry fields.
-- Phase 0 already added review_type and speaking_score.
-- This migration adds the remaining Phase A fields.

alter table public.review_logs
  add column if not exists session_id uuid null,
  add column if not exists response_latency_ms integer null,
  add column if not exists chosen_distractor_id text null,
  add column if not exists predicted_retrievability double precision null,
  add column if not exists metadata jsonb null;

-- FK to review_sessions (created in next migration)
-- Added as a deferred constraint so migration order is not strict.
-- Uncomment after 202704270002 is applied:
-- alter table public.review_logs
--   add constraint fk_review_logs_session
--   foreign key (session_id) references public.review_sessions(id)
--   on delete set null;

-- Index for session-based analytics
create index if not exists idx_review_logs_session_id
  on public.review_logs (session_id)
  where session_id is not null;

comment on column public.review_logs.session_id is
  'FK to review_sessions.id. Groups logs by learning session.';
comment on column public.review_logs.response_latency_ms is
  'Milliseconds from card display to user response. Used for ACE telemetry.';
comment on column public.review_logs.chosen_distractor_id is
  'The distractor card id the user selected on a wrong quiz answer. Used for confusion_edges.';
comment on column public.review_logs.predicted_retrievability is
  'FSRS-computed retrievability (0-1) at the time of review.';
comment on column public.review_logs.metadata is
  'Extensible JSON blob for future telemetry without schema migrations.';
