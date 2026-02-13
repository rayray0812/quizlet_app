-- Admin phase 2/3 foundation: risk alerts, approvals, impersonation boundaries

create table if not exists public.admin_risk_alerts (
  id bigserial primary key,
  target_user_id uuid not null references auth.users(id) on delete cascade,
  risk_type text not null, -- unusual_geo | brute_force | device_drift | etc
  severity text not null default 'medium', -- low | medium | high | critical
  status text not null default 'open', -- open | triaged | resolved | dismissed
  summary text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  resolved_at timestamptz null,
  resolved_by uuid null references auth.users(id)
);

create table if not exists public.admin_impersonation_sessions (
  id bigserial primary key,
  actor_user_id uuid not null references auth.users(id),
  target_user_id uuid not null references auth.users(id),
  ticket_id text not null,
  reason text not null default '',
  started_at timestamptz not null default now(),
  ended_at timestamptz null,
  expires_at timestamptz not null,
  status text not null default 'active', -- active | ended | expired | revoked
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.admin_approval_requests (
  id bigserial primary key,
  requested_by uuid not null references auth.users(id),
  action_type text not null, -- delete_account | bulk_disable | role_grant | etc
  payload jsonb not null default '{}'::jsonb,
  reason text not null default '',
  status text not null default 'pending', -- pending | approved | rejected | expired
  approved_by uuid null references auth.users(id),
  approved_at timestamptz null,
  rejected_by uuid null references auth.users(id),
  rejected_at timestamptz null,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_risk_alerts_status_created
  on public.admin_risk_alerts(status, created_at desc);

create index if not exists idx_admin_impersonation_actor_status
  on public.admin_impersonation_sessions(actor_user_id, status, started_at desc);

create index if not exists idx_admin_approval_requests_status_created
  on public.admin_approval_requests(status, created_at desc);

alter table public.admin_risk_alerts enable row level security;
alter table public.admin_impersonation_sessions enable row level security;
alter table public.admin_approval_requests enable row level security;

drop policy if exists "admin_risk_alerts_global_admin_all" on public.admin_risk_alerts;
create policy "admin_risk_alerts_global_admin_all"
on public.admin_risk_alerts
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_impersonation_global_admin_all" on public.admin_impersonation_sessions;
create policy "admin_impersonation_global_admin_all"
on public.admin_impersonation_sessions
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_approval_requests_global_admin_all" on public.admin_approval_requests;
create policy "admin_approval_requests_global_admin_all"
on public.admin_approval_requests
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));
