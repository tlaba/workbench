# Blackweir Municipal Waterworks — Premium Plant Pack

*Design doc for Retrofit Factory 3D's waterworks pack. Reuses the shared sim engine
(`g10_waterworks.js` is a pure plant module). The free bakery and the other packs stay
byte-identical. See [GDD.md](./GDD.md), [GDD-IRONLINE.md](./GDD-IRONLINE.md) and
[GDD-EMBERLINE.md](./GDD-EMBERLINE.md).*

**Pitch:** every other plant lets you stop. Blackweir doesn't. Raw water arrives whether
or not you're ready, and the town's permit never sleeps. The bakery's moisture throttles
throughput and the brewery's hygiene sets price; here the buffer is a **bomb**, the price
is **flat**, and money dies only in **fines** and the power bill — exactly how real
utilities die.

## 1 · Shape

- 12 machines, 6 weeks × 5 days, day = 480 ticks. Start $15,000 / win **$26,000**.
- Flat **$4.20/kGal**, sold up to **1.5× the daily contract** (the town's reservoirs
  absorb surplus; beyond the cap, no credit) — so pre-draining the basin and treating a
  storm surge are *paid* work, and a clean plant turns a storm into its best revenue day.
- Demand 480 → 1,250 kGal/day against a ~1,260/day healthy filter bottleneck.
- Three utility buses: **power** (substation), **air** (blower — this is the bus that
  *cleans*: backwash + clarifier airlift, so neglecting it accelerates someone else's
  fouling), **chem** (dosing skid).
- Flow: raw **basin** → treatment train → treated **clearwell** → high-lift → town. The
  clearwell buffers the town through a short treatment stop; the basin is the tension.

## 2 · Signature mechanic — the river does not stop

`inflow = (demand/480) · diurnal(tick) · stormMult` arrives every tick regardless of
plant state (diurnal curve: 0.55 overnight trough → 1.45 evening peak). The
**equalization basin** (cap 900 kGal, opens at 50%) is a **bomb you keep half-empty**:
overflow the bypass weir and you pay **$6/kGal** spilled + a permit strike at 60 kGal.
Three **storm days** per season are seeded from the run PRNG and **forecast the evening
before** — inflow surges to **2.1×** and storm turbidity ages the FOUL-heavy
front-of-train (screens, clarifier, filters) 2–4× faster. So maintenance is
**calendar-strategic** — service *before* the storm, pre-drain overnight (the drained
water sells) — not just condition-strategic. Starve the basin instead and the pumps
**short-cycle**, eating their windings (THERM). Hold the band ~15–85%.

## 3 · Signature mechanic — consent to operate

Five calibration channels (dosing, turbidity, UV intensity, chlorine residual, batch)
carry `compliance:true`. While water ships, `violMin += min(1, Σ max(0, w − 0.25)·2.2)`
— a freshly calibrated plant has margin; drifted channels stack. It is **silent**: not in
the HUD, no downtime, no scrap. A $180 sensor reveals a part's drift; a **$60 lab sample**
reveals today's running total once. Fines are **$9/violation-minute** (cap $1,300/day) with
a **Notice of Violation strike at 90**. Price never moves — compliance failure only takes
money and strikes, and the water always ships.

## 4 · New wear type + resilience

**THERM**: a starved basin short-cycles the low-lift/high-lift pumps (one stop→start per
12 ticks eats the windings); the UV ballast cycles when the lamps stop — operating
decisions, not just maintenance, age the iron. To keep a 9-machine serial train winnable,
two softeners: the **clearwell** (treated buffer, ~9h at week-4 demand) ships through a
short treatment breakdown, and a broken **utility limps on standby** (`BUS_FLOOR 0.40`)
rather than a total stop, so one failure doesn't instantly overflow the basin.

## 5 · Verified balance (10-seed matrix)

| policy | wins | finishes | median cash | worst case |
|---|---|---|---|---|
| predictive + sensors-on-the-5-CALs + forecast-timed pre-storm servicing | **6/10** | 8/10 | $28,399 | −$3,053 |
| blind calendar | 0/10 | 0/10 — dead ~day 14 | $12,196 | — |
| inspect-only / run-to-failure | 0/10 | 0/10 — dead ~day 8–13 | ~$20k | — |

The neglect strategies bank cash right up until a breakdown day overflows the basin into a
spill fine + strike cascade, or a silent Notice of Violation lands — you can't see it kill
you, which is the lesson. Predictive wins by sensoring the five compliance channels first,
lab-sampling in heavy weeks, and servicing the front-of-train the night before each
forecast storm.

## 6 · Deliberately not built (yet)

Lifelike waterworks geometry + hall dressing (generic tanks/boxes + coloured bus pipes for
now); an animated bypass-weir overflow; pack-specific grades.

## 7 · Regression contract

Bakery + other packs byte-identical (`__sim(null,1234567,'bakery')` → 9768 / 8 / 3;
brewery seed 77 → 29043; foundry + brewery matrices unchanged). Waterworks state
(basin, clearwell, storm schedule, violation minutes) serializes and round-trips
deterministically. All behaviour is gated by plant id, channel type (`THERM`/`DCAL`), or
constants the other plants don't define.
