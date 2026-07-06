# Ironline Brewery & Bottling Works — Premium Plant Pack

*Design document for Retrofit Factory 3D's first paid add-on plant. The free
Old Bakery Plant is documented in [GDD.md](./GDD.md); this pack reuses that
sim engine unchanged and adds content + mechanics on top. A fault is still
data, not code.*

**Pitch:** the bakery taught you predictive maintenance. Ironline asks you to
run it at industrial scale — twelve machines, three utility networks, a crew,
and a brewer's discipline the bakery never needed: **hygiene**. Skip a wash
cycle and nothing breaks — your beer just quietly gets worse, until the day a
batch goes down the drain.

---

## 1 · Shape of the season

| | Free bakery | Ironline (premium) |
|---|---|---|
| Machines | 6 | **12** |
| Season | 4 weeks × 5 days | **6 weeks × 5 days** |
| Day length | 480 min | 480 min |
| Start / win cash | $8,000 / $30,000 | **$16,000 / $25,000** |
| Contract price | $3.60/loaf | **$5.50/case × quality** |
| Utility buses | 1 (air) | **3 (steam · glycol · air)** |
| Failure types | DRAG · SEIZE · DRIFT · LEAK · MOIST | + **FOUL** (fouling/scale) + **CAL** (calibration drift) |
| Crew | you | you + **hireable apprentice** |
| Instruments | inspection, automation | + **per-part condition sensors** |
| Quality axis | scrap only (oven thermocouple) | **hygiene → quality → price** + CAL scrap |
| Weekly demand | 620 → 1,200 | **450 → 1,200** (wk 6 out-runs a base line) |

The escalation logic is the bakery's: same plant all season, wear carries
forward, quotas climb past base capacity so the finale demands an upgraded,
healthy line. Ironline stretches it across more days and more simultaneous
failure surfaces than one pair of hands can cover — which is the point: the
mid-game decision is *buying back attention* (apprentice, sensors, automation).

## 2 · The plant

Utilities (produce a bus; don't make product) and a nine-stage line:

```
BLR-100 Steam Boiler ──steam──▶ Brewhouse · Pasteurizer
GLY-200 Glycol Chiller ─glycol─▶ Fermenter A/B · Bright Tank
AIR-300 Air Compressor ──air──▶ Filler · Labeler · Case Packer

MIL-350 Mill → BRH-400 Brewhouse → FRM-510/520 Fermenters → BRT-600 Bright
  → FIL-700 Filler/Capper → PAS-800 Pasteurizer → LBL-900 Labeler → CSE-950 Case Packer
```

Throughput = the slowest line machine (◄ LIMIT), each further scaled by the
product of its buses' health factors. A fouled boiler doesn't break anything —
it drags the brewhouse *and* the pasteurizer at once. One root cause, many
symptoms: the bakery's compressor lesson, cubed. The 3D hall colour-codes the
network (orange steam, blue glycol, cyan air pipe runs from each utility to
its consumers) so the coupling is legible without opening a panel.

Every machine carries 3 wear channels (36 total) using the shared channel
physics; each has an `insp` cost and generic MTTR fallbacks, so the whole
plant is data — `PLANTS.brewery` in `g8_brewery.js`.

## 3 · New failure physics

- **FOUL — fouling / scale.** DRAG-like rate loss and +60 % energy at full
  wear, but with an accelerant: wear rate ×(1 + `FOUL_ACCEL`·w). Clean early
  and it's cheap; ignore it and it *runs away*. Teaches: some maintenance is
  time-critical, not just cost-optimal.
- **CAL — calibration drift.** No rate loss, no breakdown risk — it silently
  scraps a fraction of output (`+0.3·w`, capped). Invisible in the HUD until
  you inspect (or fit a sensor). Teaches: watch the output, not just the
  machinery.

Both are implemented in the shared engine gated by channel type, so the
bakery (which uses neither) is byte-identical.

## 4 · Hygiene → contamination → quality → price (signature mechanic)

Six **product-contact vessels** (brewhouse, both fermenters, bright tank,
filler, pasteurizer) accrue **soil** while running (~0.14/day). Soil is always
visible — you know when you last cleaned — and does two things:

1. **Quality drag.** Day quality `q = 1 − 0.22·avgSoil − 0.30·(contaminated)`,
   time-weighted over the day's production. Quality multiplies the contract
   **price**: dirty plant → cheaper beer. Revenue, not volume — you still ship,
   you just earn less per case.
2. **Contamination roulette.** Each running vessel rolls
   `P = 0.0008 · soil³` per minute. The cube keeps a reasonably clean vessel
   safe and a filthy one on borrowed time. A hit dumps ~200 cases of WIP,
   bills $320 sanitation, and pins the vessel at degraded quality until washed.

**CIP (clean-in-place)** is a planned crew job: $130 + ~50 min of downtime,
resets soil and clears contamination. The cadence that emerges (~every 3–4
days per vessel, staggered) is the brewer's rhythm the pack is named for.

Verified balance (10-seed policy matrix, `__matrix(seeds,'brewery')`):

| policy | wins | finishes | median cash | contaminations/season |
|---|---|---|---|---|
| predictive + automation + crew + **CIP** | **7/10** | 7/10 | $31,003 | 2 |
| blind calendar services, **no hygiene** | 0/10 | 5/10 | $8,154 | 6 |
| inspect-only | 0/10 | 0/10 | — | 5–6 |
| run-to-failure | 0/10 | 0/10 | — | 6 |

The designed reading: mechanical diligence alone keeps you *alive*; only
mechanical diligence **plus hygiene** wins. Skip hygiene = contamination
roulette.

## 5 · Crew & instruments (attention economy)

- **Apprentice** (`🧑‍🔧` on the tech chip): $1,800 fee + $170/day. Pulls
  planned jobs from the shared queue in parallel with you, ~1.4× slower,
  never handles an emergency alone. Turns the 12-machine plant from
  impossible-to-cover into a scheduling puzzle.
- **Condition sensors** (`📡` per channel in the panel, $180): the channel's
  true wear stays revealed permanently — targeted predictive maintenance
  without repeat inspection fees. Best on the FOUL/CAL channels whose whole
  danger is invisibility.
- **Automation** ($900 here vs $2,600 at the bakery — the plant is newer):
  wear −65 % and daily re-reveal, as in the base game.

## 6 · Economy tuning notes

Baked into `BREW_C` after sweep-driven balance passes (see PR history):
channel wear `k ×0.55`, initial wear `×0.45`, `WEAR_SCALE 0.35`,
`HAZARD_SCALE 0.18`, price $5.50 (raised from $4.50 to fund the hygiene cost
center), demand curve 450→1,200. Invariant we tune against: **the reliability
ordering must hold** — predictive strategies must beat calendar must beat
neglect on *finishes and worst-case*, and no-hygiene must not win.

## 7 · Distribution & entitlement

The pack ships inside the same single HTML file (it's data + one module,
`g8_brewery.js`). Access is gated by the entitlements system
(see [CLOUD-SAVES.md](./CLOUD-SAVES.md#premium-packs-entitlements)):

- No Supabase configured → the pack is **open as a preview** (today's public
  build).
- Supabase configured → the plant picker shows **🔒 Redeem key**; a
  `redeem_key()` RPC atomically claims a minted key and grants the
  entitlement; owned packs cache locally for offline play.
- `localStorage.rf3d_dev_unlock = "1"` bypasses for dev/self-hosting.

Per-plant saves (`rf3d_save_brewery`, cloud rows keyed `(user_id, plant)`)
keep bakery and brewery runs independent.

## 8 · Deliberately not built (yet)

- **Batch fermentation** — fermenters as discrete multi-day batches (with a
  buffer tank decoupling brewhouse from filler) instead of continuous flow.
  The largest remaining sim idea; adds a planning layer.
- Boil-over / glycol-freeze **cascade events** between coupled utilities.
- A **filler carousel / catwalk** detail pass on the 3D hall.
- Pack-specific **achievements/grades** beyond the shared end screen.

## 9 · Regression contract

Everything above must hold while the free bakery stays **byte-identical**:
`__sim(null,1234567,'bakery')` → cash 9768 / 8 days / 3 strikes;
`__sim(targeted-hybrid, 11)` → 32095 won; boot + save round-trip
deterministic. All brewery behaviour is gated by plant id, channel type, or
constants the bakery doesn't define (`HYGIENE`, `HIRE_FEE`, `SENSOR_COST`) —
never by forking engine code.
