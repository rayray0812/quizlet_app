-- Admin account management foundation schema
-- Apply after base auth/sync schema migrations.

create table if not exists public.admin_roles (
  id bigserial primary key,
  role_key text not null unique,
  description text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.admin_role_bindings (
  id bigserial primary key,
  admin_user_id uuid not null references auth.users(id) on delete cascade,
  role_key text not null references public.admin_roles(role_key) on delete cascade,
  scope_type text not null default 'global', -- global | org | group
  scope_id text null,
  created_by uuid null references auth.users(id),
  created_at timestamptz not null default now(),
  unique (admin_user_id, role_key, scope_type, scope_id)
);

create table if not exists public.admin_audit_logs (
  id bigserial primary key,
  actor_user_id uuid not null references auth.users(id),
  target_user_id uuid null references auth.users(id),
  action text not null,
  reason text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_account_blocks (
  id bigserial primary key,
  target_user_id uuid not null references auth.users(id) on delete cascade,
  blocked_by uuid not null references auth.users(id),
  reason text not null default '',
  blocked_until timestamptz null,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_bulk_jobs (
  id bigserial primary key,
  actor_user_id uuid not null references auth.users(id),
  job_type text not null, -- disable_users | signout_users | assign_role | etc
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending', -- pending | running | done | failed
  summary text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_admin_role_bindings_user
  on public.admin_role_bindings(admin_user_id);

create index if not exists idx_admin_audit_logs_actor_created
  on public.admin_audit_logs(actor_user_id, created_at desc);

create index if not exists idx_admin_audit_logs_target_created
  on public.admin_audit_logs(target_user_id, created_at desc);

create index if not exists idx_admin_bulk_jobs_actor_created
  on public.admin_bulk_jobs(actor_user_id, created_at desc);

-- RLS
alter table public.admin_roles enable row level security;
alter table public.admin_role_bindings enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.admin_account_blocks enable row level security;
alter table public.admin_bulk_jobs enable row level security;

-- Helper: check whether auth user is a global admin
create or replace function public.is_global_admin(uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.admin_role_bindings arb
    where arb.admin_user_id = uid
      and arb.scope_type = 'global'
      and arb.role_key in ('super_admin', 'org_admin')
  );
$$;

-- Policies: only global admins can read/write admin tables
drop policy if exists "admin_roles_global_admin_all" on public.admin_roles;
create policy "admin_roles_global_admin_all"
on public.admin_roles
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_role_bindings_global_admin_all" on public.admin_role_bindings;
create policy "admin_role_bindings_global_admin_all"
on public.admin_role_bindings
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_audit_logs_global_admin_all" on public.admin_audit_logs;
create policy "admin_audit_logs_global_admin_all"
on public.admin_audit_logs
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_account_blocks_global_admin_all" on public.admin_account_blocks;
create policy "admin_account_blocks_global_admin_all"
on public.admin_account_blocks
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_bulk_jobs_global_admin_all" on public.admin_bulk_jobs;
create policy "admin_bulk_jobs_global_admin_all"
on public.admin_bulk_jobs
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

-- Seed roles
insert into public.admin_roles(role_key, description)
values
  ('super_admin', 'Global full-access admin'),
  ('org_admin', 'Organization-scoped admin'),
  ('support_admin', 'Support operations admin'),
  ('readonly_auditor', 'Read-only auditor')
on conflict (role_key) do nothing;
