# Industrial Troubleshooting Sim — engine + press prototype

A realistic, multi-discipline troubleshooting game where faults are **emergent,
not scripted**. This folder is the technical vertical slice.

| File | What it is |
|---|---|
| [`hydraulic-press-troubleshooter.html`](./hydraulic-press-troubleshooter.html) | **Live, clickable diagnostic workstation.** Open in any browser — no build, no deps. Runs a real reduced physics engine + independent PLC scan for a 150-ton hydraulic press across 5 layers. |
| [`SIMULATION_ENGINE.md`](./SIMULATION_ENGINE.md) | The engine spec (component/signal-propagation model, tick+scan loop, fault chokepoint) and the press worked end-to-end across all five layers with four fault scenarios. |

## Try it in 30 seconds
1. Open the HTML file in a browser.
2. Top bar → **⚙ INSTRUCTOR → ① Clog pressure filter**.
3. Press **▶ CYCLE**. Watch the ram crawl; at 6 s the PLC latches
   `ALM-1102 EXTEND TIMEOUT` — nobody coded "clog → timeout", it *emerged*.
4. Don't trust the alarm: the extend solenoid is energized (the red herring).
   Pick the **Pressure** instrument, click **PG-101** (pinned at 210 bar) then
   **PG-102** (sagging) → ~9 bar across the filter. That's your root cause.
5. **Repair → Replace filter element → RESET → CYCLE.** Clean cycle. Solved.

Then try the other three from the **BRIEF** tab: transducer drift (weak parts,
no alarm), intermittent limit-switch wiring (random no-retract), and a cylinder
seal leak that mimics a bad pump (use the **Dead-head pump test** to exonerate
the pump).

## Layers
Left-hand tabs switch the same machine between **Hydraulic (P&ID)**,
**Electrical**, **Mechanical**, **PLC (live ladder + I/O)**, and **HMI**. The
fault lives in one layer; its symptoms show up in the others — which is the
whole skill.
