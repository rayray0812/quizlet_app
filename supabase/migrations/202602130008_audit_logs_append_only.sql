-- Fix: Make admin_audit_logs append-only (no UPDATE/DELETE allowed)
-- Previously used 'for all' which allowed tampering with audit history.

drop policy if exists "admin_audit_logs_global_admin_all" on public.admin_audit_logs;

-- SELECT: admins can read audit logs
create policy "admin_audit_logs_select"
on public.admin_audit_logs
for select
using (public.is_global_admin(auth.uid()));

-- INSERT: admins can append new log entries
create policy "admin_audit_logs_insert"
on public.admin_audit_logs
for insert
with check (public.is_global_admin(auth.uid()));

-- No UPDATE or DELETE policy = audit logs are immutable
