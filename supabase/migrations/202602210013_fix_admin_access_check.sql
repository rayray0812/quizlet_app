-- Fix admin access check for authenticated clients under RLS.
-- Make is_global_admin callable as SECURITY DEFINER.

create or replace function public.is_global_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_role_bindings arb
    where arb.admin_user_id = uid
      and arb.scope_type = 'global'
      and arb.role_key in ('super_admin', 'org_admin')
  );
$$;

revoke all on function public.is_global_admin(uuid) from public;
grant execute on function public.is_global_admin(uuid) to authenticated;
