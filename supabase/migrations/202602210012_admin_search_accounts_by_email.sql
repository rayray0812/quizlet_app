-- Admin account search by user_id or email for admin console.

create or replace function public.admin_list_accounts(
  search_text text default '',
  row_limit integer default 500
)
returns table(
  user_id uuid,
  email text,
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
    raise exception 'Only global admin can list accounts';
  end if;

  return query
  select
    p.user_id,
    coalesce(u.email, '') as email,
    p.role,
    p.updated_at
  from public.profiles p
  left join auth.users u on u.id = p.user_id
  where normalized_search = ''
    or p.user_id::text ilike '%' || normalized_search || '%'
    or coalesce(u.email, '') ilike '%' || normalized_search || '%'
  order by p.updated_at desc
  limit safe_limit;
end;
$$;

revoke all on function public.admin_list_accounts(text, integer) from public;
grant execute on function public.admin_list_accounts(text, integer) to authenticated;
