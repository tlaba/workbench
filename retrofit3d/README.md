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

- **🔍 Inspect** ($40) — reveal per-part wear. No downtime.
- **🔧 Repair** — service the worst parts to like-new. Costs downtime.
- **📦 Stock spare** — pre-buy the part so a breakdown skips the emergency premium.
- **⬆ Upgrade** — +40% capacity, but a faster line wears *everything* faster.
- **🤖 Automate** — condition-monitoring + auto-drain cuts that machine's wear ~60%.
- **🆕 Replace** — a brand-new unit. Capital-heavy.

Throughput is the **minimum of the chain**, so the bottleneck is wherever wear
bites hardest — fix it and the limit *migrates* somewhere else. The compressor's
moisture couples into every pneumatic machine through a shared air bus: neglect
it and a slow cascade drags the whole floor down. Miss the contract floor three
days and the bakery pulls the contract.

## Emergent, not scripted — verified

Three disciplines were checked headless against the tuned economy on a fixed seed:

| Strategy | Outcome |
|---|---|
| **Run-to-failure** (do nothing) | Loses ~**day 6** — breakdowns and the moisture cascade compound |
| **Preventive** (calendar servicing) | **Wins** — ~$24k against the $20k target |
| **Predictive** (automate the roots, condition-based repair) | **Wins** by a thin margin |

Neglect always loses; disciplined maintenance always wins — and the two skilled
strategies finish within a few percent of each other, exactly the balance the
GDD targets. None of it is hand-scripted: it falls out of ordinary wear +
throughput + economy math.
