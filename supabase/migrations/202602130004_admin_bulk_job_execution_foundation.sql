-- Admin phase 3 execution foundation for bulk jobs
-- Adds worker-friendly columns and RPC helpers for claiming/completing jobs.

alter table public.admin_bulk_jobs
  add column if not exists attempt_count int not null default 0,
  add column if not exists max_attempts int not null default 5,
  add column if not exists last_error text not null default '',
  add column if not exists started_at timestamptz null,
  add column if not exists finished_at timestamptz null,
  add column if not exists worker_id text null;

create index if not exists idx_admin_bulk_jobs_status_created
  on public.admin_bulk_jobs(status, created_at asc);

create index if not exists idx_admin_bulk_jobs_worker_status
  on public.admin_bulk_jobs(worker_id, status, updated_at desc);

create or replace function public.admin_claim_next_bulk_job(worker text)
returns table (
  id bigint,
  actor_user_id uuid,
  job_type text,
  payload jsonb,
  status text,
  summary text,
  attempt_count int,
  max_attempts int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  claimed_id bigint;
begin
  if not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  select j.id
  into claimed_id
  from public.admin_bulk_jobs j
  where j.status = 'pending'
    and j.attempt_count < j.max_attempts
  order by j.created_at asc
  limit 1
  for update skip locked;

  if claimed_id is null then
    return;
  end if;

  update public.admin_bulk_jobs
  set status = 'running',
      worker_id = worker,
      started_at = now(),
      attempt_count = attempt_count + 1,
      updated_at = now()
  where public.admin_bulk_jobs.id = claimed_id;

  return query
  select
    j.id,
    j.actor_user_id,
    j.job_type,
    j.payload,
    j.status,
    j.summary,
    j.attempt_count,
    j.max_attempts
  from public.admin_bulk_jobs j
  where j.id = claimed_id;
end;
$$;

create or replace function public.admin_complete_bulk_job(
  job_id bigint,
  success boolean,
  err text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_global_admin(auth.uid()) then
    raise exception 'forbidden';
  end if;

  update public.admin_bulk_jobs
  set status = case when success then 'done' else 'failed' end,
      last_error = case when success then '' else coalesce(err, '') end,
      finished_at = now(),
      updated_at = now()
  where id = job_id
    and status = 'running';
end;
$$;
