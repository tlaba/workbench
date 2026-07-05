-- Retrofit Factory 3D — cloud saves schema for Supabase.
-- Run this once in your project's SQL editor (Dashboard → SQL Editor → New query).
-- It creates a single-row-per-user saves table and locks it down with RLS so a
-- signed-in player can only ever read or write their OWN save.

create table if not exists public.saves (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb       not null,
  updated_at timestamptz not null default now()
);

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
