-- Classroom MVP foundation schema (teacher/student by class)
-- Apply after base sync schema migration.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'student' check (role in ('teacher', 'student')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  subject text not null default '',
  grade text not null default '',
  invite_code text not null unique,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.class_members (
  id bigserial primary key,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'removed')),
  unique (class_id, student_id)
);

create table if not exists public.class_sets (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  owner_teacher_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  cards jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (class_id, id)
);

create table if not exists public.class_assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  set_id uuid not null,
  assigned_by uuid not null references auth.users(id) on delete cascade,
  due_at timestamptz null,
  published_at timestamptz not null default now(),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint fk_class_assignments_set
    foreign key (class_id, set_id)
    references public.class_sets (class_id, id)
    on delete cascade,
  unique (class_id, set_id)
);

create table if not exists public.student_assignment_progress (
  id bigserial primary key,
  assignment_id uuid not null references public.class_assignments(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'not_started' check (
    status in ('not_started', 'in_progress', 'completed')
  ),
  score double precision null,
  last_studied_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (assignment_id, student_id)
);

create index if not exists idx_profiles_role
  on public.profiles(role);

create index if not exists idx_classes_teacher_created
  on public.classes(teacher_id, created_at desc);

create index if not exists idx_classes_invite_code
  on public.classes(invite_code);

create index if not exists idx_class_members_class_status
  on public.class_members(class_id, status);

create index if not exists idx_class_members_student_status
  on public.class_members(student_id, status);

create index if not exists idx_class_sets_class_updated
  on public.class_sets(class_id, updated_at desc);

create index if not exists idx_class_assignments_class_published
  on public.class_assignments(class_id, is_published, published_at desc);

create index if not exists idx_class_assignments_set
  on public.class_assignments(set_id);

create index if not exists idx_assignment_progress_student_updated
  on public.student_assignment_progress(student_id, updated_at desc);

create index if not exists idx_assignment_progress_assignment
  on public.student_assignment_progress(assignment_id);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_classes_updated_at on public.classes;
create trigger trg_classes_updated_at
before update on public.classes
for each row execute function public.set_updated_at();

drop trigger if exists trg_class_sets_updated_at on public.class_sets;
create trigger trg_class_sets_updated_at
before update on public.class_sets
for each row execute function public.set_updated_at();

drop trigger if exists trg_class_assignments_updated_at on public.class_assignments;
create trigger trg_class_assignments_updated_at
before update on public.class_assignments
for each row execute function public.set_updated_at();

drop trigger if exists trg_student_assignment_progress_updated_at on public.student_assignment_progress;
create trigger trg_student_assignment_progress_updated_at
before update on public.student_assignment_progress
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.class_sets enable row level security;
alter table public.class_assignments enable row level security;
alter table public.student_assignment_progress enable row level security;

create or replace function public.is_class_teacher(class_uuid uuid, uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.classes c
    where c.id = class_uuid
      and c.teacher_id = uid
  );
$$;

create or replace function public.is_class_member(class_uuid uuid, uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.class_members cm
    where cm.class_id = class_uuid
      and cm.student_id = uid
      and cm.status = 'active'
  );
$$;

create or replace function public.can_access_class(class_uuid uuid, uid uuid)
returns boolean
language sql
stable
as $$
  select public.is_class_teacher(class_uuid, uid)
      or public.is_class_member(class_uuid, uid);
$$;

create or replace function public.is_assignment_teacher(assignment_uuid uuid, uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.class_assignments ca
    join public.classes c on c.id = ca.class_id
    where ca.id = assignment_uuid
      and c.teacher_id = uid
  );
$$;

create or replace function public.is_assignment_student(assignment_uuid uuid, uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.class_assignments ca
    join public.class_members cm on cm.class_id = ca.class_id
    where ca.id = assignment_uuid
      and cm.student_id = uid
      and cm.status = 'active'
  );
$$;

create or replace function public.join_class_by_invite_code(code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_uid uuid;
  target_class_id uuid;
  archived_flag boolean;
begin
  current_uid := auth.uid();
  if current_uid is null then
    raise exception 'Authentication required';
  end if;

  select c.id, c.is_archived
  into target_class_id, archived_flag
  from public.classes c
  where upper(c.invite_code) = upper(trim(code))
  limit 1;

  if target_class_id is null then
    raise exception 'Class not found for invite code';
  end if;

  if archived_flag then
    raise exception 'Class is archived';
  end if;

  insert into public.class_members (class_id, student_id, status)
  values (target_class_id, current_uid, 'active')
  on conflict (class_id, student_id)
  do update
    set status = 'active';

  return target_class_id;
end;
$$;

revoke all on function public.join_class_by_invite_code(text) from public;
grant execute on function public.join_class_by_invite_code(text) to authenticated;

drop policy if exists "profiles_self_all" on public.profiles;
create policy "profiles_self_all"
on public.profiles
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "classes_select_members_or_teacher" on public.classes;
create policy "classes_select_members_or_teacher"
on public.classes
for select
using (public.can_access_class(id, auth.uid()));

drop policy if exists "classes_insert_teacher_only" on public.classes;
create policy "classes_insert_teacher_only"
on public.classes
for insert
with check (auth.uid() = teacher_id);

drop policy if exists "classes_update_teacher_only" on public.classes;
create policy "classes_update_teacher_only"
on public.classes
for update
using (public.is_class_teacher(id, auth.uid()))
with check (public.is_class_teacher(id, auth.uid()));

drop policy if exists "classes_delete_teacher_only" on public.classes;
create policy "classes_delete_teacher_only"
on public.classes
for delete
using (public.is_class_teacher(id, auth.uid()));

drop policy if exists "class_members_select_members_or_teacher" on public.class_members;
create policy "class_members_select_members_or_teacher"
on public.class_members
for select
using (public.can_access_class(class_id, auth.uid()));

drop policy if exists "class_members_insert_teacher_only" on public.class_members;
create policy "class_members_insert_teacher_only"
on public.class_members
for insert
with check (
  public.is_class_teacher(class_id, auth.uid())
);

drop policy if exists "class_members_update_self_or_teacher" on public.class_members;
create policy "class_members_update_self_or_teacher"
on public.class_members
for update
using (
  auth.uid() = student_id
  or public.is_class_teacher(class_id, auth.uid())
)
with check (
  auth.uid() = student_id
  or public.is_class_teacher(class_id, auth.uid())
);

drop policy if exists "class_members_delete_self_or_teacher" on public.class_members;
create policy "class_members_delete_self_or_teacher"
on public.class_members
for delete
using (
  auth.uid() = student_id
  or public.is_class_teacher(class_id, auth.uid())
);

drop policy if exists "class_sets_select_members_or_teacher" on public.class_sets;
create policy "class_sets_select_members_or_teacher"
on public.class_sets
for select
using (public.can_access_class(class_id, auth.uid()));

drop policy if exists "class_sets_insert_teacher_only" on public.class_sets;
create policy "class_sets_insert_teacher_only"
on public.class_sets
for insert
with check (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = owner_teacher_id
);

drop policy if exists "class_sets_update_teacher_only" on public.class_sets;
create policy "class_sets_update_teacher_only"
on public.class_sets
for update
using (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = owner_teacher_id
)
with check (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = owner_teacher_id
);

drop policy if exists "class_sets_delete_teacher_only" on public.class_sets;
create policy "class_sets_delete_teacher_only"
on public.class_sets
for delete
using (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = owner_teacher_id
);

drop policy if exists "class_assignments_select_teacher_or_published_students" on public.class_assignments;
create policy "class_assignments_select_teacher_or_published_students"
on public.class_assignments
for select
using (
  public.is_class_teacher(class_id, auth.uid())
  or (
    public.is_class_member(class_id, auth.uid())
    and is_published = true
  )
);

drop policy if exists "class_assignments_insert_teacher_only" on public.class_assignments;
create policy "class_assignments_insert_teacher_only"
on public.class_assignments
for insert
with check (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = assigned_by
);

drop policy if exists "class_assignments_update_teacher_only" on public.class_assignments;
create policy "class_assignments_update_teacher_only"
on public.class_assignments
for update
using (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = assigned_by
)
with check (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = assigned_by
);

drop policy if exists "class_assignments_delete_teacher_only" on public.class_assignments;
create policy "class_assignments_delete_teacher_only"
on public.class_assignments
for delete
using (
  public.is_class_teacher(class_id, auth.uid())
  and auth.uid() = assigned_by
);

drop policy if exists "progress_select_self_or_teacher" on public.student_assignment_progress;
create policy "progress_select_self_or_teacher"
on public.student_assignment_progress
for select
using (
  auth.uid() = student_id
  or public.is_assignment_teacher(assignment_id, auth.uid())
);

drop policy if exists "progress_insert_self_or_teacher" on public.student_assignment_progress;
create policy "progress_insert_self_or_teacher"
on public.student_assignment_progress
for insert
with check (
  (
    auth.uid() = student_id
    and public.is_assignment_student(assignment_id, auth.uid())
  )
  or public.is_assignment_teacher(assignment_id, auth.uid())
);

drop policy if exists "progress_update_self_or_teacher" on public.student_assignment_progress;
create policy "progress_update_self_or_teacher"
on public.student_assignment_progress
for update
using (
  auth.uid() = student_id
  or public.is_assignment_teacher(assignment_id, auth.uid())
)
with check (
  auth.uid() = student_id
  or public.is_assignment_teacher(assignment_id, auth.uid())
);

drop policy if exists "progress_delete_self_or_teacher" on public.student_assignment_progress;
create policy "progress_delete_self_or_teacher"
on public.student_assignment_progress
for delete
using (
  auth.uid() = student_id
  or public.is_assignment_teacher(assignment_id, auth.uid())
);
