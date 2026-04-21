-- Public study sets table for community sharing
create table if not exists public_study_sets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  study_set_id uuid not null,
  title text not null,
  description text default '',
  cards jsonb default '[]'::jsonb,
  author_name text default '',
  tags text[] default '{}',
  download_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes
create index if not exists idx_public_study_sets_user_id
  on public_study_sets(user_id);
create index if not exists idx_public_study_sets_download_count
  on public_study_sets(download_count desc);
create index if not exists idx_public_study_sets_created_at
  on public_study_sets(created_at desc);

-- Unique constraint: one user can only publish a study set once
create unique index if not exists idx_public_study_sets_user_set
  on public_study_sets(user_id, study_set_id);

-- RLS: everyone can read, only owners can write
alter table public_study_sets enable row level security;

create policy "Anyone can read public study sets"
  on public_study_sets for select
  using (true);

create policy "Users can insert own public study sets"
  on public_study_sets for insert
  with check (auth.uid() = user_id);

create policy "Users can update own public study sets"
  on public_study_sets for update
  using (auth.uid() = user_id);

create policy "Users can delete own public study sets"
  on public_study_sets for delete
  using (auth.uid() = user_id);

-- Function to increment download count
create or replace function increment_download_count(set_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update public_study_sets
    set download_count = download_count + 1
    where id = set_id;
end;
$$;
