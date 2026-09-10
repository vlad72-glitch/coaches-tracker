-- Coaches Tracker — database setup
-- Safe to run more than once. It never overwrites your data.
--
-- IMPORTANT: this project also holds the Win and Swim Trainings app, which has
-- login accounts for your coaches. Pay rates and payouts must not be readable
-- by them, so every rule below is gated on ct_owners, NOT on "is signed in".

-- ---------------------------------------------------------------- owners ----
-- Only user ids listed here can read or write anything in the tracker.
create table if not exists public.ct_owners (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  added_at   timestamptz not null default now()
);
alter table public.ct_owners enable row level security;

-- An owner may see the owner list. Nobody else sees it, and nobody can add
-- themselves: rows go in from the SQL editor only.
drop policy if exists ct_owners_read on public.ct_owners;
create policy ct_owners_read on public.ct_owners
  for select to authenticated
  using (exists (select 1 from public.ct_owners o where o.user_id = auth.uid()));

-- ----------------------------------------------------------------- state ----
-- The whole tracker is one JSON document: { coaches: [...], months: {...} }.
-- It is small, single-user, and edited as a unit, so one row keeps the app
-- logic identical to the offline version and makes sync trivial.
create table if not exists public.ct_state (
  id          text primary key default 'singleton',
  doc         jsonb not null default '{"coaches":[],"months":{}}'::jsonb,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);
alter table public.ct_state enable row level security;

insert into public.ct_state (id) values ('singleton')
on conflict (id) do nothing;

create or replace function public.ct_is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.ct_owners o where o.user_id = auth.uid());
$$;

drop policy if exists ct_state_select on public.ct_state;
create policy ct_state_select on public.ct_state
  for select to authenticated using (public.ct_is_owner());

drop policy if exists ct_state_update on public.ct_state;
create policy ct_state_update on public.ct_state
  for update to authenticated
  using (public.ct_is_owner()) with check (public.ct_is_owner());

-- stamp every write so other devices can tell they are behind
create or replace function public.ct_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists ct_state_touch on public.ct_state;
create trigger ct_state_touch before update on public.ct_state
  for each row execute function public.ct_touch();
