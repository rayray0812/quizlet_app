-- Automatically create a profile row when a new user signs up via auth.users.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1), ''),
    'student'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- Fire after every new row in auth.users (signup, OAuth, invite, etc.)
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill: create profile rows for any existing auth.users that don't have one yet.
insert into public.profiles (user_id, display_name, role)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'full_name', split_part(u.email, '@', 1), ''),
  'student'
from auth.users u
where not exists (
  select 1 from public.profiles p where p.user_id = u.id
)
on conflict (user_id) do nothing;
