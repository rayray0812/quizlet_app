-- Folders sync schema
-- Apply in Supabase SQL editor or via Supabase CLI migrations.

create table if not exists public.folders (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  name text not null,
  color_hex text not null default 'FF6366F1',
  icon_code_point integer not null default 59076, -- default icon
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists idx_folders_user_updated_at
  on public.folders (user_id, updated_at desc);

drop trigger if exists trg_folders_updated_at on public.folders;
create trigger trg_folders_updated_at
before update on public.folders
for each row execute function public.set_updated_at();

alter table public.folders enable row level security;

drop policy if exists "folders_owner_all" on public.folders;
create policy "folders_owner_all"
on public.folders
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
