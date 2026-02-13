-- Admin phase 3: concrete job handlers for worker execution
-- These functions are callable by service role (edge worker) and global admins.

create or replace function public.admin_worker_signout_user(
  target_user_id uuid,
  actor_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_sessions int := 0;
  resolved_actor uuid;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  resolved_actor := coalesce(actor_user_id, auth.uid(), target_user_id);

  delete from auth.sessions
  where user_id = target_user_id;
  get diagnostics deleted_sessions = row_count;

  insert into public.admin_audit_logs(actor_user_id, target_user_id, action, reason, metadata)
  values (
    resolved_actor,
    target_user_id,
    'worker_signout_user',
    'bulk job execution',
    jsonb_build_object('deleted_sessions', deleted_sessions)
  );

  return jsonb_build_object(
    'target_user_id', target_user_id,
    'deleted_sessions', deleted_sessions
  );
end;
$$;

create or replace function public.admin_worker_enforce_mfa(
  target_user_id uuid,
  actor_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_actor uuid;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  resolved_actor := coalesce(actor_user_id, auth.uid(), target_user_id);

  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object(
    'mfa_required', true,
    'mfa_enforced_at', now()
  )
  where id = target_user_id;

  insert into public.admin_audit_logs(actor_user_id, target_user_id, action, reason, metadata)
  values (
    resolved_actor,
    target_user_id,
    'worker_enforce_mfa',
    'bulk job execution',
    '{}'::jsonb
  );

  return jsonb_build_object(
    'target_user_id', target_user_id,
    'mfa_required', true
  );
end;
$$;

create or replace function public.admin_worker_delete_account(
  target_user_id uuid,
  actor_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_actor uuid;
  deleted_sets int := 0;
  deleted_progress int := 0;
  deleted_logs int := 0;
  deleted_auth_users int := 0;
begin
  if auth.role() <> 'service_role' and not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  resolved_actor := coalesce(actor_user_id, auth.uid(), target_user_id);

  delete from public.review_logs where user_id = target_user_id;
  get diagnostics deleted_logs = row_count;

  delete from public.card_progress where user_id = target_user_id;
  get diagnostics deleted_progress = row_count;

  delete from public.study_sets where user_id = target_user_id;
  get diagnostics deleted_sets = row_count;

  delete from auth.users where id = target_user_id;
  get diagnostics deleted_auth_users = row_count;

  insert into public.admin_audit_logs(actor_user_id, target_user_id, action, reason, metadata)
  values (
    resolved_actor,
    target_user_id,
    'worker_delete_account',
    'bulk job execution',
    jsonb_build_object(
      'deleted_sets', deleted_sets,
      'deleted_progress', deleted_progress,
      'deleted_logs', deleted_logs,
      'deleted_auth_users', deleted_auth_users
    )
  );

  return jsonb_build_object(
    'target_user_id', target_user_id,
    'deleted_sets', deleted_sets,
    'deleted_progress', deleted_progress,
    'deleted_logs', deleted_logs,
    'deleted_auth_users', deleted_auth_users
  );
end;
$$;
