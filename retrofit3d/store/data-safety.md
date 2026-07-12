# Data safety form — exact answers

**Play Console → Monitor and improve → Policy → App content → Data safety.**

These answers were produced by a line-by-line audit of the actual network code
(`g7_cloud.js`, `g6_save.js`, `sw.js`). The game talks to exactly ONE remote host
(the Supabase cloud-saves backend) and only after the player chooses to sign in.
There are no ads, analytics, tracking, or crash-reporting SDKs — verified by grep
across every script in the build.

## Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (single hardcoded HTTPS endpoint) |
| Do you provide a way for users to request that their data is deleted? | **Yes** |
| Account deletion URL (when asked) | `https://tlaba.github.io/workbench/retrofit3d/account-deletion.html` |

## Data types — declare exactly these three

### 1. Personal info → Email address
- Collected: **Yes** · Shared: **No** · Processed ephemerally: **No**
- Required or optional: **Optional** (only if the player signs in for cloud saves)
- Purposes: **Account management**

### 2. Personal info → User IDs
- Collected: **Yes** · Shared: **No** · Processed ephemerally: **No**
- Required or optional: **Optional**
- Purposes: **Account management, App functionality**
- (This is the cloud account UUID attached to save rows.)

### 3. App activity → Other actions
- Collected: **Yes** · Shared: **No** · Processed ephemerally: **No**
- Required or optional: **Optional**
- Purposes: **App functionality**
- (This is the cloud game-save snapshot: cash/day/week, machine states, in-game
  position. The audit confirmed it contains no PII, no device IDs, no location.)

## Everything else: NOT collected

Location, financial info, health & fitness, messages, photos/videos, audio,
files & docs, calendar, contacts, web browsing, search history, installed apps,
device or other IDs, crash logs, diagnostics — **none collected**. Leave unchecked.

Why "Shared: No" everywhere: Supabase is a **service provider** (processor)
storing data on the developer's behalf, and Google sign-in is **user-initiated** —
both are exempt from Play's definition of "sharing."

## ⚠️ Known gap / follow-up

Google Play requires apps that support account creation to offer account deletion
**in-app** as well as via a web link. Today the app has:
- ✅ Web deletion-request URL (`account-deletion.html`, created with this kit)
- ✅ In-app deletion of a plant's **cloud save** (starting a New Game clears it)
- ❌ No in-app "delete my account" button (Supabase account deletion needs a
  server-side function)

The web URL satisfies the form today; plan to add an in-app delete-account flow
(a small Supabase Edge Function the signed-in user can call) before a wide
production rollout.
