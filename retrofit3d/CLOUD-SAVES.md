# Cloud saves (sign in to save progress)

Retrofit Factory 3D already saves your run **on-device** — you can close the tab
and pick up exactly where you left off, no account needed. This adds an optional
**cloud** layer on top: sign in with your email and your run follows you across
devices.

The game is a single static HTML file with no backend of its own, so the cloud
side runs on **Supabase** (a hosted Postgres + auth service with a generous free
tier). It talks to Supabase's Auth + REST APIs directly over `fetch` — there's no
SDK bundled and nothing else to host. Until you complete the setup below, the
cloud button just says "not configured" and the game stays local-only.

## What you get

- **Email sign-in** — enter your email, get a one-time code, you're in. No passwords.
- **Cross-device saves** — one save row per user **per plant** (the free bakery and
  the Ironline Brewery pack keep separate runs), pushed automatically as you play and
  pulled when you sign in. Newer save wins if both sides changed.
- **Private by design** — [row-level security](./supabase-setup.sql) means a
  signed-in player can only ever read/write their own save. The key baked into the
  page is the **publishable anon key**, which is safe to ship in client code.

## Setup (about 5 minutes)

1. **Create a project** at [supabase.com](https://supabase.com) (free tier is fine).
2. **Create the table.** Open **SQL Editor → New query**, paste the contents of
   [`supabase-setup.sql`](./supabase-setup.sql), and run it. This creates the
   `saves` table and its row-level-security policies.
3. **Turn on email codes.** In **Authentication → Providers → Email**, make sure
   email sign-in is enabled. Then in **Authentication → Email Templates → Magic
   Link**, edit the template so it shows the **code** rather than only a link —
   include the token, e.g.:

   ```
   Your Retrofit Factory sign-in code is: {{ .Token }}
   ```

   (Supabase's default email sends a link; the game uses the 6-digit code, so the
   template needs `{{ .Token }}`. On the free tier email is rate-limited; for real
   traffic add your own SMTP under **Authentication → SMTP Settings**.)
4. **Point the game at your project.** Grab **Project URL** and the **anon /
   publishable key** from **Project Settings → API**, then either:
   - paste them into the two constants at the top of `g7_cloud.js`
     (`_SB_BAKED_URL`, `_SB_BAKED_KEY`) and rebuild, **or**
   - for a quick test without rebuilding, run this once in the browser console on
     the game page and reload:
     ```js
     localStorage.setItem('rf3d_sb', JSON.stringify({
       url: 'https://YOUR-PROJECT.supabase.co',
       key: 'YOUR-ANON-KEY'
     }));
     ```
5. **Allowlist the game's URL.** In **Authentication → URL Configuration**, add
   `https://tlaba.github.io` (and `http://localhost` if you test locally) to the
   redirect allowlist. The code flow doesn't redirect, but Supabase still checks
   the site URL.

That's it — the 👤 button will now offer email sign-in, and your run syncs.

## How it works (for the curious)

- **Auth:** `POST /auth/v1/otp` sends the code; `POST /auth/v1/verify` exchanges it
  for a JWT session, stored in `localStorage` and refreshed via
  `/auth/v1/token?grant_type=refresh_token` when it expires.
- **Saves:** the same snapshot the local save uses (see `g6_save.js`
  `serializeState()`) is upserted to `POST /rest/v1/saves` and read back from
  `GET /rest/v1/saves`. On sign-in the client compares timestamps and keeps the
  newer of local vs. cloud, so you never silently lose the more recent run.
- **Nothing is trusted from the page beyond your own row:** the anon key alone
  can't touch any save; every request carries your user JWT and RLS enforces
  `auth.uid() = user_id` on the database side.

## Premium packs (entitlements)

The same `supabase-setup.sql` also creates the tables for **gating premium packs**
(e.g. the Ironline Brewery) behind redeem keys — optional, only needed if you sell
or gift packs.

- **Default (no Supabase configured):** premium packs stay **open as a preview** —
  the game can't gate against a store that isn't there, so nothing is locked. This
  is how the public build behaves today.
- **With Supabase configured:** premium plants show **🔒 Redeem key** in the plant
  picker until unlocked. Mint keys yourself in the SQL editor:
  `insert into public.pack_keys (key, pack) values ('IRON-ABCD-1234', 'brewery');`
  A signed-in player redeems one via the picker; `redeem_key()` (a `security
  definer` RPC) atomically claims the key and grants the entitlement. Owned packs
  are cached in `localStorage` (`rf3d_ent`) so they keep working offline.
- **Dev/self-host bypass:** set `localStorage.rf3d_dev_unlock = "1"` to unlock every
  pack on that device (for testing or a free self-hosted build).
- **Security:** `pack_keys` has RLS enabled with **no policies**, so the client can
  never read or write it directly — only the `security definer` `redeem_key()`
  function touches it, and it only ever grants a pack to `auth.uid()`.
