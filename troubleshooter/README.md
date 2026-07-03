# Industrial Troubleshooting Sim — four machines, one workstation

A realistic, multi-discipline troubleshooting game where faults are **emergent,
not scripted**. Four machines share one diagnostic workstation — pick one from
the dropdown in the top bar:

| Machine | What it is | Difficulty | Fault library |
|---|---|---|---|
| **SORT-LINE 2** | belt conveyor sortation line (VFD, photo-eyes, divert gate, encoder) | ★ | slip, dirty photo-eye, VFD derate, seizing bearing, dead encoder |
| **PRESS-LINE 3** | 150-ton hydraulic press across 5 layers | ★★ | the original 8 (filter, drift, wiring, seals, pump, air, spool, coil) |
| **PICK-CELL 4** | 2-axis gantry robot with vacuum gripper | ★★★ | worn cup (drops parts), failing servo, worn pump, curtain intermittent, Z-encoder drift |
| **MOLD-LINE 5** | hydraulic injection molder (heater zones, screw + check ring, mold cooling) | ★★★★ | dead heater band, lying thermocouple (burned parts), worn check ring (short shots), blocked cooling (creeping eject-stick), tired clamp (flash), hopper bridging |

Each machine has its own physics, PLC program, instruments (tachometer on the
conveyor, vacuum gauge on the robot), discriminator test (chalk-mark / dead-head
/ blank-off), career fault library, and per-machine personal best.

**▶ Play it live (no install):**
https://tlaba.github.io/workbench/ (auto-deploys from `main` via GitHub Pages)

## The game loop
- **🎓 Tutorial** — a guided first ticket teaches the diagnose→repair→verify loop.
- **Progression** — career shifts unlock in order: SORT-LINE 2 (★) → grade C
  unlocks PRESS-LINE 3 (★★) → PICK-CELL 4 (★★★) → MOLD-LINE 5 (★★★★). Free-play
  and the instructor sandbox are always open on every machine.
- **📞 Paid hints** — call OEM support mid-ticket: $150 names the layer the root
  cause lives in, $400 points at the subsystem. Comes out of your budget.
- **🏁 Challenge links** — the shift summary gives a copyable link with the exact
  seed; a rival plays the identical shift (same tickets, same severities).
- **Resume** — an interrupted shift is saved locally and offered on return.
- **🔊 Sound** — diagnostic audio: VFD whine tracks Hz, a failing bearing squeals,
  a pinned relief valve screams, a leaking vacuum cup hisses.
- **🏭 Plant Mode (endgame)** — unlock all four machines, then run the whole
  floor simultaneously: faults (some **degrading in real time**) land on any
  machine, work orders queue, and you're scored on **fleet uptime**.
- **👁 Visual diagnosis** — probe auto-zoom cinematics, a real thermal-camera
  heat-glow overlay, vibrating bearings, dripping seals, sparking wiring, and
  a red alarm strobe on faulted machines.
- **Technician rank** — lifetime fixed-ticket count ranks you Apprentice →
  Technician → Journeyman → Master Tech → Plant Wizard.

| File | What it is |
|---|---|
| [`hydraulic-press-troubleshooter.html`](./hydraulic-press-troubleshooter.html) | **Live, clickable diagnostic workstation.** Open in any browser — no build, no deps. Runs the **real lumped-parameter solvers** (backward-Euler R-C hydraulics, nodal-analysis electrical, rigid-body ram) + an independent PLC scan for a 150-ton hydraulic press across 5 layers. **8 emergent fault types.** |
| [`SIMULATION_ENGINE.md`](./SIMULATION_ENGINE.md) | The engine spec (component/signal-propagation model, tick+scan loop, fault chokepoint) and the press worked end-to-end across all five layers with the fault scenarios. |

## Try it in 30 seconds
1. Open the HTML file in a browser.
2. Top bar → **⚙ INSTRUCTOR → ① Clog pressure filter**.
3. Press **▶ CYCLE**. Watch the ram crawl; at 6 s the PLC latches
   `ALM-1102 EXTEND TIMEOUT` — nobody coded "clog → timeout", it *emerged*.
4. Don't trust the alarm: the extend solenoid is energized (the red herring).
   Pick the **Pressure** instrument, click **PG-101** (pinned at 210 bar) then
   **PG-102** (sagging) → ~9 bar across the filter. That's your root cause.
5. **Repair → Replace filter element → RESET → CYCLE.** Clean cycle. Solved.

Then try the other seven from the **BRIEF** tab: transducer drift (weak parts,
no alarm), intermittent limit-switch wiring (random no-retract), and — because
the solvers are real — a cylinder seal leak vs. a worn pump that *both* look
weak but split cleanly on the **Dead-head pump test** (seal → 214 bar, pump
fine; worn pump → ~191 bar, pump condemned), plus air-in-oil, a sticky spool,
and an open solenoid coil.

## Layers
Left-hand tabs switch the same machine between **Hydraulic (P&ID)**,
**Electrical**, **Mechanical**, **PLC (live ladder + I/O)**, and **HMI**. The
fault lives in one layer; its symptoms show up in the others — which is the
whole skill.

## Career mode (the game)
Press **▶ START SHIFT** for the playable loop:

- A shift of **8 work orders**, each a *hidden* seeded fault with only an
  operator complaint to go on (some complaints are deliberately ambiguous —
  "slow extend" could be the filter *or* a sticky spool; "can't make tonnage"
  could be a worn pump *or* a cylinder seal).
- **Every shift is different:** ticket order is shuffled and fault severity is
  randomized, and the last two tickets are ⚠ PRIORITY calls with **two
  simultaneous faults** — fix one and the machine is *still* broken, exactly
  like the real nightmare where one fault masks another.
- **Personal best** (grade + total cost) persists across shifts in your browser.
- **Diagnose** with the instruments, pick the replacement part, and **CYCLE to
  verify**. A wrong part burns real money and the ticket stays open.
- **Economy:** $5,000 parts budget, downtime billed at $12/s while the machine
  is down. Blow the budget and the shift ends early.
- **Scoring:** end-of-shift grade from first-fix rate, mean time-to-repair, and
  total cost (parts + downtime), with a per-ticket breakdown.

**⚙ INSTRUCTOR** remains available outside a shift as a free-play sandbox to
inject any of the 8 faults yourself.
