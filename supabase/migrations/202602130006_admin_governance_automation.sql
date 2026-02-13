-- Admin governance automation foundation
-- Covers stale approval expiry, impersonation expiry, and overdue approval alerts.

create or replace function public.admin_expire_stale_approval_requests(
  max_age_hours int default 72
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_count int := 0;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  with target as (
    update public.admin_approval_requests
    set status = 'expired'
    where status = 'pending'
      and created_at < now() - make_interval(hours => max_age_hours)
    returning id, requested_by, action_type
  )
  insert into public.admin_audit_logs(actor_user_id, target_user_id, action, reason, metadata)
  select
    coalesce(auth.uid(), requested_by),
    requested_by,
    'expire_approval_request',
    'governance_worker',
    jsonb_build_object('request_id', id, 'action_type', action_type)
  from target;

  get diagnostics affected_count = row_count;
  return affected_count;
end;
$$;

create or replace function public.admin_expire_impersonation_sessions()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_count int := 0;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  with target as (
    update public.admin_impersonation_sessions
    set status = 'expired',
        ended_at = coalesce(ended_at, now())
    where status = 'active'
      and expires_at < now()
    returning id, actor_user_id, target_user_id
  )
  insert into public.admin_audit_logs(actor_user_id, target_user_id, action, reason, metadata)
  select
    coalesce(auth.uid(), actor_user_id),
    target_user_id,
    'expire_impersonation_session',
    'governance_worker',
    jsonb_build_object('session_id', id)
  from target;

  get diagnostics affected_count = row_count;
  return affected_count;
end;
$$;

create or replace function public.admin_raise_overdue_approval_alerts(
  overdue_hours int default 24
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

  insert into public.admin_risk_alerts(
    target_user_id,
    risk_type,
    severity,
    status,
    summary,
    metadata
  )
  select
    ar.requested_by,
    'approval_overdue',
    'high',
    'open',
    format(
      'Approval request %s pending for more than %s hours.',
      ar.id,
      overdue_hours
    ),
    jsonb_build_object(
      'request_id', ar.id,
      'action_type', ar.action_type,
      'created_at', ar.created_at
    )
  from public.admin_approval_requests ar
  where ar.status = 'pending'
    and ar.created_at < now() - make_interval(hours => overdue_hours)
    and not exists (
      select 1
      from public.admin_risk_alerts ra
      where ra.risk_type = 'approval_overdue'
        and ra.status in ('open', 'triaged')
        and ra.metadata ->> 'request_id' = ar.id::text
    );

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;
