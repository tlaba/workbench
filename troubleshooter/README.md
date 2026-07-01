# Industrial Troubleshooting Sim — engine + press prototype

A realistic, multi-discipline troubleshooting game where faults are **emergent,
not scripted**. This folder is the technical vertical slice.

**▶ Play it live (no install):**
https://raw.githack.com/tlaba/workbench/main/troubleshooter/hydraulic-press-troubleshooter.html

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
- **Diagnose** with the instruments, pick the replacement part, and **CYCLE to
  verify**. A wrong part burns real money and the ticket stays open.
- **Economy:** $5,000 parts budget, downtime billed at $12/s while the machine
  is down. Blow the budget and the shift ends early.
- **Scoring:** end-of-shift grade from first-fix rate, mean time-to-repair, and
  total cost (parts + downtime), with a per-ticket breakdown.

**⚙ INSTRUCTOR** remains available outside a shift as a free-play sandbox to
inject any of the 8 faults yourself.
