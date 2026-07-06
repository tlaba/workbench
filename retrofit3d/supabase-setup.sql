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

-- =============================================================================
-- ENTITLEMENTS — which premium packs an account owns, unlocked by redeem keys.
-- Optional: only needed if you sell/gift premium packs (e.g. the Ironline
-- Brewery). With this in place the game gates premium plants behind a key;
-- without it, premium packs stay open as a preview.
-- =============================================================================

-- What each account owns. Readable only by its owner; written only by the
-- redeem_key() function below (no direct insert policy).
create table if not exists public.entitlements (
  user_id    uuid        not null references auth.users (id) on delete cascade,
  pack       text        not null,
  granted_at timestamptz not null default now(),
  primary key (user_id, pack)
);
alter table public.entitlements enable row level security;
drop policy if exists "ent_select_own" on public.entitlements;
create policy "ent_select_own" on public.entitlements
  for select using (auth.uid() = user_id);

-- Redeemable keys you hand out. Locked down entirely: only the security-definer
-- redeem_key() function reads or writes this table (no RLS policies = no client
-- access even with a valid JWT). Insert keys yourself via the SQL editor, e.g.
--   insert into public.pack_keys (key, pack) values ('IRON-ABCD-1234', 'brewery');
create table if not exists public.pack_keys (
  key         text primary key,
  pack        text not null,
  redeemed_by uuid references auth.users (id),
  redeemed_at timestamptz
);
alter table public.pack_keys enable row level security;

-- Atomically claim an unused key for the caller and grant them its pack.
-- Idempotent: re-redeeming your own key just re-confirms the entitlement.
create or replace function public.redeem_key(k text)
returns text language plpgsql security definer set search_path = public as $$
declare p text;
begin
  update public.pack_keys set redeemed_by = auth.uid(), redeemed_at = now()
    where key = k and redeemed_by is null
    returning pack into p;
  if p is null then
    select pack into p from public.pack_keys where key = k and redeemed_by = auth.uid();
    if p is null then raise exception 'invalid_or_used_key'; end if;
  end if;
  insert into public.entitlements (user_id, pack) values (auth.uid(), p)
    on conflict do nothing;
  return p;
end $$;
revoke all on function public.redeem_key(text) from public, anon;
grant execute on function public.redeem_key(text) to authenticated;
