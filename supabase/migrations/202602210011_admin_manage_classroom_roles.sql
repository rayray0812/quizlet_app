-- Admin can manage classroom role (teacher/student) for any user profile.

create or replace function public.admin_list_profiles(
  search_text text default '',
  row_limit integer default 500
)
returns table(
  user_id uuid,
  role text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  normalized_search text;
  safe_limit integer;
begin
  actor_id := auth.uid();
  normalized_search := lower(trim(coalesce(search_text, '')));
  safe_limit := greatest(1, least(coalesce(row_limit, 500), 5000));

  if auth.role() <> 'service_role' and not public.is_global_admin(actor_id) then
    raise exception 'Only global admin can list profiles';
  end if;

  return query
  select p.user_id, p.role, p.updated_at
  from public.profiles p
  where normalized_search = ''
    or p.user_id::text ilike '%' || normalized_search || '%'
  order by p.updated_at desc
  limit safe_limit;
end;
$$;

revoke all on function public.admin_list_profiles(text, integer) from public;
grant execute on function public.admin_list_profiles(text, integer) to authenticated;

create or replace function public.admin_set_profile_role(
  target_user_id uuid,
  new_role text,
  reason text default 'admin_set_profile_role'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  normalized_role text;
begin
  actor_id := auth.uid();
  normalized_role := lower(trim(new_role));

  if normalized_role not in ('teacher', 'student') then
    raise exception 'Unsupported role: %', new_role;
  end if;

  if auth.role() <> 'service_role' and not public.is_global_admin(actor_id) then
    raise exception 'Only global admin can update profile role';
  end if;

  insert into public.profiles (user_id, role, display_name)
  values (target_user_id, normalized_role, '')
  on conflict (user_id)
  do update
    set role = excluded.role,
        updated_at = now();

  insert into public.admin_audit_logs(
    actor_user_id,
    target_user_id,
    action,
    reason,
    metadata
  )
  values (
    coalesce(actor_id, target_user_id),
    target_user_id,
    'set_profile_role',
    coalesce(nullif(trim(reason), ''), 'admin_set_profile_role'),
    jsonb_build_object('new_role', normalized_role)
  );
end;
$$;

revoke all on function public.admin_set_profile_role(uuid, text, text) from public;
grant execute on function public.admin_set_profile_role(uuid, text, text) to authenticated;
