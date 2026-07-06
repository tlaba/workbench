-- Retrofit Factory 3D — cloud saves schema for Supabase.
-- Run this once in your project's SQL editor (Dashboard → SQL Editor → New query).
-- It creates a one-row-per-user-per-plant saves table and locks it down with RLS so
-- a signed-in player can only ever read or write their OWN saves.

create table if not exists public.saves (
  user_id    uuid        not null references auth.users (id) on delete cascade,
  plant      text        not null default 'bakery',
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, plant)
);

-- Upgrade from the older single-save schema (pre-plant-pack): add the plant column
-- and switch the primary key to (user_id, plant). Safe to run on a fresh DB too.
alter table public.saves add column if not exists plant text not null default 'bakery';
do $$ begin
  if exists (select 1 from pg_constraint where conname='saves_pkey'
             and conrelid='public.saves'::regclass
             and array_length(conkey,1)=1) then
    alter table public.saves drop constraint saves_pkey;
    alter table public.saves add primary key (user_id, plant);
  end if;
end $$;

alter table public.saves enable row level security;

-- Each policy scopes access to the caller's own row (auth.uid() = the signed-in
-- user's id). The anon/publishable key used by the game can do nothing without a
-- valid user JWT, and even then only to this one row.
drop policy if exists "saves_select_own" on public.saves;
create policy "saves_select_own" on public.saves
  for select using (auth.uid() = user_id);

drop policy if exists "saves_insert_own" on public.saves;
create policy "saves_insert_own" on public.saves
  for insert with check (auth.uid() = user_id);

drop policy if exists "saves_update_own" on public.saves;
create policy "saves_update_own" on public.saves
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "saves_delete_own" on public.saves;
create policy "saves_delete_own" on public.saves
  for delete using (auth.uid() = user_id);
