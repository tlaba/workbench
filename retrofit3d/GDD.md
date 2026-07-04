# Retrofit Factory 3D — Game Design Document (Final, v1.0)

**Lead Game Director's cut. Single source of truth. Level 1: Old Bakery Plant.**
Target platform: Unity 2022 LTS+ / URP, mobile-first Android, portrait. One Unity developer. One shippable level proving six pillars.

**The one rule that governs everything below:** *a fault is data, not code.* A machine is a small component model; every symptom, breakdown and cascade emerges from `params + runtime + load` read through two chokepoints — `effParam()` (physics) and `effCost()` (economy). No code path anywhere is allowed to *know* that "compressor moisture stops the slicer." It falls out of ordinary throughput math on a shared air bus. Where this document lists a canonical number, that number is identical in §5, §18 and §24 — no drift.

---

## 1. Game Title + Pitch

**Retrofit Factory 3D** — *Keep a dying bakery line alive: one technician, six aging machines, and every dollar you don't spend on maintenance is a dollar the breakdown takes back with interest.*

---

## 2. Full GDD (Vision, Audience, Pillars, USP)

**Vision.** A calm, thinky industrial-maintenance strategy game for phones. You inherit a plant decades past its design life and run it against a wholesale bread contract. You never build or place machines — you *keep them running*. The drama is diagnosis and triage under a hard resource squeeze, not construction.

**Audience.** Players of management/tycoon and systems-puzzle games (Mini Metro, Factorio-adjacent but far lighter, Overcooked-style pressure without twitch). Mobile-primary, 25–45, comfortable reading a number and making a call. Plays in ~8–10 minute think-y sessions with clean day-boundary stopping points — this is a *planning* game, not an idle tapper.

**The six pillars (each traceable to the data-driven component model, never scripted):**

| # | Pillar | Where it lives in data (not code) |
|---|---|---|
| 1 | **Systemic wear** | Per-channel `wear[0..1]` integrated by F1 from `k_c · duty · S_c`; no timers |
| 2 | **The maintenance triangle** (predictive / preventive / run-to-failure all viable) | One `Repair` verb whose cost/time is read by `effCost` from state flags; hidden per-channel wear revealed by paid Inspect |
| 3 | **Cascades via explicit shared dependencies** | The air **bus** carries `P_air` + `moisture` as two numbers; downstream seal wear multiplies by `S = 1 + μ·moisture`. Edges are data rows |
| 4 | **One technician as the scarce clock** | A single agent draining a job queue; travel + job time both charged against a daily tech-minute budget |
| 5 | **Bottleneck migration (whack-a-mole)** | `T = min_i(r_i)` over the chain; `argmin` moves on its own as wear/upgrades change `r_i` |
| 6 | **Six verbs, every action a tradeoff** | Each verb is a modifier applied through `effParam`/`effCost`; adding an effect = adding a term, never a special case |

**USP.** *The cheap discriminating test beats guessing.* The signature moment — a compressor moisture fault that surfaces as three scattered symptoms on machines at opposite ends of the floor — is not scripted. It emerges from one wear number on a shared bus, and a single $45 inspection at the root cures all three. No other mobile game turns *reliability-centered maintenance* into the core loop.

---

## 3. Core Gameplay Loop

**Time.** Continuous minute-ticks. `TICKS_PER_DAY = 480` (an 8-hour shift). Campaign `D_MAX = 10` days. Player controls a time throttle (Pause / 1× / 2× / 4×). The day boundary is a planning beat, not a rules change.

**The loop, per day:**

```
PLAN ──► RUN (time advances) ──► REVIEW ──► PLAN(d+1) …
 │         │                        │
 │         └ wear ramps, faults      │
 │           emerge, tech works,     │
 │           cash accrues/bleeds     │
 └ assign tech jobs, buy parts,      └ settle wages/energy/rent/parts,
   set target run-rate, queue          show revealed condition + finance,
   upgrades (also doable live-paused)   test win/loss
```

- **PLAN** — the only place money and the tech's queue are committed. Assign **Inspect / Repair / Upgrade / Replace / Ignore** to specific machines; buy spare parts (per type); set the line's target run-rate.
- **RUN** — the clock moves; the **inspect → diagnose → act → verify** loop runs here; ignored conditions worsen.
- **REVIEW** — settle finances, show the *only-what-you-revealed* condition report, test win/loss.

**Tick order is load-bearing** (throughput solved before wear so wear sees this tick's duty; breakdowns after wear; economy last):

```
stepSim(dt):
  1 solveUtilities   — air bus: P_air + moisture from compressor channels
  2 solveThroughput  — dependency factors → chain min → per-machine rate (pure reads)
  3 advanceWear      — integrate wear ONCE per tick (uses duty from step 2)
  4 rollBreakdowns   — seeded hazard per machine → maybe hard fault
  5 advanceTech      — travel/job timers; on complete apply effects
  6 accrueEconomy    — cash += revenue − energy − wages − overhead − maintenance
  7 sampleUI         — expose only revealed/observable signals
```

**Contract:** wear/breakdown state is integrated only in steps 3–4. `solveThroughput` and `effParam` are pure reads and never mutate wear, so the throughput solve is idempotent.

---

## 4. First 3D Level Layout

A **12-column × 8-row isometric floor** (columns A–L = x0–11, rows 1–8 = y0–7). One tile = 2 m → plant is 24 m × 16 m. Fixed-angle isometric camera. The value-adding line runs left-to-right along the back wall then turns **down** toward the shipping dock at bottom-right, forming an **L** — deliberately compact for the eye, with the utility and tool crib **off** the flow so travel time is a felt cost.

| Element | Tile (center) | Footprint / note |
|---|---|---|
| **MIX-100** Mixer | (2, 2) | back-left, by the ingredient store; 1×1 |
| **CNV-200** Feed Conveyor | (4.5, 2), spans (3,2)–(6,2) | long belt, physically bridges Mixer→Oven |
| **OVN-300** Tunnel Oven | (7.5, 2), occupies (7,1)–(8,3) | largest footprint, against back wall for venting; tech routes **around** it |
| **COOL-350** Cooling Rack | (8.5, 2)–(9, 2.5) passive | non-serviced cooling tunnel between oven and slicer (see §5 note) |
| **SLC-400** Slicer | (9, 3) | line turns downward as cooled loaves exit |
| **PKG-500** Packager | (10, 5) | by the shipping dock (11, 6) |
| **CMP-900** Air Compressor | (1, 7) | bottom-left corner, deliberately **far** from the slicer/packager it feeds |
| **Tool Crib / Parts + Tech spawn** | (5, 7) | bottom-center; balanced average walk, far corners still cost |

**Why:** (1) the three pneumatic consumers (Mixer top-left; Slicer & Packager bottom-right) sit at opposite ends from each other and from the compressor, so when the compressor's moisture fault surfaces the symptoms are **spatially scattered**, selling the misdiagnosis. (2) The oven's central bulk is a physical obstacle adding a **+2-tile detour** to any Mixer/Conveyor ↔ Slicer/Packager path. (3) The compressor in the dead corner makes its long jobs the most travel-expensive — the sneaky single point of failure is also the most annoying to reach.

---

## 5. Machine List + Full Stat Tables

**These are the canonical numbers. §18 and §24 use exactly these.** All machines start **worn** (it's a retrofit; the plant is decades past design life). `baseOutputPerHr` is capacity at full health; `downtimeCostPerHr` is a per-machine **severity weight** used for UI ranking and the WIP-scrap charge basis (the *economic* downtime charge is foregone revenue + $40/machine-hr scrap; see §8/§24).

### 5.1 Core machine stats

| Machine | Start H% | Base out/hr | Energy $/hr | Breakdown risk %/day @start | Up lvl | Repair $ | Inspect $ | Downtime wt $/hr | Crit 1–5 | Depends on |
|---|---|---|---|---|---|---|---|---|---|---|
| **MIX-100** Spiral Mixer | 72 | 210 | 2.5 | 6 | 1 | 220 | 40 | 110 | 4 | compressor (dosing only) |
| **CNV-200** Feed Conveyor | 58 | 155 | 1.2 | 12 | 1 | 260 | 35 | 150 | 5 | mixer |
| **OVN-300** Tunnel Oven | 55 | 140 | 14 | 9 | 1 | 400 | 60 | 150 | 5 | conveyor |
| **SLC-400** Slicer | 68 | 180 | 2.0 | 7 | 1 | 150 | 25 | 95 | 3 | oven, compressor |
| **PKG-500** Packager | 63 | 165 | 2.8 | 5 | 1 | 190 | 30 | 120 | 3 | slicer, compressor |
| **CMP-900** Air Compressor (utility) | 61 | 40 SCFM | 6.0 | 8 | 1 | 300 | 45 | 150 | 5 | — (cascade root) |

**Healthy chain min = Oven @ 140/hr → 1,120/day** (capped at the 800 contract). Worn-start chain ≈ 840/day — thin headroom, so **breakdowns (full stops), not gentle sag, drive the loss.** COOL-350 is a passive cooling tunnel (gives the slicer a physically coherent cooled feed; never wears, never serviced, not in the serviceable list).

### 5.2 Failure channels — three per machine, each an `effParam` override

Every machine has exactly three wear channels. Mode maps to how the channel overrides a param: **DRAG** = `scale baseRate` (slows), **DRIFT** = `offset power` or `scale quality` (waste/scrap, no stop), **SEIZE** = hazard-driven hard stop (`baseRate→0`). `k_c` is per-tick base wear rate. Moisture-sensitive seal channels multiply their wear by `S = 1 + 1.5·moisture`.

| Machine | Channel (mode) | k_c | Part $ | Service MTTR | Fail MTTR | Emerges as |
|---|---|---|---|---|---|---|
| **Mixer** | Main-shaft bearing (DRAG) | 0.00010 | 260 | 2.0 h | 4.0 h | rising current, growl, mix times creep |
| | Drive V-belt tension (SEIZE) | 0.00013 | 45 | 2.0 h | 4.0 h | start-up squeal → belt snaps, starves conveyor |
| | Pneumatic bowl-lift/gate seal (DRIFT→dosing quality, moist-sens) | 0.00011 | 70 | 2.0 h | 4.0 h | slow tilt, mis-dosed batches → **scrap**, not a line-stop |
| **Conveyor** | Belt tension / mistracking (SEIZE) | 0.00020 | 120 | 2.5 h | 3.5 h | belt walks off, jams → **starves oven** |
| | Idler/roller bearing (DRAG) | 0.00013 | 55 | 2.0 h | 3.5 h | squeak → grind → drag stalls belt |
| | Gear reducer (DRIFT→power) | 0.00010 | 180 | 2.5 h | 3.5 h | speed variance, whine, oil weep |
| **Oven** | Heater element aging (DRAG) | 0.00016 | 210 | 2.0 h | 3.0 h | pale crust, throughput sags (fastest — always at duty=1) |
| | Door/gasket heat-loss (DRIFT→power) | 0.00013 | 95 | 2.0 h | 3.0 h | energy bill climbs, uneven bake |
| | **Burner/ignition control (SEIZE)** | 0.00011 | 175 | 2.0 h | 3.0 h | flame-out → **hard stop** (the channel that can actually seize) |
| | *Thermocouple drift (DRIFT→quality)* | folded into gasket channel's quality term | — | — | — | **silent under-bake → scrap**, no stoppage, no alarm |
| **Slicer** | Blade dulling (DRAG) | 0.00010 | 40 | 1.0 h | 2.5 h | torn slices → **RTF-optimal channel** (cheap, fast, no cascade) |
| | Blade-drive crank bearing (DRIFT→quality) | 0.00009 | 85 | 1.0 h | 2.5 h | knocking, misalignment |
| | Pneumatic pusher seal (SEIZE, moist-sens) | 0.00016 | 50 | 1.0 h | 2.5 h | weak push → jams (2nd cascade victim) |
| **Packager** | Heat-seal element (DRIFT→quality) | 0.00010 | 65 | 1.5 h | 2.0 h | weak seals → spoilage/rework |
| | Gripper seal (SEIZE, moist-sens) | 0.00016 | 55 | 1.5 h | 2.0 h | drops loaves → jam (1st cascade victim) |
| | Film-feed roller (DRAG) | 0.00009 | 45 | 1.5 h | 2.0 h | film slip → **RTF-optimal channel** |
| **Compressor** | Dryer/auto-drain — **MOISTURE** (DRIFT→bus) | 0.00020 | 75 | 2.0 h | 2.0 h | water at drip legs, **intermittent misfires on 3 machines at once** |
| | Header leak (DRIFT→pressure+power) | 0.00016 | 35 | 1.5 h | 1.5 h | runs continuously, pressure sags, energy climbs |
| | Piston ring/valve (SEIZE) | 0.00014 | 320 | 2.0 h | 5.0 h | overheat seizure → **total pneumatic loss** (5 h + corner walk) |

**Note (mixer pneumatics are non-line-stopping):** the mixer heads the serial chain, so if its pneumatics could stop it, any air loss would trivially zero the whole line and mask the downstream symptoms. Instead the mixer's air seal drives **dosing quality (scrap), not run/stop** — so partial air loss produces genuinely *distributed* degradation across the three consumers, preserving the misdiagnosis puzzle. A mixer hard stop can still come from its own mechanical SEIZE (V-belt) channel.

---

## 6. Breakdown & Maintenance System

### 6.1 Health decay (F1)

Per running channel, per tick: `Δwear_c = k_c · duty_i · S_c · dt`, `wear_c = clamp(wear_c + Δwear_c, 0, 1)`.

- **`duty_i`** is the wear driver. Because a serial no-buffer line paces every machine to the same throughput `T` (conservation of flow), a machine passing `T` loaves makes the same number of cycles whether or not it has spare capacity — so **cycle-driven wear tracks the line's absolute run-rate `T`, not headroom.** `duty_i` is the machine's run-hours fraction (the bottleneck runs at duty 1; upstream/downstream machines that stall waiting also lose duty). A separate **overstress** term (`> ratedLoad`, heavy-rye batches, over-temp) folds into `S_c` and is the only genuinely superlinear contributor.
- **`S_c`** is the cascade seam. For moisture-sensitive pneumatic seals, `S_c = 1 + 1.5·moisture`; else 1. Moisture is *not* a scripted event on the slicer — it is a multiply in F1.

*Implementation note for tuning:* the shipped reference sim expresses `duty` via the `u`-form in §24; the physical intent is the cycle/run-hours reading above. The whack-a-mole coupling (§7.1) is therefore driven by **raising the line's target run-rate after an upgrade** (every machine cycles faster), which is real, not by rewarding unused capacity headroom.

### 6.2 Health & hidden condition (F2)

`H_c = 1 − wear_c` (per channel, **hidden**). `H_i = min_c H_c` (weakest-link). `min` (not average) so a single bad channel is diagnosable — the player must find *which* one, which is what makes Inspect worth paying for. The floor UI shows only coarse observables (a rate dip, a vibration/steam icon, rising energy, a scrap pile); the precise per-channel number is fog until revealed.

### 6.3 Breakdown risk (F4)

`λ_i = λ0_i · exp(6.0·(1 − H_i))`; `p_break = 1 − exp(−λ_i·dt)`; seeded roll fires → weakest channel `wear→1`, `brokenDown=true`. `λ0_i` is calibrated per machine so day-1 risk equals `breakdownRiskPctPerDayAtStart` from §5. **The hazard is nonzero even at freshly-serviced health** (H=0.92 → ≈1.6·λ0): maintenance *reduces* surprise probability, it cannot zero an irreducible baseline. Risk is smooth and rising, never a cliff — run-to-failure is a gamble whose odds you can feel.

### 6.4 The three failure modes, all overrides

DRAG (quiet throughput loss), DRIFT (energy waste or quality/scrap — no alarm), SEIZE (stochastic hard stop). `triggerBreakdown` is not special-case code — it is the same override table pushed to its endpoint (`set baseRate→0`). Clearing it requires a tech repair job.

### 6.5 The maintenance triangle — all three optimal *somewhere*, at channel granularity

The triangle is real because different **channels** reward different policies, and Inspect is a genuine bet (0.5 tech-hr of the scarce budget, ±0.05 reveal noise, opportunity cost against repairing):

- **PREDICTIVE** (Inspect → act on a revealed **P-F window**): optimal for crit-5 and cascade-edge channels (oven element, conveyor belt, compressor moisture/piston, pneumatic seals). Delete the fog, repair the bad channel just before its risk band crosses threshold. Cost is the looking.
- **PREVENTIVE** (blind cadence Repair): optimal for hard-to-inspect or safety-critical channels where a scheduled service beats paying to look every cycle. Wastes some remaining life.
- **RUN-TO-FAILURE** (Ignore): **provably optimal for cheap, fast-swap, non-cascade DRAG channels** — specifically the **slicer blade** ($40, 1 h, no bus edge, low $95/hr severity) and the **packager film-feed roller** ($45, 1.5 h). Expected downtime cost < inspection+repair cost, so ignoring until the symptom is correct.

**The winning play is a *mixed* policy** — predictive on the air bus and crit-5 machines, run-to-failure on the two cheap DRAG channels, preventive where inspection isn't worth the tech-minute. A pure policy is never optimal; that mixed optimum is the game.

### 6.6 Inspection reveal (F11)

On Inspect complete: each channel `revealed=true`, `revealedValue = clamp(wear_c + N(0, 0.05), 0, 1)`, **and** a failure-probability band / time-to-threshold **P-F window with confidence** (not a point date — a SEIZE is stochastic). Inspect costs the machine's `inspectCost`, 0.5 tech-hr, **zero line downtime**. Revealing changes what the player knows, never the wear.

### 6.7 Repair restoration — one model, everywhere

**Repair resets the serviced channel to `wear = REPAIR_FLOOR = 0.08` (health → ~92%, near-new but not perfect).** This single model propagates to the economy (§8) and UI (§11): a service never restores to 100%. **Restore-to-new is the Replace verb only.** `effCost(Repair)` reads state: planned (not broken) → part @1.0×, labor $150, service MTTR; emergency (post-seizure) → part @2.5× (or consume stock), labor ×2.0, +180 min delivery if unstocked, fail MTTR, +$400 cascade collateral. The premium is data on the ordinary Repair verb, not a branch.

---

## 7. Upgrade / Retrofit System

**L1 ships five verbs** — Inspect, Repair, Upgrade, Replace, Ignore. Automate and Monitor (condition sensor) are gated to Levels 3+ (they only pay back over a longer campaign / with sensor capital), so L1 never shows a dead button. Replace is the **recovery** verb: correct only when a machine is driven so far gone that `Repair`'s 0.08 floor can't economically hold it (repeated emergencies), where a full reset beats another repair.

| Verb | Effect (F12) | Cost | Tradeoff |
|---|---|---|---|
| **Inspect** | reveal per-channel wear + P-F band | inspectCost, 0.5 tech-hr, **0 downtime** | the predictive enabler; recurring tech-minute cost |
| **Repair** | serviced channel `wear→0.08` | part + $150 labor, service MTTR (line down) | restores near-new; emergency premium read from state |
| **Upgrade** (L1→L2) | `baseRate ×= 1.4` | $1,500, 3 tech-hr install | raises capacity → **moves the bottleneck & wear hotspot** |
| **Replace** | new machine, all `wear→0`, spec bump | highest cash, long down | recovery for a machine too far gone; overkill otherwise |
| **Ignore** | nothing | $0 | run-to-failure default; wear + hazard climb |

### 7.1 The crucial coupling — an upgrade raises the whole line's cycle rate

In a serial line every machine runs at chain rate `T = min_i(r_i)`. Upgrade the current bottleneck (the oven) → its `r_i` rises → **`T` rises → every machine now cycles faster → cycle-driven wear climbs across the line**, fastest on whatever is now the new slowest link. This is emergent from `min-of-chain` feeding F1 — no script couples them. Upgrade the oven → the **conveyor** (155/hr, next-slowest, highest 12%/day risk) becomes both the new bottleneck *and* the new wear hotspot. Whack-a-mole with teeth, and you did it to yourself.

### 7.2 The utility version — faster pneumatic machines draw more air

Air draw genuinely tracks demand: `airDraw_total = Σ_pneumatic drawPerUnit_i · r_i`. Speeding a pneumatic machine raises `airDraw_total` → compressor duty rises → it wears faster **and** delivered pressure sags (F5) → *every* pneumatic machine gets less air. A speed upgrade on one pneumatic machine can starve the others — emergent, via the shared bus, matching the numbers the sim actually runs.

---

## 8. Budget & Profit System

**Five resources:** production output (only revenue source), cash (win/lose is read off it), downtime, spare-parts stock (per type), technician-minutes (the hard scarcity — one tech, one job at a time). **Clock:** day = one 8-hour shift; campaign 10 days. Tech budget = 480 tech-minutes/day; every dispatch also burns 15 min travel → a realistic day is **3–5 actions.** You physically cannot inspect all six *and* repair *and* upgrade in a day.

### 8.1 Starting conditions & fixed costs

`STARTING_CASH = $8,000`. `TECH_WAGE = $240/day`, `OVERHEAD = $110/day` (fixed, paid whether the tech is busy or idle). All machines start worn (§5).

### 8.2 Revenue — the perishable wholesale contract

| Constant | Value |
|---|---|
| `CONTRACT_DEMAND` | 800 loaves/day |
| `PRICE` | $3.50/loaf (shipped up to demand) |
| `CONTRACT_FLOOR` | 400 loaves/day (below = a strike) |
| `SHORT_SHIP_PENALTY` | $600/day below floor |
| `SALVAGE` | $1.20/loaf (overproduction, or all revenue post-cancellation) |

Two consequences fall out: overproduction is nearly worthless (a natural ceiling on upgrade ROI past 800/day), and **consistency beats peak** — a line reliably shipping 780/day out-earns one that peaks at 1,000 but craters on a breakdown day. Reliability, not horsepower, is what you buy. **Line output = min-of-chain** (F8); any core machine down, or the compressor's piston seized, → output 0 for that interval.

### 8.3 Energy

`ENERGY_PRICE = $0.18/kWh`. Worn machines draw more for the same output (DRIFT channels `offset` power). The compressor's leak channel raises its draw *before* it ever fails — a neglected compressor quietly bleeds extra power for days. You pay for neglect on the electric bill long before the breakdown.

### 8.4 Spare parts — per type, stock-ahead vs premium

**Six part types, individually stockable.** Stock ahead → normal price, on-hand instantly (no wait). Emergency (unstocked, machine down now) → **normal × 2.5** and **+180 min delivery** (machine stays down the whole time). Held stock freezes cash (a resource) and is wasted if you later Replace/Upgrade. Predictive play converts emergencies into planned jobs, so it buys every part at 1.0× and never eats the delivery wait — a large slice of its edge.

### 8.5 The downtime cost model — **foregone revenue + $40/machine-hr scrap only**

The serial line already zeroes throughput when a machine stops, so lost loaves are captured as **foregone revenue** — there is no separate lost-throughput rate (double-charging would make every policy insolvent). The only *additive* downtime charge is `WIP_SCRAP = $40/machine-hr` down, plus the fixed unplanned penalties: emergency part 2.5×, +180 min delivery, `CASCADE_DAMAGE = $400` collateral per run-to-failure seizure, and the $600 short-ship penalty when daily output < floor.

**Worked contrast, oven element, planned vs unplanned:** planned service (part $210 @1.0×, $150 labor, 2 h at scrap $40/hr + brief foregone revenue) ≈ **$600–800**; unplanned seizure (part $210 @2.5× = $525, labor ×2 = $300, +3 h delivery + 3 h teardown of foregone revenue, +$600 penalty, +$400 cascade) ≈ **$4,000+**. Same channel, same Repair verb. The 5×+ gap is entirely emergent from three state flags — that gap *is* the game's argument for maintenance.

### 8.6 Why PREDICTIVE > PREVENTIVE > RUN-TO-FAILURE

Inspection is cheap ($25–60) and non-disruptive (0 downtime) relative to what condition data lets you avoid: the 2.5× premium, the long unplanned downtime, the $600 penalty, the cascade. Predictive beats preventive because acting on actual P-F windows spends nothing on healthy channels and wastes no remaining life; preventive beats run-to-failure because planned short downtime + stocked parts + no cascade beat an unplanned line-stop. All three remain *viable per channel* (§6.5). The ordering is produced by money logic, proven in §18, not asserted.

### 8.7 Master constants (economy)

`STARTING_CASH 8000` · `WIN_CASH 20000` · `PRICE 3.50` · `SALVAGE 1.20` · `CONTRACT_DEMAND 800` · `CONTRACT_FLOOR 400` · `SHORT_SHIP_PENALTY 600` · `ENERGY_PRICE 0.18` · `TECH_WAGE 240` · `OVERHEAD 110` · `TECH_MIN_PER_DAY 480` · `TRAVEL_MIN 15` · `INSPECT_MIN 30` · `EMERGENCY_PART_MULT 2.5` · `EMERGENCY_DELIVERY_MIN 180` · `LABOR_REPAIR 150 / EMERGENCY ×2.0` · `CASCADE_DAMAGE 400` · `WIP_SCRAP_RATE 40` · `UPGRADE_COST 1500 / TIER 1.4` · `REPAIR_FLOOR 0.08` · `SIGMA_INSPECT 0.05` · `STRIKES_TO_LOSE 3` · `HEALTH_CONDEMN 0.15`.

---

## 9. Production Bottleneck System

**F5 — air bus (solved first):** `P_air = 7.0·(1 − 0.35·wear_leak)·min(1, cap/airDraw_total)`; `moisture = min(1, 0.05 + 0.75·wear_moist)`. Compressor piston seized → `P_air=0, moisture=1`.

**F6 — dependency factors:** `airFactor_i = clamp((P_air − 4.0)/(7.0 − 4.0), 0, 1)` for pneumatic consumers; `matFactor_i = (matIn.level>0)?1:0`. Below `P_min = 4.0 bar` clamps can't actuate → `airFactor→0`.

**F7 — per-machine rate:** `r_i = effParam('baseRate')_i · (pneumatic? airFactor : 1) · (brokenDown? 0 : 1)`. Every wear channel that scales baseRate already lowers `r_i` through the chokepoint.

**F8 — chain throughput:** `T = min_i(r_i)` over Mixer→Conveyor→Oven→Cooling→Slicer→Packager. No buffers → any `r_i=0` ⇒ `T=0`.

**F9 — duty/utilization:** `u_i = clamp(T / capacity_i, 0, 1)`; `u_compressor = airDraw_total/(40·dragScale)`. Bottleneck = `argmin_i r_i`; the UI paints it live so the player *sees* the mole move.

**Two explicit shared dependencies, both pure data:** conveyor jam → oven's `matIn` drains → oven `matFactor→0` (oven "fails" with nothing wrong with the oven); compressor moisture/leak → the three pneumatic consumers via F5/F6. The constraint is *wherever the worst number currently is* and moves on its own as wear accrues or you upgrade.

**The cascade, traced end to end (compressor → slicer/packager):** root is the aging plant preloading `compressor.moisture` wear high; it ramps unwatched. Moisture climbs → `S = 1 + 1.5·moisture` accelerates the slicer & packager seal wear (a multiply in F1, no code says "moisture damages the slicer") → those seals drift and their hazard climbs → the slicer becomes `argmin` and the constraint visibly jumps there → ignored further, its seal hazard fires and the line stops. **Moisture's first-order symptom is *intermittent* pneumatic misfires on all three consumers at once** (the diagnostic signature); hard seizure is the multi-day consequence of prolonged neglect. **The discriminating test:** a $45 compressor inspection reveals sagging pressure + high moisture and points *past* the slicer; repairing the compressor dryer at the root ($75, 2 h) cures all three. One root fix, three machines — the payoff for diagnosing instead of guessing.

---

## 10. Win & Lose Conditions

**Win:** end Day 10 with cash ≥ `$20,000` (from $8,000 = +$12,000 net), no lose condition tripped. One number, watched all game. It can't be reached by hoarding (you'd ship too little) or by pure horsepower (overproduction is salvage-priced) — only by *reliability*.

**Star grade:**

| Grade | Condition |
|---|---|
| ★ | end cash ≥ $20,000 |
| ★★ | ≥ $24,000 and zero strikes |
| ★★★ | ≥ $28,000, zero strikes, and **no *preventable* unplanned failure** (no seizure above a hazard threshold you had inspection data on) — rewards acting on information, not dodging the baseline dice |

**Lose:**

| # | Lose | Trigger |
|---|---|---|
| L1 Bankruptcy | `cash < $0` at any moment |
| L2 Contract cancelled | 3 short-ship strikes (daily output < 400) → unwinnable, immediate loss |
| L3 Plant condemned | fleet average health < 0.15 |
| L4 Objective failed | Day 10 ends with cash < $20,000 (scored retry, not sudden death) |

L1 kills reckless neglect; L2 kills cash-hoarding-by-under-producing; L3 kills strip-mining. **Tail de-risk (so a perfect predictive run isn't lost to variance):** imminent seizures telegraph harder near the deadline; the player holds **one expedited-part token** (bounded recovery — skips the 180-min delivery on one emergency); late-campaign hazard is softened so the last two days aren't a coin-flip on an earned win. Tuning targets a **+15–20% PdM cushion** validated across a seed spread, with PM landing just below.

**Acceptance bands (reference seed, must all hold):** RTF ends below $12k or trips L1/L2; PM lands $17k–$19.5k (below the bar); competent PdM clears ≥ $21k; every policy survivable-to-Day-10 on *some* channel subset; a single unlucky cascade recoverable, two not.

---

## 11. Mobile UI Layout

**Portrait-locked, one-thumb, bottom-sheet, stage→confirm commit.** Top 12% HUD (display-only), 55% play area, 8% persistent tech strip, bottom 25% dock/sheet (the only surface that receives committing taps).

**HUD (read-only, peek popovers only):** 💵 Cash · 📅 Day 3/10 · 📦 Output% (of quota) · ❤ Reliability% (fleet min-aware). A fifth peek — **⚠ Quality% / reject rate** — is surfaced on the Output popover so silent scrap faults (oven thermocouple drift, packager seal) have an observable tell without an alarm. Tapping Reliability names the worst machine and deep-links to it. The current bottleneck carries a 🔻 pip and a floor marker.

**Machine selection → bottom sheet** (not radial: six actions need cost/time/consequence lines a radial can't hold, and the sheet lives in the thumb zone). Tap machine → 250 ms soft-focus → sheet slides up:

```
OVEN #3                    ❤ 44% ▼
Status: RUNNING · HOT
Wear 56% · Duty 90% · P-F ~2–4 d
Fed by: Conveyor   Feeds: Cooling
┌──────────┬──────────┐
│🔍 Inspect │🔧 Repair │
│ $60 · 0.5h│ $360·2h  │
├──────────┼──────────┤
│⬆ Upgrade  │♻ Replace │
│$1.5k·3h   │ $2.5k·5h │
├──────────┴──────────┤
│      ✋ Ignore  free  │
└─────────────────────┘
```

Each action is a **card** showing cost + tech-hours (pillar 6). Un-inspected condition chips read `? ? ?`. **Fast path:** low-cost/no-downtime actions (**Inspect**) commit in **one tap**; a machine long-press does a one-tap inspect; only money-committing or line-stopping actions (Repair/Upgrade/Replace) use the two-step stage→confirm consequence forecast. Cards greyed with a *reason* ("Needs belt part — 🛒 buy"), never a dead grey button. After an Inspect, a ✦ pip lights the implied action — guidance, not automation.

**Tech strip (persistent):** `🔧 Sam → walking to Oven · arrives 0:20 · then Repair 2h · 5h/8h used`. Tap → work-order queue (drag ≡ to reorder — the only non-camera drag, and never required; walk-chips between jobs show travel cost so batching nearby jobs is a visible skill).

**End-of-day report** (slides up, single thumb button, 5-second scannable): Output x/800, net cash broken down (sales/wages/parts/scrap), named **Events** (the cascade, e.g. "Compressor moisture → Slicer + Packager misfiring"), **loaves scrapped: under-baked** (attributes silent-fault loss), and tomorrow's teased bottleneck. Win = celebratory variant; loss = red variant with a one-line post-mortem + Retry.

---

## 12. Camera & Controls

Fixed-pitch (~30°) isometric, slight perspective, **no rotation** in MVP (one canonical angle → the player never gets lost and health reads consistently). Whole floor fits at default zoom.

| Gesture | Action |
|---|---|
| Tap machine | select + open action sheet |
| Tap empty floor | deselect |
| Tap tech avatar | open work-order queue |
| One-finger drag | pan (only past "fit"; clamped to floor) |
| Two-finger pinch | zoom (clamped: whole-floor min, single-machine max) |
| Double-tap machine | snap-zoom + select |
| Swipe down on sheet | dismiss |
| Long-press machine | one-tap Inspect fast path |

**No twitch, ever** — failures unfold over game-day seconds, not frames; a laggy bus ride never costs a machine. Light pan inertia, pinch toward centroid, haptic tick on select/commit/breakdown.

---

## 13. 3D Visual Style

**Clean high-poly "friendly industrial"** — beveled matte-PBR forms, soft AO, one warm key + cool fill, baked lighting + a light real-time emissive layer for state. Reads premium on a phone, stable at the fixed iso angle.

**Palette:** warm concrete floor `#C9C4BB`; steel body + bakery-amber accent `#E8A24A`; teal trim `#2FA6A0`. **Reserved state set** (never décor): healthy `#4CAF6D`, warning `#F2B234`, critical `#E5533D`, being-serviced blue `#3E8EF0`, dashed pneumatic cyan `#57C8E3`.

**Machine states (silhouette-readable, motion > color on small screens):** RUNNING-healthy (smooth loop, faint steam); RUNNING-worn (periodic hitch, spark flick, rust creep); DOWN (anim stopped, red beacon, smoke, ⚠); BEING-SERVICED (blue pulse, tech present, progress ring); **STARVED** (stopped but *no damage VFX*, amber "no input" icon, its dashed dependency line turns red and pulses toward the culprit). The **starved ≠ failed** distinction carries the cascade lesson without text.

**Health read redundantly** (survives small screens + colorblindness): rust/grime albedo lerp, steam/exhaust density, spark frequency ∝ hazard, a floating fill-ring (the colorblind-safe fallback), and motion crispness. **Scrap/quality faults get a visible reject pile VFX** so silent under-bake has a tell. **Bottleneck marker** = pulsing amber 🔻 chevron ring that physically *slides* to the new limiter when the constraint moves. **Technician "Sam"** (teal coveralls, bright hard-hat pip) walks literal travel time; path-line preview on queuing a distant job; ❓/📦 thought bubble when blocked on a part.

---

## 14. Factory Floor Layout

The 12×8 grid of §4, portrait-friendly. Process flow runs the back wall then turns down to the dock, forming the L. The **cooling tunnel COOL-350** sits between oven and slicer (physically coherent cooled feed for the blade). The **air compressor sits in the dead bottom-left corner**, its dashed cyan lines running long to Mixer (top-left), Slicer and Packager (bottom-right) — long air runs mean pressure drop and condensation en route, reinforcing the moisture failure mode and making every compressor job the highest travel penalty. The tool crib/tech-spawn at bottom-center balances the average walk while keeping the far corner and far-right packager costly.

**Tech walk model:** Manhattan pathing on the aisle grid (no diagonals), routing around the oven's (7–8, 1–3) footprint with a **+2-tile detour** on any upstream↔downstream hop. Walk speed 1.0 m/s (1.3 nominal de-rated for congestion/tools). `travelTime_min = ceil(manhattanTiles·2 / 1.0 / 60)`. A precomputed **7×7 distance matrix** (crib + six machines, detour folded in) drives job travel duration — the "sneaky compressor = longest walk (up to 12 tiles) + longest MTTR (5 h)" punishment is data, not geometry re-solved at runtime.

---

## 15. Player Progression

Within L1, mastery is the skill curve, not unlocks: (1) learn inspect→diagnose→repair→verify; (2) learn the three policies and that they apply *per channel*; (3) learn the compressor cascade and the discriminating test; (4) learn to juggle five resources against one tech; (5) learn bottleneck migration; (6) learn the mixed-policy optimum (predictive on the bus + crit-5, RTF on the two cheap DRAG channels). Star grades give the "hard to master" ceiling: ★ is a pass, ★★ demands zero strikes, ★★★ demands zero *preventable* failures — a reason to replay with tighter tech-minute hygiene. New verbs (Automate, Monitor sensor) and a second tech unlock across Levels 2–5, not L1.

---

## 16. Level Progression

Each level adds **one** major system; the engine never gains scripted content, only more machines and tighter constraints.

- **L2 — Bigger Bakery:** +Proofer (before oven, humidity/steam-valve wear) and +Depanner (a **fourth** pneumatic consumer on the same bus → bigger single-point blast radius). Cash tighter, larger order. **Night-shift energy tariff** (1.5× past hour 8). First deliberately overlapping multi-fault to stress the one-tech queue.
- **L3 — Two Lines + Supply Chain:** a second parallel line (balance load; a fault on A partly absorbed by B). **Spare-parts stockouts with lead times** (the parts resource finally bites). **Monitor sensor upgrades** purchasable — continuous condition data instead of per-inspection, making predictive a capital decision. **Automate** becomes viable here.
- **L4 — Second Technician + 24h Ops:** unlock a second tech (schedule two against travel/idle; floor distances become an optimization). Full 24-hour running — no free maintenance window, wear ramps faster. A reliability SLA fine makes preventive mandatory.
- **L5 — Portfolio / Terminal Plant:** hardest cash constraint, heavily-worn plant (or a portfolio sharing one budget). Simultaneous compound cascades the norm. Central decision: **Retrofit vs Replace.** Market price swings (loaf/energy volatility) make finance the primary difficulty. All six pillars at maximum.

---

## 17. Tutorial Flow

Taught through *doing* across the first days via spotlight/dim/step-gating — never a wall of text. Each beat: dim except the target, one coach line, one required tap. Days 1–3 are cost-softened (the player can't fail); actions are real so muscle memory transfers. Skippable after beat 1.

- **Day 1 — the loop:** the Mixer stutters (pre-seeded high wear). Tap → chips read `? ? ?` → **Inspect** (watch Sam walk: "time is a resource") → diagnosis reveals a worn bearing, ✦ on Repair → **Repair** → verify it runs smooth, health up. End-of-day report shown with only relevant lines lit.
- **Day 2 — the triangle:** the Oven ages; three mini-cards animate in — Predictive / Preventive / Run-to-failure — and the player *chooses one channel policy* for it. Whatever they pick plays out for real, so they feel the consequence.
- **Day 3 — the compressor cascade (set-piece):** the compressor's moisture has quietly climbed (visible heavier exhaust — reward for watching). Pneumatics start **misfiring intermittently** on Mixer/Slicer/Packager — scattered, *no damage* — dashed lines pulse red toward the compressor. Tapping a starved machine shows "Nothing wrong here — culprit: Air Compressor 🔻." Inspect/Repair the compressor → all three recover at once.
- **Day 4+ — soft release:** upgrade the Oven → the 🔻 marker visibly slides to the Conveyor ("throughput is only as fast as your weakest link"). Highlighting fades; the full five-resource juggle and the contract clock go live.

**Session pacing:** ~30–45s days at 1×; a full 10-day run is a **~8–10 minute think-y session** (the honest length of the planning-burst the economy rewards). Marketed as a strategy session game, not a 4-min tapper. Event-driven time controls (⏸/1×/2×/4×, bottom-right); **auto-slow (or soft toast) fires on the *first symptom / threshold crossing*, not only on failure** — so fast-forward surrenders control while a preventive decision still exists, training predictive over reactive. Opening an action sheet soft-pauses the world. End-of-day = the natural quit point; progress saves at every day boundary; **no offline decay** (a strategy game, not a chore).

---

## 18. Example 10-Day Gameplay Scenario

Deterministic reference seed (mulberry32, seed 1234567, 480 ticks/day). Two policies run verbatim from the tuned pass.

### 18.1 RUN-TO-FAILURE (do-nothing) — loses Day 7 (L2)

| Day | Cash end | Output | Downtime hrs | Spares | Tech-hrs | Key events |
|---|---|---|---|---|---|---|
| 1 | $10,461 | 847 | 0 | 0 | 0 | Nominal; ships 800 (capped). Compressor moisture already 0.39 and rising unwatched; no spend. |
| 2 | $12,868 | 801 | 0 | 0 | 0 | Ships 800. Moisture 0.44; slicer seal 0.51, packager seal 0.60 (accelerating via S=1+1.5·moisture). Cash peaks. |
| 3 | $14,240 | 533 | 2.4 | 0 | 2.3 | PACKAGER seizes (gripper seal, moisture-driven) + OVEN burner seizes. Output sags to 533 (~$935 lost rev). Cascade begins. |
| 4 | $11,435 | 0 | 16.6 | 0 | 8 | SLICER seizes (pusher seal) — 2nd victim. Line fully down → STRIKE #1. Unstocked emergencies: 3h delivery each. ~$2,800 lost rev + $600 penalty. |
| 5 | $7,674 | 86 | 7.8 | 0 | 7 | Emergency repairs slicer (+$375) & oven (+$525). Output 86 → STRIKE #2. $1,375 emergency parts + $800 cascade dmg. |
| 6 | $9,416 | 618 | 0.7 | 0 | 0.7 | MIXER stops (mechanical channel under total neglect) — 3rd machine felled by the same root. Brief recovery, moisture 0.66. |
| 7 | $6,770 | 0 | 10.2 | 0 | 8 | CONVEYOR belt seizes → line down → STRIKE #3 ⇒ **L2 CONTRACT CANCELLED (LOSS).** |
| 8 | $5,025 | 174 | 5.3 | 0 | 5.3 | Post-cancellation (salvage only). Emergency conveyor repair (+$650). Moisture 0.77. |
| 9 | $4,364 | 24 | 7.6 | 0 | 7.6 | COMPRESSOR itself seizes (piston/moisture) — the root finally fails. Total pneumatic loss, output 24. |
| 10 | $3,631 | 945 | 0.6 | 0 | 0.6 | Emergency compressor repair (+$750, 5h). Line recovers mechanically but the contract is gone; ends **$3,631** (goal $20,000). |

### 18.2 PREDICTIVE / SKILLED — wins Day 10 at $20,702

| Day | Cash end | Output | Downtime hrs | Spares | Tech-hrs | Key events |
|---|---|---|---|---|---|---|
| 1 | $9,726 | 847 | 2.2 | 0 | 6.9 | Full condition sweep: inspect all 6 (zero line-downtime) + pre-empt the known-worst conveyor (H0 58%, 12%/day). Fog deleted; still ships 800. |
| 2 | $11,078 | 904 | 4.5 | 0 | 4.5 | Service the two crit-5 fast movers nearest failure: OVEN element + COMPRESSOR moisture ROOT (kills the cascade at source). Moisture 0.39→0.13. |
| 3 | $12,935 | 1,005 | 3.0 | 0 | 3.8 | Reset slicer & packager pneumatic seals before the now-low moisture can bite. Re-inspect conveyor. All parts @1.0×, no wait. |
| 4 | $13,385 | 999 | 5.5 | 0 | 7.1 | Service mixer + THE ONE SMART UPGRADE: Oven L1→L2 (×1.4). Shipped output stops sagging with oven wear. |
| 5 | $15,116 | 971 | 3.5 | 0 | 4.3 | Conveyor is now the binding constraint post-upgrade → service it. Slicer kept on tight cadence. Cash climbing. |
| 6 | $14,473 | 326 | 7.5 | 0 | 8 | Service compressor at the root again. One unlucky MIXER seizure slips through → output 326 → STRIKE #1 (the thin-margin bite). Recoverable. |
| 7 | $14,494 | 746 | 5.3 | 0 | 6.9 | Emergency repair mixer (+$550) — the single recovered failure. Re-service slicer & packager. No 2nd strike. |
| 8 | $16,235 | 1,047 | 4.5 | 0 | 4.5 | Service conveyor + mixer. Ships 800, cash recovering fast; zero surprises. |
| 9 | $18,370 | 1,071 | 2.2 | 0 | 3.8 | Final compressor root touch-up; inspect slicer/packager to coast. Ships 800. |
| 10 | $20,702 | 1,032 | 1.3 | 0 | 1.3 | Light slicer service, ship 800. Ends **$20,702 ⇒ WIN by $702** (+3.5%): a thin margin, one recovered emergency, zero cascade. |

**Strategy proof (reference seed):** RTF trips L2 on Day 7 and bleeds to $3,631; blanket PM survives but ends $17,317 (L4, short by $2,683 — over-services healthy channels *and* is still surprised twice); competent PdM wins at $20,702. Ordering **$20,702 > $17,317 > $3,631** is produced, not asserted. Determinism verified (RTF twice → $3,631 == $3,631). The mixed-policy optimum (predictive on the bus + crit-5, RTF on the slicer-blade and film-roller DRAG channels) beats all three pure policies — that mixed optimum is the game.

---

## 19. MVP Scope

One level (Old Bakery Plant), fixed chain Mixer→Conveyor→Oven→Cooling→Slicer→Packager + Air Compressor utility. Must-haves:

1. **Six machines as data-driven objects**, each with **three per-channel wear values** (0..1), pre-seeded high.
2. **Continuous minute-tick wear** (F1) from `k_c · duty · S_c`.
3. **The maintenance triangle, all three viable at channel granularity** — Inspect reveals per-channel wear + P-F band (noisy); Repair→REPAIR_FLOOR; Ignore→hazard.
4. **Cascade via a real air bus** — continuous `P_air` + `moisture`, `airFactor`, `S = 1 + 1.5·moisture` accelerating downstream seal wear; conveyor jam starves oven.
5. **Five live resources**, one tech (queue + travel + job time), per-part-type stock.
6. **Bottleneck = min-of-chain**, migrates emergently on wear/upgrade.
7. **Five verbs** (Inspect/Repair/Upgrade/Replace/Ignore) through `effParam`/`effCost`.
8. **Contract economy** — demand cap, floor, strikes, salvage, penalty; win = cash ≥ $20k by Day 10; L1–L4 losses.
9. **Single-slot save/load** including seed + absolute tick.
10. **Portrait UI** — HUD, tappable machines, bottom-sheet action menu (fast-path Inspect + stage→confirm), day clock + speed, persistent tech strip, quality/scrap readout, end-of-day report.

**Done =** player can win by mixed-policy play and lose by mismanaging any resource, with the compressor cascade emerging from the bus.

---

## 20. What NOT to Build Yet

No second factory / level select beyond one. No machine placement (topology fixed — retrofit, not construct). No belt-logistics item routing (conveyors are utilities with a jam state). No second technician, hiring, or tech skill trees. **Automate and Monitor verbs are deferred to L3+** (L1 ships a clean five-verb sheet, no dead buttons). No procedural generation, no market price fluctuation. No simulated dough items (throughput is numeric). No monetization/ads/IAP/analytics/cloud/backend/accounts. No story/cutscenes/dialogue. VFX limited to the minimum that distinguishes running/worn/down/**starved** + a scrap pile (color + one particle + the health ring). No localization; settings = volume + quit. No NavMesh — tech travel is a timed lerp driven by the precomputed 7×7 Manhattan+detour matrix. If a feature isn't required to prove the six pillars are fun, it's out.

---

## 21. Unity Scene Structure

Three scenes. `Boot` (a single `Bootstrap` spawns persistent managers via `DontDestroyOnLoad`, loads config, then `MainMenu`). `MainMenu` (Play/Continue/Quit/volume). `Factory` (the game):

- `--- MANAGERS ---` header; scene-scoped systems live here.
- **Environment** — floor shell, walls, baked lighting (scene objects, never instantiated).
- **`MachineAnchors`** — 6 machine slots + `TechDepot`; machines are **instantiated as prefabs onto anchors** from the `LevelDefinition`.
- **`Technician`**, **Camera Rig** (fixed iso ortho + pinch-zoom/clamped-pan), **UI Canvas** (ResourceBar, DayClock, ActionSheet, MachineTooltip, TechStatus, QualityReadout, WinLossPanel), **EventSystem**.

**Prefab vs scene:** prefab = anything instantiated 0..N (Machine, Technician, status badge, VFX, action-sheet button, floating text, decal). Scene object = exactly one, hand-placed (environment, anchors, camera, UI panels, managers).

**Managers:** persistent — `GameManager`, `TimeManager`, `EconomyManager`, `SaveSystem`, `AudioManager`. Scene-scoped — `UtilityBus`, `ProductionLine`, `DependencyGraph`, `MaintenanceSystem`, `UIController`. A static `Services` locator (`Services.Economy`, `Services.Time`, …) is the single reset point on level load. Systems talk only through events (`OnTick`, `OnDayBoundary`, `OnEconomyChanged`, `OnJobComplete`, `OnCascade`).

---

## 22. Unity Scripts / Classes

Layered: **Definitions (SO) → Runtime state → Systems → UI.** The build implements the **channel/bus minute-tick model** — this is materially more than a single-scalar-condition prototype and §25 budgets accordingly.

### Data layer (ScriptableObjects)

**`MachineDefinition`** — `id, displayName, prefab, icon; MachineRole role; float baseThroughput, baseEnergyDraw, ratedLoad, nominalPressureDraw; WearChannelDef[3] channels; UpgradeDefinition[] upgrades; float repairLaborCost, upgradeCost, replaceCost, inspectCost; string[] dependsOnUtilityIds; bool pneumatic; float downtimeSeverity;`

**`WearChannelDef`** (the fault-as-data core; **18 total**, 3 per machine) — `string id; ChannelMode mode (Scale/Offset/SetHazard); string targetParam (baseRate/power/quality/busPressure/busMoisture); float gain; float k_c; bool moistureSensitive; float lambda0; float partCost; float serviceMttrHours, failMttrHours; float busPressureInjection, busMoistureInjection; float preSeedWear;` — pre-seed is **per channel**, so "compressor moisture high, piston low" is expressible (that split *is* the cascade setup).

**`UpgradeDefinition`** — `id, displayName, tier; float throughputMult, wearMult, energyMult, cost, techHours;`

**`LevelDefinition`** — `List<MachinePlacement> (def + anchorId + per-channel preSeed); List<DependencyEdge> (from→to, MaterialFlow|Utility); float startingCash; PartStock[] startingParts (6 types); float techMinutesPerDay, travelMin, energyPrice, price, salvage; int contractDemand, contractFloor, strikesToLose, dayLimit; float shortShipPenalty, winCash, condemnHealth; int rngSeed; float[7,7] travelMatrix;`

### Runtime layer

**`MachineState : MonoBehaviour`** — mutable instance; **never mutates the Definition.** Holds `MachineDefinition def; float[3] wear; float duty; int upgradeTier; bool brokenDown; ChannelReveal[3] (revealed, value, pfBand);`. The **effParam chokepoint** (all gameplay reads through it, never raw base):

```
float EffParam(param):
  v = def.params[param] * UpgradeMult(param)
  foreach channel c targeting param:
    Scale:  v *= (1 - c.gain * wear[c])
    Offset: v += c.gain * wear[c]
  if brokenDown && param==baseRate: v = 0
  return v
float EffWear(c) = def.channels[c].k_c * duty * (moistSens ? 1+1.5*busMoisture : 1)
float Hazard()   = def.channels[c].lambda0 * exp(6.0*(1 - (1-wear[c])))
```

Methods: `TickWear(dt)`, `RollBreakdown(dt, seededRand)`, `ApplyRepair(channel)`, `ApplyUpgrade()`, `Replace()`, `Inspect(channel, noise)`, `RefreshVisuals()`.

### Systems layer

- **`TimeManager`** — the clock. Runs a **sub-day loop of 480 minute-ticks/day**, firing `OnTick(dt)` per minute and `OnDayBoundary` at each boundary. Pause/1×/2×/4× scale real→sim time; **absolute global tick** (not within-day) so jobs spanning a day boundary don't freeze the tech. One tick source → deterministic → trivial save/load.
- **`UtilityBus`** — solved first each tick: `P_air = 7.0·(1−0.35·wear_leak)·min(1, cap/airDraw_total)`; `moisture = min(1, 0.05 + 0.75·wear_moist)`; `airDraw_total = Σ drawPerUnit·r_i`. Exposes continuous `AirFactor(machine)`.
- **`ProductionLine`** — computes `EffParam(baseRate)·airFactor` per machine, `T = min-of-chain`, back-propagates duty, reports capped daily output to `EconomyManager`. Exposes `CurrentBottleneck`.
- **`DependencyGraph`** — built from edges; MaterialFlow (conveyor jam → oven `matFactor→0`) + Utility (consumes `UtilityBus.AirFactor`). Raises `OnCascade` for UI/VFX. Cascades emergent from data edges.
- **`EconomyManager`** — the ledger: per-part-type stock, contract logic (demand cap, floor, strikes, salvage, short-ship penalty), energy, wages, overhead, WIP scrap, cascade damage, capital. Win/loss checks (cash≥winCash; L1 cash<0; L2 strikes≥3; L3 fleet<0.15). `effCost(action)` reads state (stocked? broken? cascade?) → planned vs emergency price.
- **`MaintenanceSystem`** — validates affordability, enqueues `MaintenanceJob{target, channel, type, hoursRequired, cost, partType}` onto the Technician; applies effects on completion (Inspect→per-channel noisy reveal + P-F band; Repair→`wear[c]=0.08`; Upgrade→tier; Replace→wear all 0).
- **`Technician`** — `Queue<MaintenanceJob>`, one at a time; `minutesRemainingToday` (refilled each day boundary); travel duration from the **7×7 matrix** (charged against tech-minutes); jobs roll to tomorrow if minutes run out. Exposes `AvailableMinutes`, `CurrentJob`.
- **`SaveSystem`** — JSON DTO: cash, per-part stock, day, **per-machine {per-channel wear, tier, brokenDown, per-channel revealed}**, tech queue, cumulative output, strikes, **rngSeed + absoluteTick** (deterministic resume under the minute-tick model). Definitions resolved by `id` via a `DefinitionRegistry`.
- **`UIController`** — binds systems→UI, raycast tap-select; ActionSheet with live cost/hours/parts + fast-path Inspect; QualityReadout; "?" for un-inspected channels.

---

## 23. Prefab List

1. **`Machine.prefab`** (one generic, mesh-swapper) + 6 `MachineDefinition` SOs — or 6 variant meshes sharing `MachineState`.
2. **`Technician.prefab`** — rig + walk/kneel/idle anim + toolbox marker.
3. **`StatusBadge.prefab`** (pooled) — healthy/worn/inspecting/failed/starved/serviced icons.
4. **`SmokeVFX.prefab`** (pooled) — failure smoke/spark, keyed per channel.
5. **`ScrapPileVFX.prefab`** (pooled) — reject pile for quality faults.
6. **`ActionSheetButton.prefab`** — one action row (icon/label/cost/hours/parts).
7. **`FloatingText.prefab`** (pooled) — "−$450", "+120 units", "12 scrapped".
8. **`MachineTooltip.prefab`**, **`WinLossPanel.prefab`** (UI).
9. **`DependencyLine.prefab`** — dashed cyan pneumatic line, turns red/pulses on cascade.
10. **`DamageDecal.prefab`** — rust/leak decal by wear tier.

**SO assets:** 6× `MachineDefinition`, **18× `WearChannelDef`**, ~10× `UpgradeDefinition`, 1× `LevelDefinition_Bakery`.

---

## 24. Formulas (with the tuned constants)

**Tick order (per 1-min tick):** `solveUtilities → solveThroughput → advanceWear → rollBreakdowns → advanceTech → accrueEconomy`. Wear/breakdown integrated **once** per tick (steps 3–4); throughput/effParam are **pure reads**.

**F1 WEAR** (per running channel c): `Δwear = k_c · u_i² · S_c · dt`; `wear = clamp(wear+Δwear, 0, 1)`. `S_c = 1 + 1.5·moisture` for moisture-sensitive pneumatic seals, else 1. `dt = 1`. `k_c` per channel = 0.00009–0.00028 (§5). *Physical reading (§6.1): `u_i` is duty; cycle-driven wear tracks the line's absolute run-rate `T`, and the whack-a-mole coupling comes from an upgrade raising `T` (every machine cycles faster), not from unused headroom. The `u²` form is the shipped reference expression that produced §18's tables.*

**F2 HEALTH:** `H_c = 1 − wear_c`; `H_i = min_c H_c`.

**F3 effParam:** `effRate = base · upTier · Π_DRAG(1 − gain·wear) · Π_SEIZE(1 − 0.5·gain·wear)`, `= 0 if brokenDown`. `effPower = nominalPower · (1 + Σ_{DRIFT,LEAK} gain·wear)`.

**F4 HAZARD:** `λ_i = λ0_i · exp(6.0·(1 − H_i))`; `p_break = 1 − exp(−λ_i·dt)`; `seededRand() < p_break` → seize weakest channel. Calibrated: `λ0_i = −ln(1 − risk)/480 / exp(6.0·(1 − H0_i))` so day-1 risk = §5 `breakdownRiskPctPerDayAtStart`.

**F5 AIR BUS** (solved first): `P_air = 7.0·(1 − 0.35·wear_leak)·min(1, (40·dragScale)/airDraw_total)`; `moisture = min(1, 0.05 + 0.75·wear_moist)`; `airDraw_total = Σ drawPerUnit·r_i` (~32 SCFM at nominal). Compressor brokenDown → `P_air=0, moisture=1`.

**F6 AIR FACTOR:** `airFactor = clamp((P_air − 4.0)/(7.0 − 4.0), 0, 1)`.

**F7 PER-MACHINE RATE:** `r_i = effRate_i · (pneumatic? airFactor : 1) · (brokenDown? 0 : 1)`.

**F8 CHAIN THROUGHPUT:** `T = min_i r_i` over the serial chain (no buffers → any `r_i=0` ⇒ `T=0`).

**F9 UTILIZATION:** `u_i = clamp(T / capacity_i, 0, 1)`; `u_compressor = airDraw_total/(40·dragScale) ≈ 0.8`. Bottleneck at `u=1` = wear hotspot; upgrading it raises `T` → everyone's `u` → moves the hotspot.

**F10 CASH (daily):** `cash += revenue − energy − 240 − 110 − plannedParts − labor − inspectCost − emergencyPremium − cascadeDamage − wipScrap − capital − penalty`. `revenue = min(800, produced)·3.50 + max(0, produced−800)·1.20` (contract-cancelled: `produced·1.20`). `energy = Σ effPower_kW·(1/60)·0.18` per tick. `penalty = (produced<400)? 600 : 0` and `strike++`. `wipScrap = downMachineHours·40`. **Lost throughput is realized as foregone revenue, never double-charged.**

**F11 INSPECT:** `revealedValue_c = clamp(wear_c + N(0, 0.05), 0, 1)` + a P-F probability band; **zero downtime**, 0.5 tech-hr, costs `inspectCost`.

**F12a REPAIR** (one verb, cost read from state): planned → `wear_c → 0.08`, part @1.0×, labor $150, service MTTR (1–2 h). Emergency → part @2.5× (or consume stock), labor ×2.0, +180 min delivery if unstocked, fail MTTR (2–5 h), +$400 cascade damage.

**F12b UPGRADE:** `baseRate ×= 1.4`, cost $1,500, 3 tech-hr install.

**Constants:** `TICKS_PER_DAY 480 · D_MAX 10 · α 2.0 · μ 1.5 · κ 6.0 · P_NOM/P_MIN 7.0/4.0 · λ_leak 0.35 · M0/M_seal 0.05/0.75 · AIR_DRAW/COMP_CAP 32/40 · k_c 0.00009–0.00028 · STARTING_CASH 8000 · WIN_CASH 20000 · PRICE 3.50 · SALVAGE 1.20 · CONTRACT_DEMAND 800 · CONTRACT_FLOOR 400 · SHORT_SHIP_PENALTY 600 · ENERGY_PRICE 0.18 · TECH_WAGE/OVERHEAD 240/110 · TECH_MIN_PER_DAY 480 · TRAVEL_MIN 15 · INSPECT_MIN 30 · EMERGENCY_PART_MULT 2.5 · EMERGENCY_DELIVERY_MIN 180 · LABOR_REPAIR/EMERGENCY_MULT 150/2.0 · CASCADE_DAMAGE 400 · WIP_SCRAP_RATE 40 · UPGRADE_COST/TIER 1500/1.4 · REPAIR_FLOOR 0.08 · SIGMA_INSPECT 0.05 · STRIKES_TO_LOSE/HEALTH_CONDEMN 3/0.15 · SERVICE_MTTR 1.0–2.0h · FAIL_MTTR 2.0–5.0h.`

---

## 25. Prioritized Development Plan

Solo dev. Each milestone ends in a runnable, testable build. **Prove the simulation with debug UI before art.** Note: the channel/bus minute-tick model is the real cost driver — estimates below reflect that, not a single-scalar prototype.

- **M0 — Skeleton (½ day):** URP portrait template, Boot/MainMenu/Factory scenes, `Services` locator, `Bootstrap`, scene loading. Gray Factory scene runs on-device.
- **M1 — Minute-tick clock + Economy (1.5 days):** `TimeManager` with the **480-tick/day sub-day loop** + absolute global tick + pause/1×/2×/4×; `EconomyManager` ledger (contract cap, floor, strikes, salvage, penalty). Debug text: day, tick, cash. *Proves the heartbeat the whole balance depends on.*
- **M2 — Data-driven machines + per-channel wear (3 days):** `MachineDefinition` + `WearChannelDef` (18 assets) + `MachineState` with the effParam chokepoint and **3 wear channels each**; author 6 SOs + `LevelDefinition` with per-channel pre-seed. Wear integrates per tick. Debug overlay: per-channel wear + effRate. *Proves pillar 1.* **Run on a real Android device by end of M2.**
- **M3 — Production line / min-of-chain (1.5 days):** `ProductionLine` min-of-chain + duty back-prop → revenue. Overlay highlights the bottleneck; degrade a channel → watch the limiter move. *Proves pillar 5 + the load→wear coupling.*
- **M4 — Air bus + cascades (3 days):** `UtilityBus` (continuous P_air/moisture, airDraw = Σ draw·r), continuous `airFactor`, `S = 1+1.5·moisture` accelerating downstream seal wear; `DependencyGraph` (conveyor jam starves oven). Kill the compressor → three consumers degrade/misfire, seize on prolonged neglect. *Proves pillar 3 and the cascade — the engine of the game.*
- **M5 — Technician + maintenance verbs (3 days):** `Technician` (queue, tech-minutes, travel from the 7×7 matrix), `MaintenanceSystem`, all five verbs with real effects; Inspect→per-channel noisy reveal + P-F band (predictive), Repair→0.08 floor (preventive), Ignore→hazard→emergency (RTF); per-part-type stock with emergency premium/delivery. *Proves pillars 2, 4, 6 and the mixed-policy triangle.*
- **M6 — Real UI (2.5 days):** `UIController` — ResourceBar, DayClock, tap-select + ActionSheet (fast-path Inspect + stage→confirm), TechStatus strip, QualityReadout, "?" chips. Touch-tuned.
- **M7 — Win/Loss + Save/Load (1.5 days):** win (cash≥$20k Day 10), L1–L4, WinLossPanel; single-slot JSON save including **seed + absolute tick + per-channel wear** (deterministic resume).
- **M8a — Tutorial framework (2–3 days):** spotlight/dim/step-gating across Days 1–4 (§17) — touches every panel; this is real scope, budgeted here, not a "couple of tooltips."
- **M8b — Balance + art/juice (3–4 days):** tune against the reference seed **and a seed spread** until the acceptance bands (§10) hold and the +15–20% PdM cushion is validated. Art is **off the critical path**: kitbash/asset-store meshes (or ship debug-cube visuals for the prototype); VFX cut to the minimum that distinguishes running/worn/down/**starved** + scrap pile (color + one particle + health ring). Iso camera polish, 3–4 SFX, floating-text juice.

**Critical path:** M1→M2→M3→M4→M5 is the simulation core and must be nailed with debug UI first. If time runs short, cut art (M8b) and the tutorial (M8a) before cutting any of M2–M5 — the pillars are the product. **Guardrails:** everything tuneable lives in SOs (balance in the Inspector, never a recompile); one tick source; object-pool badges/VFX/text from M4; systems event-decoupled; UI never reaches into runtime state except through a system.