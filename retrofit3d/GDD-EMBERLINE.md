# Emberline Diecast & Alloy Works — Premium Plant Pack

*Design doc for Retrofit Factory 3D's foundry pack. Reuses the shared sim engine
(`g9_foundry.js` is a pure plant module — data + hooks, no engine forks). The free
bakery and the other packs stay byte-identical. See [GDD.md](./GDD.md) for the core
game and [GDD-IRONLINE.md](./GDD-IRONLINE.md) for the brewery.*

**Pitch:** the brewery made *quality* your price lever. The foundry removes the price
lever entirely — castings sell for a flat **$9** — and puts the whole game on the
**cost** side of the ledger. Your product is a **thermodynamic inventory**: molten
metal you already paid to melt, held hot at a carrying cost, that a careless stop can
freeze solid or a quality slip can force you to melt *twice*.

## 1 · Shape

- 12 machines, 6 weeks × 5 days, day = 480 ticks. Start $17,000 / win **$42,000**.
- Flat price **$9.00/casting**; demand 380 → 1,050/day against a ~1,250/day healthy
  ceiling (after baseline defects + the morning heat ramp), so weeks 5–6 need an
  upgraded cell or CNC.
- Three utility buses: **gas** (boiler skid → melt furnace, holding furnace, heat-treat
  oven), **hydraulic** (HPU → both diecast cells, trim press), **water** (cooling tower
  → dies, quench, CNC chiller).

## 2 · Signature mechanic — the Heat Bank

Molten metal is banked inventory: `S.px.melt` (cap 900 casting-equivalents) with a
superheat `S.px.heat` (0–1). The burners hold the bank hot whenever gas flows and the
melt furnace is up — **heat is decoupled from melting**, so a full hot bank still pours
and drains (an early build deadlocked here: a full bank auto-idled the furnace, heat
craved, and it froze permanently). Cells pour only while superheat ≥ **35%**; below
**15%** the bank **freezes** — pour locks until it recovers to 50%, gas draw doubles,
and both furnace linings take a THERM hit ($500 remelt fee).

A fouled **gas skid** does double damage: it cools the bank *and* multiplies the cost of
every pound melted — `energy = MELT_KWH × price × (2 − gasF)` — so a dirty regenerator
melts the same metal for more dollars while the line looks fine. Each night the player
chooses **HOLD-HOT** ($140, tomorrow opens hot with the bank intact) or **GO COLD** (the
heel freezes into sows that re-melt next morning at 1.6× energy, with dead pour minutes).
From week 3 the ledger teaches which is cheaper.

## 3 · Signature mechanic — the Rework Spiral

Defect fraction `d = clamp(0.03 + 0.45·mean(six calibration channels) + 0.20·mean(die
heat-check), 0, 0.55)`. The X-ray gate catches `c = 1 − 0.85·detector-cal-wear`. Of gross
production, caught defects (`P·d·c`) **re-melt** — 85% of the metal returns to the bank,
but it must be melted *again* (gas + pour capacity), so quality failures eat **capacity**,
never price. Escapes (`P·d·(1−c)`) ship: $4/unit warranty above 2% of the day, and a
$600 recall **+ contract strike** at 5%. The gate's own detector cal is the one silent
failure that un-hides every other silent failure — protect it first.

## 4 · New wear type — THERM (downtime is wear)

Refractory linings, die blocks and the oven muffle take a wear hit on **every
running↔stopped transition** — including the uncommanded auto-idle when a full bank
starves the melt furnace. Engine-generic (gated by `C.THERM_CYCLE`; zero effect on plants
that don't set it). The lesson: batch hot-side repairs into the cold morning ramp; nurse
a sick die to the free overnight cycle instead of panic-stopping it hot.

## 5 · Verified balance (10-seed matrix)

| policy | wins | finishes | median cash | worst case |
|---|---|---|---|---|
| predictive + auto + crew + sensors | **6/10** | 7/10 | $69,432 | $5,494 |
| blind calendar | 0/10 | 0/10 — dead ~day 10 | $8,282 | — |
| inspect-only / run-to-failure | 0/10 | 0/10 — dead ~day 8 | ~$13–15k | — |

The challenge is **reliability**: keep the gas skid + caster pair healthy so the bank
keeps moving, sensor the six silent calibration channels, and read the Energy / Re-melt /
Hold-hot / Warranty settle lines the way a brewery reads quality. A surviving foundry is
very profitable (flat high margin) — the game is not going broke, it's not freezing.

## 6 · Deliberately not built (yet)

Lifelike foundry geometry + hall dressing (ships with generic vessels/boxes + coloured
bus pipes for now, as the brewery did before its 3D pass); cascade events between coupled
utilities; pack-specific grades.

## 7 · Regression contract

The free bakery and the other packs stay byte-identical: `__sim(null,1234567,'bakery')` →
9768 / 8 / 3; brewery `predictive` seed 77 → 29043; save round-trips (incl. the heat bank
and the THERM run-tracker). All foundry behaviour is gated by plant id, channel type
(`THERM`/`DCAL`), or constants the other plants don't define.
