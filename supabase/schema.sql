-- Mauban Chess Club database setup
-- Run this complete script in Supabase Dashboard > SQL Editor.
-- Safe for browser use only when the publishable key is paired with these RLS policies.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  category text not null default 'OPEN' check (category in ('Elementary','Secondary','OPEN')),
  contact text,
  role text not null default 'member' check (role in ('member','admin','super_admin')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  category text not null check (category in ('Elementary','Secondary','OPEN')),
  school text,
  created_at timestamptz not null default now()
);
create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'All categories',
  status text not null default 'Scheduled',
  event_date date,
  venue text,
  description text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table if not exists public.pairings (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  round integer not null check (round > 0),
  board integer not null check (board > 0),
  white_name text not null,
  black_name text not null,
  result text not null default 'Pending' check (result in ('Pending','1-0','0-1','½-½','0-0','BYE')),
  created_at timestamptz not null default now(),
  unique(tournament_id,round,board)
);
create table if not exists public.local_ratings (
  id uuid primary key default gen_random_uuid(),
  player_name text not null,
  category text not null check (category in ('Elementary','Secondary','OPEN')),
  rating integer not null check (rating between 0 and 4000),
  notes text,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);
create index if not exists local_ratings_rating_idx on public.local_ratings(rating desc);
create index if not exists pairings_tournament_round_idx on public.pairings(tournament_id,round,board);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles(id,full_name,email,category,contact)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    new.email,
    coalesce(new.raw_user_meta_data->>'category','OPEN'),
    new.raw_user_meta_data->>'contact'
  );
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_club_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and role in ('admin','super_admin')
      and status = 'approved'
  );
$$;

alter table public.profiles enable row level security;
alter table public.players enable row level security;
alter table public.tournaments enable row level security;
alter table public.pairings enable row level security;
alter table public.local_ratings enable row level security;

-- Public can see approved member names only through aggregate counts in the site.
-- A signed-in member can read their own profile; admins can read all profiles.
drop policy if exists "profile read own or admin" on public.profiles;
create policy "profile read own or admin" on public.profiles for select
using (id = (select auth.uid()) or public.is_club_admin());
drop policy if exists "profile update admin" on public.profiles;
create policy "profile update admin" on public.profiles for update
using (public.is_club_admin()) with check (public.is_club_admin());
drop policy if exists "players public read" on public.players;
create policy "players public read" on public.players for select using (true);
drop policy if exists "players admin manage" on public.players;
create policy "players admin manage" on public.players for all
using (public.is_club_admin()) with check (public.is_club_admin());
drop policy if exists "tournaments public read" on public.tournaments;
create policy "tournaments public read" on public.tournaments for select using (true);
drop policy if exists "tournaments admin manage" on public.tournaments;
create policy "tournaments admin manage" on public.tournaments for all
using (public.is_club_admin()) with check (public.is_club_admin());
drop policy if exists "pairings public read" on public.pairings;
create policy "pairings public read" on public.pairings for select using (true);
drop policy if exists "pairings admin manage" on public.pairings;
create policy "pairings admin manage" on public.pairings for all
using (public.is_club_admin()) with check (public.is_club_admin());
drop policy if exists "ratings public read" on public.local_ratings;
create policy "ratings public read" on public.local_ratings for select using (true);
drop policy if exists "ratings admin manage" on public.local_ratings;
create policy "ratings admin manage" on public.local_ratings for all
using (public.is_club_admin()) with check (public.is_club_admin());

-- IMPORTANT: After creating your first account, promote it using the SQL below.
-- Replace the email with the email address used for your administrator account.
-- update public.profiles set role='super_admin', status='approved'
-- where email='YOUR-ADMIN-EMAIL-HERE';
