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
| [`MONETIZATION.md`](./MONETIZATION.md) | A staged, product-fit monetization plan — free web build as the funnel, premium plant packs, a paid Complete Edition, and an education/B2B licensing channel built on the game's reliability-engineering core. |

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

## The loop (Level 1 — Old Bakery Plant)

Six machines feed one bread contract: **Spiral Mixer → Conveyor → Oven →
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
collateral** — so run-to-failure pays through the nose. Every run rolls a fresh
**seed** (breakdown luck differs); the end screen offers *retry this shift* on the
same seed, a **shift post-mortem** (breakdown count, emergency vs planned spend,
moisture peak, a tailored tip), and saves your **personal best** on-device.

Throughput is the **minimum of the chain**, so the bottleneck is wherever wear
bites hardest — fix it and the limit *migrates* somewhere else. The compressor's
moisture couples into every pneumatic machine through a shared air bus: neglect
it and a slow cascade drags the whole floor down. Miss the contract floor three
days and the bakery pulls the contract.

## Emergent, not scripted — verified

Seven maintenance disciplines are swept headless across **10 seeds**
(v3 balance — run `window.__matrix()` in the browser console to reproduce):

| Strategy | Wins | Median | Range |
|---|---|---|---|
| **Run-to-failure** (ignore everything) | 0/10 | $8.6k — dies ~day 5-6 | $4.4k–10.5k |
| **Inspect the bottleneck only** (look, barely act) | 0/10 | $11.5k | $4.4k–15.5k |
| **Compressor-first inspections** (fixes only) | 0/10 | $10.9k | $4.1k–16.3k |
| **Upgrade the bottleneck** (capacity chase) | 0/10 | $16.7k | $1.6k–19.3k |
| **Early automation** + threshold overhauls | 3/10 | $18.5k | $2.8k–21.0k |
| **Preventive** (blind calendar overhauls) | 4/10 | $19.3k | $3.2k–22.2k |
| **Predictive** (reset once → inspect → 🔩 targeted fix) | **5/10** | **$20.6k** | **$16.8k**–22.7k |

The lesson is the real one from reliability engineering: **condition-based
maintenance has the best expected value and by far the best worst case** —
calendar overhauls gamble on breakdown luck, capacity upgrades on a dying
plant are a trap, and inspection without action is just watching it die.
A 🔩 targeted fix restores the known part to like-new; a blanket overhaul is
faster per part but leaves residual wear — precision beats brute force.
Grades: ★ $20k · ★★ $21.5k · ★★★ $22.5k (strike-free, verified reachable).
None of it is hand-scripted: it falls out of ordinary wear + throughput +
economy math.
