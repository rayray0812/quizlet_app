create table if not exists public.class_matching_results (
  assignment_id uuid not null references public.class_assignments(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  best_time_seconds integer not null check (best_time_seconds > 0),
  latest_time_seconds integer not null check (latest_time_seconds > 0),
  accuracy integer not null default 0 check (accuracy >= 0 and accuracy <= 100),
  attempts integer not null default 0 check (attempts >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (assignment_id, student_id)
);

create index if not exists idx_class_matching_results_assignment_best
  on public.class_matching_results(assignment_id, best_time_seconds, updated_at);

create index if not exists idx_class_matching_results_class_student
  on public.class_matching_results(class_id, student_id);

drop trigger if exists set_class_matching_results_updated_at on public.class_matching_results;
create trigger set_class_matching_results_updated_at
before update on public.class_matching_results
for each row execute function public.set_updated_at();

alter table public.class_matching_results enable row level security;

drop policy if exists "class_matching_results_select_members_or_teacher" on public.class_matching_results;
create policy "class_matching_results_select_members_or_teacher"
on public.class_matching_results
for select
using (public.can_access_class(class_id, auth.uid()));

drop policy if exists "class_matching_results_insert_self_only" on public.class_matching_results;
create policy "class_matching_results_insert_self_only"
on public.class_matching_results
for insert
with check (
  auth.uid() = student_id
  and public.can_access_class(class_id, auth.uid())
);

drop policy if exists "class_matching_results_update_self_only" on public.class_matching_results;
create policy "class_matching_results_update_self_only"
on public.class_matching_results
for update
using (auth.uid() = student_id)
with check (
  auth.uid() = student_id
  and public.can_access_class(class_id, auth.uid())
);
