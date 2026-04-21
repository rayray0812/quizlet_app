-- Community reports table for moderation
create table if not exists community_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  public_set_id uuid not null references public_study_sets(id) on delete cascade,
  reason text not null default '',
  details text default '',
  status text not null default 'pending', -- pending, reviewed, dismissed
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_community_reports_status
  on community_reports(status);
create index if not exists idx_community_reports_public_set_id
  on community_reports(public_set_id);

-- Unique: one user can only report a specific set once
create unique index if not exists idx_community_reports_unique
  on community_reports(reporter_id, public_set_id);

-- RLS
alter table community_reports enable row level security;

create policy "Users can insert own reports"
  on community_reports for insert
  with check (auth.uid() = reporter_id);

create policy "Users can read own reports"
  on community_reports for select
  using (auth.uid() = reporter_id);

-- Add category column to public_study_sets for content discovery
alter table public_study_sets
  add column if not exists category text default '';

create index if not exists idx_public_study_sets_category
  on public_study_sets(category);

-- Function to fetch user public profile stats
create or replace function get_user_public_stats(target_user_id uuid)
returns json
language plpgsql
security definer
as $$
declare
  result json;
begin
  select json_build_object(
    'published_count', count(*),
    'total_downloads', coalesce(sum(download_count), 0)
  ) into result
  from public_study_sets
  where user_id = target_user_id;
  return result;
end;
$$;
