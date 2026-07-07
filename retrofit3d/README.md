# Retrofit Factory 3D

Keep a dying bakery line alive: one technician, six aging machines, and every
dollar you don't spend on maintenance is a dollar the breakdown takes back with
interest. A calm, thinky industrial-**maintenance** strategy game — you never
build or place machines, you keep them running.

Carries the troubleshooter's DNA into a strategy layer: **a fault is data, not
code.** Every symptom, breakdown and cascade emerges from `params + runtime +
load` read through one chokepoint (`effParam()`), not from scripted events.

**▶ Play it live (no install):**
https://tlaba.github.io/workbench/retrofit3d/retrofit-factory-3d.html
(auto-deploys from `main` via GitHub Pages)

| File | What it is |
|---|---|
| [`retrofit-factory-3d.html`](./retrofit-factory-3d.html) | **Playable browser prototype.** Single self-contained HTML — no build, no deps (three.js inlined). A real-time 3D factory hall you walk around as the technician, six animated machines, the full tuned economy running a deterministic seeded simulation. |
| [`GDD.md`](./GDD.md) | The 25-section developer-ready Game Design Document — vision, pillars, canonical machine stats, economy formulas, and the tuned constants the prototype uses verbatim. |
| [`GDD-IRONLINE.md`](./GDD-IRONLINE.md) · [`GDD-EMBERLINE.md`](./GDD-EMBERLINE.md) · [`GDD-BLACKWEIR.md`](./GDD-BLACKWEIR.md) | Design docs for the three premium plant packs — the **Ironline Brewery** (hygiene→price + batch fermentation), the **Emberline Diecast Foundry** (a heat bank + rework spiral, flat price), and the **Blackweir Waterworks** (an inflow-fed basin bomb + silent compliance) — each with its verified balance matrix. |
| [`MONETIZATION.md`](./MONETIZATION.md) | A staged, product-fit monetization plan — free web build as the funnel, premium plant packs, a paid Complete Edition, and an education/B2B licensing channel built on the game's reliability-engineering core. |
| [`CLOUD-SAVES.md`](./CLOUD-SAVES.md) · [`supabase-setup.sql`](./supabase-setup.sql) | Optional cloud sign-in: how to point the game at a Supabase project so players can save their run to the cloud and continue on any device (the schema + row-level-security policies, and the ~5-minute setup). |

## Save, continue, and notifications

The game **saves your run on-device automatically** — close the tab and reopen to
a "Welcome back" screen that resumes exactly where you stopped (the technician's
in-progress job, every machine's wear, even the random-breakdown seed, so a
resumed run is byte-identical to one that never paused). The 🔔 button opts into
**OS notifications while the tab is backgrounded** — a machine breakdown, a day or
week completing — so you can tab away and get pinged; the sim keeps ticking in the
background (bounded to one day per absence, no offline decay).

The 👤 button adds **optional cloud saves**: sign in with an email code and your run
follows you across devices, reconciling local vs. cloud by whichever is newer. It
stays dormant (local-only) until a Supabase project is configured — see
[`CLOUD-SAVES.md`](./CLOUD-SAVES.md).

## Four plants — the free bakery and three premium packs

The game opens on a **plant picker**. The free **Old Bakery Plant** is the full
core game described below. Three *premium plant packs* build on the same
engine — each 12 machines across a 6-week season with three colour-coded
utility buses, a hireable **apprentice**, per-part **condition sensors**, and a
signature economy axis all its own:

| Plant | Buses | Signature mechanics | Where money dies |
|---|---|---|---|
| **Ironline Brewery & Bottling Works** | steam · glycol · air | **hygiene → quality → price**; **batch fermentation** through a bright-tank buffer; fouling + calibration drift | low quality → low **price** |
| **Emberline Diecast & Alloy Works** | gas · hydraulic · water | the **Heat Bank** (molten metal is banked inventory with a superheat you must never freeze); the **Rework Spiral** (defects re-melt the same metal twice); **THERM** (downtime is wear) | energy + re-melt + warranty **fines** (flat price) |
| **Blackweir Municipal Waterworks** | power · air · chem | the **river never stops** (an inflow-fed basin you keep half-empty, forecast-a-day storms); **silent compliance** (calibration drift is a permit violation, not a price cut) | weir-spill + violation **fines** + the pump power bill (flat price) |

Each plant keeps its own on-device (and cloud) save and its own reference
policy matrix (`window.__matrix(seeds, plantId)`). Design details + the
verified balance matrices live in
[`GDD-IRONLINE.md`](./GDD-IRONLINE.md), [`GDD-EMBERLINE.md`](./GDD-EMBERLINE.md)
and [`GDD-BLACKWEIR.md`](./GDD-BLACKWEIR.md). Until a store is wired up the packs
are open as a preview (the redeem-key gate is built — see
[`CLOUD-SAVES.md`](./CLOUD-SAVES.md)).

## You are the technician — walk the floor

The plant is a real-time 3D hall: brick-and-steel bakery, concrete floor with
painted walkways, roof trusses, skylight shafts, hanging bay lights, and the
compressed-air main running overhead from the compressor to every pneumatic
machine (the cascade, made visible). Machines animate with the simulation —
the mixer's agitator spins, loaves ride the conveyor, the oven mouth glows,
the compressor's gauge tracks header pressure — and degradation shows: paint
dulls to rust as health falls, breakdowns smoke and strobe red, condensate
pools under a moisture-choked compressor.

**Controls**
- **Walk** — virtual joystick, `WASD`/arrows, or tap the floor
- **Look** — drag to orbit · pinch / scroll to zoom
- **Interact** — walk up to a machine and tap **⚙ Open panel** (or press `E`).
  Panels can be *viewed* from anywhere, but you must physically be at a machine
  to work on it — too far away, and the panel offers **🚶 Walk to machine**.
- While you're mid-job you're committed (you're the one holding the wrench) —
  plan your route or ⏩ speed up time. `Space` pauses.

## The season — four escalating contracts

You play a **season of four weekly contracts** (five days each — a 20-day run) on
**one plant you never replace**. Cash, upgrades, automation, stocked spares and —
above all — the plant's accumulated **wear** all carry from week to week; only the
strike count resets with each new contract. The catch is the quota:

| Week | Daily demand | vs base line capacity (~1,120/day) |
|---|---|---|
| 1 | 620 | 55% — settling in |
| 2 | 800 | 71% — the ask climbs |
| 3 | 990 | 88% — needs a healthy line |
| 4 | **1,200** | **107% — exceeds a base line; you must add capacity** |

Because the plant only ages, each week is a *harder version of the same problem*:
the loaves you owe keep rising while the line you're nursing keeps wearing. Week 4
demands more than a healthy un-upgraded line can physically ship, so the finale
turns on a well-timed **⬆ upgrade** on top of the reliability upkeep — not just
more of the same triage.

## The loop (Old Bakery Plant)

Six machines feed the bread contract: **Spiral Mixer → Conveyor → Oven →
Slicer → Packager**, all fed compressed air by an **Air Compressor**. You have
a tight cash runway and one pair of hands. Each day you triage:

- **🔍 Inspect** ($25–60) — reveal per-part wear. No downtime — and it unlocks…
- **🔩 Targeted fix** — replace *one known-worn part* to like-new: $60 labor + the part, ~⅓ the
  downtime of a full service. Only available once that part's condition is revealed —
  **information is the currency**.
- **🔧 Repair (overhaul)** — service *all* parts to like-new. Thorough but slow;
  blind calendar overhauls burn uptime.
- **📦 Stock spare** — pre-buy the part; a breakdown then skips the 2.5× emergency
  parts premium and the 3-hour delivery.
- **⬆ Upgrade** — +40% capacity, but a faster line wears *everything* faster.
- **🤖 Automate** — condition-monitoring + auto-drain: cuts that machine's wear ~65%
  and re-reveals its true condition every morning.
- **🆕 Replace** — a brand-new unit. Capital-heavy.

Breakdowns bill the real emergency premium — **2.5× parts + 1.75× labor + $350
collateral** — so run-to-failure pays through the nose, and over a 20-day season
that debt compounds.

Throughput is the **minimum of the chain**, so the bottleneck is wherever wear
bites hardest — fix it and the limit *migrates* somewhere else. The compressor's
moisture couples into every pneumatic machine through a shared air bus: neglect
it and a slow cascade drags the whole floor down. Miss the contract floor three
days **in a single week** and the bakery pulls that contract — season over. Every
run rolls a fresh **seed**; the end screen offers *retry this season* on the same
seed, a **post-mortem**, and saves your **personal best**.

## Emergent, not scripted — verified

Seven maintenance disciplines are swept headless across the full 4-week season on
**10 seeds** (run `window.__matrix()` in the browser console to reproduce):

| Strategy | Wins (≥$30k) | Seasons finished | Median | Worst case |
|---|---|---|---|---|
| **Run-to-failure** (ignore everything) | 0/10 | 0/10 — dies in week 2 | $6.7k | $5.0k |
| **Inspect the bottleneck only** (look, barely act) | 0/10 | 0/10 — dies wk 2–3 | $11.6k | $5.0k |
| **Compressor-first inspections** (fixes only) | 0/10 | 0/10 — dies wk 2 | $10.4k | $3.9k |
| **Upgrade the bottleneck** (capacity chase, thin upkeep) | 1/10 | 8/10 | $25.5k | $17.4k |
| **Early automation** + threshold overhauls | 5/10 | 9/10 | $30.6k | $2.8k |
| **Preventive** (blind full-season calendar overhauls) | 6/10 | 9/10 | $33.3k | $18.1k |
| **Predictive** (inspect → 🔩 targeted fix + a timed ⬆ upgrade) | **6/10** | **10/10** | **$32.8k** | **$22.9k** |

The lesson is the real one from reliability engineering: **condition-based
maintenance is the most *reliable* strategy** — it is the only discipline that
finishes **every** season (10/10), with the best worst case (≈$4.8k above blind
preventive's floor) and the highest ceiling ($38.7k). Blind calendar overhauls
match it on a typical run but *gamble*: they fail 1 season in 10 and crater on a
bad-luck one. Capacity-chasing a worn plant survives but barely profits;
inspection without action is just watching it die. A 🔩 targeted fix restores the
known part to like-new at ~⅓ the downtime of a blanket overhaul — precision that
pays off most when week 4's quota leaves no uptime to waste. Grades: ★ $30k ·
★★ $33k · ★★★ $36k (verified reachable). None of it is hand-scripted: it falls
out of ordinary wear + throughput +
economy math.
