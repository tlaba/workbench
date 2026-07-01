# Industrial Troubleshooting Sim — Engine Spec & Worked Machine

**The technical heart of the game.** This document specifies the simulation
engine that makes *emergent* faults possible, then works one machine — a
150‑ton hydraulic press — end‑to‑end across all five layers (mechanical,
hydraulic, electrical, PLC, sensors/HMI) so you can see exactly how a single
root cause propagates into an alarm code three layers away.

A live, clickable prototype that implements a reduced version of this engine
ships alongside as [`hydraulic-press-troubleshooter.html`](./hydraulic-press-troubleshooter.html).

---

## 0. The one rule everything serves

> **A fault is data, not code.** Nowhere in the engine is there a branch that
> says `if (filterClogged) alarm("EXTEND_TIMEOUT")`. A clog is *one number* —
> `filter.R × 50`. The slow cylinder, the late limit switch, and the PLC's
> extend‑timeout fault code all **fall out** of ordinary physics plus an
> independently‑scanning PLC.

If any code path has to *know* that a clog causes a timeout, the design has
failed. This is what separates a real troubleshooting simulator from a quiz
with 200 memorizable answers. It also means content authoring scales: you build
physics once, and every fault you can express as a parameter override becomes a
diagnosable scenario for free — and faults **compose** (clog + weak pump =
additively worse) with zero combinatorial code.

---

## 1. Architecture at a glance

Three lumped‑parameter physical domains plus an independent controller, coupled
through four narrow, explicit seams:

```
        ┌───────────── PLANT (physics, 1 kHz) ─────────────┐
        │                                                  │
        │   ELECTRICAL  ──①──►  HYDRAULIC  ──②──►  MECHANICAL
        │   (algebraic,          (implicit,          (semi‑implicit
        │    MNA resistive)       backward‑Euler)      Euler + end‑stops)
        │        ▲                     ▲  ③ velocity closes the loop  │
        │        │                     └────────────◄────────────────┘
        │        │ ④ output image                                    │
        │        │                          ⑤ sensor sample          │
        └────────┼──────────────────────────────┼───────────────────┘
                 │      I/O IMAGE (copies)       │
        ┌────────┴──────────────────────────────▼───────────────────┐
        │              PLC  (separate scanner, 10 ms)                │
        │        read inputs → run ladder/timers → write outputs     │
        └────────────────────────────────────────────────────────────┘
```

**Why domain‑split instead of one global solver?** The hard problem is the
pressure feedback loop against a relief valve and hard end‑stops — it is
*stiff*. Backward‑Euler on the hydraulic node (with lumped fluid capacitance
`C = V/β`) is **A‑stable**: it physically cannot blow up regardless of `dt`.
Electrical at game timescale has no storage dynamics, so it solves as a cheap
algebraic resistive network (Modified Nodal Analysis). Mechanical is a handful
of rigid bodies — explicit semi‑implicit Euler with unilateral end‑stops.
Using the cheapest *stable* method per stiffness class beats one monolithic
relaxation tuned to survive its stiffest element.

**Why a separate PLC scanner?** Modeling the scan as its own asynchronous clock
with frozen I/O images is what produces realistic scan‑lag, watchdog, and
aliasing fault classes cleanly. The PLC never reads mid‑solve physics state; it
sees a *copied* input image, exactly like real I/O‑image semantics.

### Recommended rates
| Loop | Rate | Why |
|---|---|---|
| Physics `dt` | 1 ms (1 kHz) | clean backward‑Euler transients; negligible operator‑split lag |
| PLC scan | 10 ms (5–20 ms configurable) | realistically slower than physics → genuine scan‑lag faults |
| Render | display (~60 Hz) | interpolated only, never fed back into the math |

Determinism is first‑class: fixed `dt`, fixed iteration counts, stable
component ordering, seeded PRNG only, no wall‑clock in the math. Same initial
state + same fault/operator inputs → reproducible trace (essential for replay,
grading, and shared puzzles).

---

## 2. Data model

Authoring view = an explicit **port/edge graph** (inspectable, and it *is* the
level editor). At load, that graph is compiled into flat typed‑array solver
structures per domain for the hot loop.

```ts
interface Node {            // one per domain sub‑network
  id: number;
  domain: 'hyd' | 'elec' | 'mech';
  potential: number;        // hyd: pressure[Pa]; elec: voltage[V]
  capacitance: number;      // hyd: V/β (gives pressure real dynamics); elec: 0
}

interface Component {       // an edge/element between ports
  id: string; type: string;
  params: Record<string, number>;   // nominal physical constants
  state:  Record<string, number>;   // integrator memory (pos, spoolPos, temp…)
  faults: Record<string, FaultSpec>;// overlay; default = identity
  ports:  Record<string, number>;   // named ports → node ids
  effParam(name): number;           // THE single fault chokepoint
  stampHyd?(sys) | stampElec?(sys); // contribute to its domain's linear system
  update(dt, boundary): void;       // advance own state from resolved ports
  sample?(inputImage): void;        // sensors only
}
```

### The fault chokepoint

Every component reads its parameters **only** through `effParam()`. That is the
entire fault machinery — there are no fault handlers anywhere else:

```ts
effParam(name) {
  let v = this.params[name];
  const f = this.activeFault(name);        // resolves optional schedule predicate
  if (!f) return v;
  switch (f.mode) {
    case 'scale':  return v * f.value;      // clogged filter: filter.R ×50
    case 'offset': return v + f.value;      // transducer drift: pt110.offset +20bar
    case 'clamp':  return Math.min(Math.max(v, f.min), f.max);
    case 'stuck':  return f.value;          // welded contact, frozen spool, stuck bit
  }
}
```

A `FaultSpec` may carry a **schedule predicate** so intermittents and gradual
degradation are *also* pure data:

```ts
type FaultSpec =
  | { mode, value }                                  // constant
  | { mode, value, schedule: (tick, state) => bool } // "fails when warm", vibration dropout
  | { mode, rampFrom, rampTo, overTicks };           // gradual wear
```

### Canonical fault library (all identity by default)
| Fault | Override | Emergent signature |
|---|---|---|
| Clogged filter | `filter.R ×50` | high ΔP, low downstream flow, pump pinned at relief |
| Worn pump | `pump.volEff ×0.6` | pressure **sags under load**, fine at no‑load (load‑dependent tell) |
| Internal cyl leak | `cyl.gLeak +v` | won't build/hold pressure in motion; dead‑heads fine |
| Mis‑set relief | `relief.crack ±v` | wrong system ceiling |
| Sticky spool | `valve.spoolFriction ×10` | slow/incomplete shift, ignores coil |
| Open coil / welded contact | `contact.R stuck 1e9 / 1e‑6` | valve never / always energizes |
| Sensor lies | `sensor.offset/gain/stuck` | PLC sees a false world |

---

## 3. The tick loop — ordering *is* the ballgame

```ts
function stepPhysics(dt) {
  applyScheduledFaults(tick);   // 1. faults for this tick (pure fn of tick count)
  elec.solve();                 // 2. MNA → coil currents → energized flags, spool targets
  hyd.solve(dt);                // 3. backward‑Euler pressure/flow (Picard 2–4×; only real loops iterate)
  mech.integrate(dt);           // 4. F = P_cap·A_cap − P_rod·A_rod − load − friction; end‑stops
  sampleSensors(io.in);         // 5. physical state → PLC INPUT IMAGE (through effParam)
  if (plcTimer.fire(dt)) plc.scan(io.in, io.out);  // 6. independent scan → OUTPUT IMAGE
  nanGuard();                   // 7. fail safe in‑game, never propagate garbage
  tick++;
}
```

State is integrated **once** per step (steps 4 & 6), never inside the hydraulic
Picard iterations — so re‑linearization stays idempotent (the single most
likely correctness bug is a stamp that mutates state mid‑iteration; the contract
forbids it).

**The emergent chain, arrow by arrow — no special‑case code touches it:**

```
filter.faults.R = ×50
   → step 3 solves lower cap‑side pressure / limited flow
   → step 4 smaller net force → smaller velocity → position advances slowly
   → step 5 extend limit switch stays 0 longer
   → step 6 PLC TON reaches preset before the switch makes
   → ladder latches F‑EXTEND‑TIMEOUT
```

Every arrow is ordinary physics or an ordinary timer. The PLC has no concept of
"filter."

---

## 4. The worked machine — 150‑ton hydraulic press across five layers

A 30 kW motor drives a fixed‑displacement pump pulling ISO VG46 oil through a
suction strainer, a 10 µm pressure filter, past a 210 bar relief and a bladder
accumulator, into a 4/3 solenoid directional valve. Port A drives the cylinder
cap side (extend/press) through a pilot‑operated check valve; port B drives the
rod side (retract). Control is 24 VDC; a dual‑channel E‑stop chain drops the
motor contactor and both solenoids. Feedback: a 4‑20 mA cap‑line pressure
transducer and top/bottom proximity switches. The PLC sequences the cycle from
an HMI cycle button.

### Component map by layer

| Layer | Components |
|---|---|
| **Electrical** | `SUPPLY_480` → `MAIN_DISCONNECT` → `MOTOR_CONTACTOR (K1)` → `OVERLOAD` → `MOTOR`; `CONTROL_PSU (24V)`; `ESTOP_CHAIN` |
| **Hydraulic** | `RESERVOIR` → `STRAINER` → `PUMP` → `FILTER (FLT‑201)` → {`RELIEF (RV‑501)`, `ACCUM`} → `DCV (DV‑301)` → {`CHECK`→cap, `FLOW_CTRL`→rod} → `CYLINDER (CYL‑401)` |
| **Mechanical** | `MOTOR` shaft → `PUMP`; `CYLINDER` piston → `RAM/PLATEN` on 4 guide pillars → workpiece/die |
| **Sensor** | `PT‑110` (4‑20 mA cap line), `LS‑TOP` (home), `LS‑402` (bottom/extend‑complete) |
| **PLC / HMI** | DI: bottom, top, E‑stop OK, O/L OK, AI: pressure. DO: motor‑run, SOL‑A, SOL‑B, alarm. HMI: cycle/reset, pressure display, alarm banner |

Each component exposes typed ports and explicit connections (see the full
graph in the prototype's `TP` table and SVG `data-tp` anchors, which double as
the multimeter / pressure‑gauge test points).

### Normal cycle (nominal numbers)

| Phase | What happens | Cap pressure | PT‑110 | Position |
|---|---|---|---|---|
| **IDLE** | motor on, DCV centered (P→T) | ~15 bar standby | ~5.3 mA | home, LS‑TOP=1 |
| **EXTEND** | SOL‑A on, ram fast‑approaches | 30–60 bar | ~6–8 mA | 0 → 250 mm, ~3 s |
| **PRESS/DWELL** | ram at work, pressure ramps to setpoint, holds 1 s | → **200 bar** (≈354 kN) | ~15.5 mA | 250 mm, LS‑402=1 |
| **RETRACT** | SOL‑B on, check valve vents cap | decays to ~0 | ~4 mA | 250 → 0 mm |
| **HOME** | LS‑TOP=1 → DCV centers, cycle complete | ~0 | ~4 mA | home |

---

## 5. Fault scenarios — the same physics, four root layers

Each is one data override; each symptom below **emerges**.

### ① Intro — clogged pressure filter (HYDRAULIC)
`filter.R ×2000`. To push pump flow through the restriction the pump pins at
the 210 bar relief and *spills*, so delivered flow collapses (≈8 L/min vs 30).
Ram crawls (~24 mm/s vs 83), never reaches LS‑402 within the 6 s extend
watchdog → **ALM‑1102 EXTEND TIMEOUT**.
- **Red herring:** the extend solenoid *is* energized → blame the valve or pad the timer. Both are wrong.
- **Diagnose:** pressure gauge on **PG‑101** (pinned at 210) vs **PG‑102** (sagging) → ΔP ≈ 9 bar across FLT‑201. Filter clog indicator popped.
- **Fix:** replace element, reset indicator, leave the timer at 6.0 s.

### ② Moderate — transducer drift (SENSOR)
`pt110.offset +20 bar`. The PLC pressure‑holds on the transducer, so when it
*reads* 200 bar the *true* pressure is only 180 → parts under‑formed (~318 kN
vs 354). **No machine alarm** — only a soft `ALM‑3400` advisory and downstream
quality rejects.
- **Red herring:** weak parts → suspect a force deficit → bump the relief valve. That corrupts the whole force calibration; the sensor is lying.
- **Diagnose:** vent the line to true zero — reference gauge reads 0, HMI/PT‑110 reads ~20 (the tell‑tale zero offset).
- **Fix:** recalibrate/replace PT‑110, quarantine parts made since drift onset.

### ③ Hard — intermittent LS‑402 wiring (ELECTRICAL)
`ls402.wiring` intermittent, position‑gated. On ~half of cycles the fatigued
conductor makes on arrival (PLC enters PRESS) then *opens* under end‑of‑travel
shock → **ALM‑2205 RETRACT PERMIT LOST**; the other cycles are perfect, which
is what makes it maddening.
- **Red herring:** "won't retract" → swap the retract solenoid or PLC output; the intermittent "fixes itself" by luck. Others replace the switch *body* — but the fault is in the field wiring.
- **Diagnose:** trend **I0.4** while running *full‑stroke* (never on the bench) — it drops to 0 while the encoder confirms the platen is down. Multimeter wiggle‑test at the flex loop reproduces the open.
- **Fix:** replace with continuous‑flex cable, proper strain relief, re‑terminate.

### ④ Nasty — internal cylinder seal bypass (MECHANICAL, mimics HYDRAULIC)
`cyl.gLeak` up. Fluid short‑circuits cap→rod across the piston, so pressure
sags under motion and can't reach setpoint → **ALM‑3300 TARGET PRESSURE NOT
REACHED**. It *looks exactly like a worn pump*.
- **Red herring:** "can't make pressure" → condemn the pump or relief.
- **The discriminator (built into the prototype):** the **dead‑head pump test** blocks the actuator and commands the pump against the relief — pressure builds to a full 210 bar and holds → pump and relief are *fine*, so the loss is *across the piston*.
- **Fix:** reseal the cylinder.

These four are the authored vertical slice; §6 adds four more (worn pump, air‑in‑oil,
sticky spool, open coil) that emerge from the same solvers with no new code. A
realistic full fault taxonomy (open/short/ground, drift/calibration,
contamination, wear, binding, air‑in‑oil, PLC timing, EMI, intermittents)
organized by *root* layer vs *symptom* layer is included in the design corpus.

---

## 6. What the prototype implements

The shipped HTML now runs the **real lumped‑parameter solvers** from this spec —
not a reduced stand‑in — behind the workstation UI, at 200 Hz physics / 10 Hz PLC:

| Aspect | Prototype |
|---|---|
| Faults are data via `effParam` | ✅ one override per fault, no handlers anywhere |
| Physics tick + **independent** PLC scan | ✅ 200 Hz physics, 10 Hz PLC with frozen I/O images |
| Emergent symptoms (no scripted alarms) | ✅ 8 fault types verified headless |
| **Hydraulic** | ✅ backward‑Euler R‑C network (4 nodes), Picard‑linearized relief (conductance to a node fixed *at* cracking pressure) + check/DCV; unconditionally stable |
| **Electrical** | ✅ nodal analysis of the 24 VDC control circuit → real test‑point voltages; energization from **coil current** (so an open coil reads voltage‑present / no‑pull‑in) |
| **Mechanical** | ✅ 1‑DOF rigid‑body integrator, variable cap/rod chamber volumes, unilateral end‑stops, viscous+coulomb friction |
| Determinism | ✅ fixed dt, stable node ordering, seeded PRNG for intermittents |
| Full‑engine roadmap | 1 kHz + SCC decomposition, 3‑phase electrical, fixed‑point option for cross‑machine bit‑exact replay |

Because the solvers are real, **new fault classes emerge with no new code** — each
is one `effParam` override:

| Fault | Override | Emergent signature | Discriminator |
|---|---|---|---|
| ⑤ Worn pump | `pump.slip ↑` | pressure sags **under load**, `ALM‑3300` | dead‑head only reaches ~191 bar (pump can't make pressure) |
| ⑥ Air in oil | `cyl.beta ↓` | spongy, **slow** pressure build → `ALM‑3300` | pressure eventually climbs given time; rate is the tell |
| ⑦ Sticky spool | `valve.gMain ↓` | slow extend → `ALM‑1102` | filter ΔP **normal** (drop is across the valve, not FLT‑201) |
| ⑧ Open SOL‑A coil | `coilA.R → ∞` | ram won't extend → `ALM‑1102` | multimeter: 24 V **commanded** at coil but no pull‑in |

**Verification (headless Playwright, all pass with zero console errors):**
```
HEALTHY     → IDLE, good part (press peak 210 bar)
CLOG        → ALM‑1102 (crawls, PG‑101 pinned 210, high filter ΔP)
DRIFT       → completes, part WEAK (no machine alarm; PT‑110 offset)
CYL LEAK    → ALM‑3300 ; dead‑head = 214 bar  → pump exonerated
WORN PUMP   → ALM‑3300 ; dead‑head = 191 bar  → pump condemned  (vs cyl‑leak!)
STICKY SPOOL→ ALM‑1102 (slow extend, filter ΔP normal)
OPEN COIL   → ALM‑1102 (ram won't move; coil voltage present, no current)
AIR IN OIL  → ALM‑3300 (slow spongy build)
LS WIRE     → 8 cycles → 4× ALM‑2205 no‑retract, 4× clean (intermittent)
```

---

## 7. Build order for the real thing

1. **Engine core** — `Component`/`Node`/`effParam`, the three domain solvers, the PLC scanner, the fixed‑step loop. Ship the debug overlay (colour edges by flow, per‑port potentials, single‑step ticks *and* rungs, trace a symptom back to its root fault) — it *is* the level editor.
2. **Component library** — the ~20 press components as registered classes; adding a component = register one class, nothing central changes.
3. **Scenario format** — serializable JSON (`nodes, components, connections, plcProgram, faultScenarios, seed, dt, scanPeriod`) → save / replay / share / auto‑grade.
4. **Workstation UI** — the five layer schematics, instruments, alarm log, hypothesis tracker, repair/verify loop (the shipped prototype is the reference).
5. **Career wrapper** — ✅ *shipped in the prototype:* a shift of work orders with hidden seeded faults, a parts budget, downtime cost ($/s), verify-to-close, and end-of-shift scoring (first-fix rate, MTTR, total cost, grade). Next: procedural seeding, machine progression (conveyor → press → robotic cell → line), and simultaneous faults.

### Known limits (document, don't hide)
Softened bulk modulus and linearized orifices make transients *qualitatively*
right, not lab‑accurate — this is a training game, not an engineering‑grade
simulator. Cross‑browser float results aren't bit‑identical (store input logs +
checksums for shared replays). Threshold elements (relief crack, pressure
switches, end‑stops) need hysteresis/deadbands to avoid chatter.
