-- Recall app sync schema
-- Apply in Supabase SQL editor or via Supabase CLI migrations.

create extension if not exists pgcrypto;

-- Keep updated_at fresh on updates.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.study_sets (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  title text not null,
  description text not null default '',
  cards jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.card_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id text not null,
  set_id text not null,
  stability double precision not null default 0,
  difficulty double precision not null default 0,
  reps integer not null default 0,
  lapses integer not null default 0,
  state integer not null default 0,
  last_review timestamptz null,
  due timestamptz null,
  scheduled_days integer not null default 0,
  elapsed_days integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, card_id),
  constraint fk_card_progress_set
    foreign key (user_id, set_id)
    references public.study_sets (user_id, id)
    on delete cascade
);

create table if not exists public.review_logs (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  card_id text not null,
  set_id text not null,
  rating integer not null check (rating between 1 and 4),
  state integer not null,
  reviewed_at timestamptz not null,
  elapsed_days integer not null default 0,
  scheduled_days integer not null default 0,
  last_stability double precision not null default 0,
  last_difficulty double precision not null default 0,
  created_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint fk_review_logs_set
    foreign key (user_id, set_id)
    references public.study_sets (user_id, id)
    on delete cascade
);

create index if not exists idx_study_sets_user_updated_at
  on public.study_sets (user_id, updated_at desc);

create index if not exists idx_card_progress_user_set
  on public.card_progress (user_id, set_id);

create index if not exists idx_card_progress_user_due
  on public.card_progress (user_id, due);

create index if not exists idx_review_logs_user_set_reviewed_at
  on public.review_logs (user_id, set_id, reviewed_at desc);

drop trigger if exists trg_study_sets_updated_at on public.study_sets;
create trigger trg_study_sets_updated_at
before update on public.study_sets
for each row execute function public.set_updated_at();

drop trigger if exists trg_card_progress_updated_at on public.card_progress;
create trigger trg_card_progress_updated_at
before update on public.card_progress
for each row execute function public.set_updated_at();

alter table public.study_sets enable row level security;
alter table public.card_progress enable row level security;
alter table public.review_logs enable row level security;

drop policy if exists "study_sets_owner_all" on public.study_sets;
create policy "study_sets_owner_all"
on public.study_sets
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "card_progress_owner_all" on public.card_progress;
create policy "card_progress_owner_all"
on public.card_progress
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "review_logs_owner_all" on public.review_logs;
create policy "review_logs_owner_all"
on public.review_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
