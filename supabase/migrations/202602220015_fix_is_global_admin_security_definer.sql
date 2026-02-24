-- Fix: is_global_admin must bypass RLS to avoid circular dependency.
-- The function checks admin_role_bindings, whose RLS policy calls is_global_admin.
-- Without SECURITY DEFINER the function always returns false.

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
