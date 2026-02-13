-- Admin phase 3 hardening:
-- 1) approval owner + SLA escalation outbox
-- 2) impersonation revoke + telemetry stream
-- 3) compliance export metadata registry

alter table public.admin_approval_requests
  add column if not exists owner_admin_user_id uuid null references auth.users(id),
  add column if not exists sla_due_at timestamptz null,
  add column if not exists escalated_at timestamptz null,
  add column if not exists escalation_count int not null default 0;

create index if not exists idx_admin_approval_requests_owner_status
  on public.admin_approval_requests(owner_admin_user_id, status, created_at desc);

create table if not exists public.admin_notification_routes (
  id bigserial primary key,
  channel text not null, -- webhook | email | slack
  destination text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_notification_outbox (
  id bigserial primary key,
  channel text not null, -- webhook | email | slack
  destination text not null,
  subject text not null default '',
  body text not null default '',
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending', -- pending | sent | failed
  attempts int not null default 0,
  last_error text not null default '',
  created_at timestamptz not null default now(),
  sent_at timestamptz null
);

create index if not exists idx_admin_notification_outbox_status_created
  on public.admin_notification_outbox(status, created_at asc);

create table if not exists public.admin_impersonation_telemetry (
  id bigserial primary key,
  session_id bigint not null references public.admin_impersonation_sessions(id) on delete cascade,
  actor_user_id uuid not null references auth.users(id),
  target_user_id uuid not null references auth.users(id),
  event_type text not null, -- started | heartbeat | ended | revoked | note
  event_message text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_impersonation_telemetry_session_created
  on public.admin_impersonation_telemetry(session_id, created_at desc);

create table if not exists public.admin_compliance_exports (
  id bigserial primary key,
  generated_by uuid not null references auth.users(id),
  format text not null, -- json | csv
  window_days int not null,
  file_name text not null,
  signature text not null,
  checksum_sha256 text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_compliance_exports_created
  on public.admin_compliance_exports(created_at desc);

alter table public.admin_notification_routes enable row level security;
alter table public.admin_notification_outbox enable row level security;
alter table public.admin_impersonation_telemetry enable row level security;
alter table public.admin_compliance_exports enable row level security;

drop policy if exists "admin_notification_routes_global_admin_all" on public.admin_notification_routes;
create policy "admin_notification_routes_global_admin_all"
on public.admin_notification_routes
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_notification_outbox_global_admin_all" on public.admin_notification_outbox;
create policy "admin_notification_outbox_global_admin_all"
on public.admin_notification_outbox
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_impersonation_telemetry_global_admin_all" on public.admin_impersonation_telemetry;
create policy "admin_impersonation_telemetry_global_admin_all"
on public.admin_impersonation_telemetry
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

drop policy if exists "admin_compliance_exports_global_admin_all" on public.admin_compliance_exports;
create policy "admin_compliance_exports_global_admin_all"
on public.admin_compliance_exports
for all
using (public.is_global_admin(auth.uid()))
with check (public.is_global_admin(auth.uid()));

create or replace function public.admin_assign_approval_owners(
  default_owner uuid default null,
  sla_hours int default 24
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_owner uuid;
  affected_count int := 0;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  selected_owner := default_owner;
  if selected_owner is null then
    select arb.admin_user_id
    into selected_owner
    from public.admin_role_bindings arb
    where arb.scope_type = 'global'
      and arb.role_key in ('support_admin', 'org_admin', 'super_admin')
    order by arb.created_at asc
    limit 1;
  end if;

  if selected_owner is null then
    return 0;
  end if;

  update public.admin_approval_requests
  set owner_admin_user_id = selected_owner,
      sla_due_at = coalesce(sla_due_at, created_at + make_interval(hours => sla_hours))
  where status = 'pending'
    and owner_admin_user_id is null;

  get diagnostics affected_count = row_count;
  return affected_count;
end;
$$;

create or replace function public.admin_enqueue_sla_escalation_notifications(
  overdue_hours int default 24,
  channel text default 'webhook'
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count int := 0;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  with overdue as (
    select
      ar.id,
      ar.requested_by,
      ar.owner_admin_user_id,
      ar.action_type,
      ar.reason,
      ar.created_at,
      coalesce(ar.sla_due_at, ar.created_at + make_interval(hours => overdue_hours)) as due_at
    from public.admin_approval_requests ar
    where ar.status = 'pending'
      and coalesce(ar.sla_due_at, ar.created_at + make_interval(hours => overdue_hours)) < now()
      and (ar.escalated_at is null or ar.escalated_at < now() - interval '6 hours')
  ),
  queued as (
    insert into public.admin_notification_outbox(
      channel,
      destination,
      subject,
      body,
      payload,
      status
    )
    select
      lower(channel),
      nr.destination,
      format('[SLA] Approval Request %s Overdue', o.id),
      format(
        'Approval %s (%s) is overdue. owner=%s requested_by=%s created_at=%s due_at=%s',
        o.id,
        o.action_type,
        coalesce(o.owner_admin_user_id::text, '-'),
        o.requested_by::text,
        o.created_at::text,
        o.due_at::text
      ),
      jsonb_build_object(
        'request_id', o.id,
        'action_type', o.action_type,
        'owner_admin_user_id', o.owner_admin_user_id,
        'requested_by', o.requested_by,
        'created_at', o.created_at,
        'due_at', o.due_at
      ),
      'pending'
    from overdue o
    join public.admin_notification_routes nr
      on nr.is_active = true and lower(nr.channel) = lower(channel)
    returning id
  )
  select count(*) into inserted_count from queued;

  update public.admin_approval_requests ar
  set escalated_at = now(),
      escalation_count = ar.escalation_count + 1
  where ar.id in (
    select o.id
    from public.admin_approval_requests o
    where o.status = 'pending'
      and coalesce(o.sla_due_at, o.created_at + make_interval(hours => overdue_hours)) < now()
      and (o.escalated_at is null or o.escalated_at < now() - interval '6 hours')
  );

  return inserted_count;
end;
$$;

create or replace function public.admin_revoke_impersonation_session(
  session_id bigint,
  revoke_reason text default 'manual_revoke'
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  rec public.admin_impersonation_sessions%rowtype;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  update public.admin_impersonation_sessions
  set status = 'revoked',
      ended_at = coalesce(ended_at, now())
  where id = session_id
    and status = 'active';

  if not found then
    return false;
  end if;

  select * into rec from public.admin_impersonation_sessions where id = session_id;

  insert into public.admin_impersonation_telemetry(
    session_id,
    actor_user_id,
    target_user_id,
    event_type,
    event_message,
    metadata
  )
  values (
    rec.id,
    rec.actor_user_id,
    rec.target_user_id,
    'revoked',
    revoke_reason,
    jsonb_build_object('status', rec.status, 'ended_at', rec.ended_at)
  );

  insert into public.admin_audit_logs(actor_user_id, target_user_id, action, reason, metadata)
  values (
    coalesce(auth.uid(), rec.actor_user_id),
    rec.target_user_id,
    'revoke_impersonation',
    revoke_reason,
    jsonb_build_object('session_id', rec.id)
  );

  return true;
end;
$$;
