# Retrofit Factory 3D — Monetization Plan

*Draft v1 · a realistic, staged path from a free single-file web prototype to a
sustainable product. Written to fit what the game actually **is** — a calm,
thinky maintenance-strategy game whose core lesson ("condition-based maintenance
beats calendar overhauls and capacity chasing") is genuinely educational — not
to bolt on whatever monetizes fastest.*

---

## 1. What we are monetizing (and what we won't)

The product is a **short-session, systems-driven strategy game** with an
unusually credible reliability-engineering core. That shapes every decision here:

- **The fantasy is competence, not compulsion.** The satisfaction is diagnosing
  a failing plant and being *right*. Mechanics that manufacture anxiety to sell
  relief (energy timers, pay-to-skip-the-grind, loot boxes) would poison the one
  thing the game does well. **We will not ship them.**
- **The free web build is the funnel, not the product tier to protect.** A
  single self-contained HTML file that runs instantly with no install is the
  best top-of-funnel asset we have. Keep it free, keep it good, keep it linkable.
- **We charge for *more game and more polish*, never for *less friction in a
  game we deliberately made annoying*.** Everything paid below is additive
  content, a nicer wrapper, or a licensed use — not a tollbooth on the core loop.

The honest constraint: this is a niche title. The plan optimizes for a **modest,
durable revenue base from people who genuinely like the genre plus a real B2B/
education channel**, not for a viral F2P hit it was never designed to be.

---

## 2. Revenue streams, ranked by fit

Ranked by how well each fits the product and how realistic it is for a small team.

### Tier A — best fit, build first

| Stream | What it is | Why it fits |
|---|---|---|
| **Premium content packs (plant DLC)** | New levels beyond Level 1 (the Old Bakery). The GDD already scopes additional plants — a bottling line, a foundry, a water-treatment works — each with new machines, failure physics, and a distinct chokepoint puzzle. Sold as one-time packs or a "Season Pass" bundle. | Pure additive value. Buyers get *more of the thing they liked*. No dark patterns. Reuses the exact sim/economy engine, so marginal build cost per plant is content, not tech. |
| **"Complete Edition" one-time purchase** | A paid desktop/mobile build (Steam, itch.io, App Store, Play) with all plants, cosmetics, cloud saves, and quality-of-life the web demo lacks. Free web build stays as the demo. | Matches how thinky strategy players actually buy — a fair one-time price, no nickel-and-diming. The free web version is a genuine, generous demo that drives wishlists. |
| **B2B / education licensing** | The reliability-engineering model is real: condition-based vs. calendar vs. run-to-failure maintenance, bottleneck-as-minimum-of-chain, cascade coupling. License a branded/configurable build to trade schools, maintenance-tech certification programs, and industrial-training vendors. | Highest revenue-per-customer channel and the most defensible. The educational value is not a marketing veneer — it's the actual sim. See §5. |

### Tier B — good fit, add once A is proven

| Stream | What it is | Guardrails |
|---|---|---|
| **Cosmetics** | Machine liveries, plant color schemes, technician outfits, alternate HUD/UI themes, "clean vs. grimy" plant skins. Purely visual. | Never sell anything that touches the sim (no paid better parts, no paid time). Cosmetics only. |
| **Optional rewarded ads (web build only)** | Strictly opt-in: watch a short ad to unlock a bonus practice seed or a cosmetic. Never interstitials, never in the paid builds, never gating the core loop. | Web-demo only, opt-in only. If it degrades the calm feel, cut it. |
| **"Name in the plant" / supporter tier** | Small supporter purchase that puts a backer's name on a floor decal or safety sign. Cheap, warm, community-flavored. | Vanity only, capped so it never clutters the readable floor. |

### Tier C — later / opportunistic

- **Soundtrack & art book** on Bandcamp/itch for the ambient-industrial score.
- **Scenario editor + community workshop**, with a modest revenue-share on
  premium community plants once there's a community to share with.
- **Merch** (only if there's demonstrated fan demand — do not front-load).

### Explicitly rejected

Energy/stamina timers · pay-to-win parts or cash injections · loot boxes / gacha ·
forced interstitial ads · paywalling the tutorial or Level 1 · anything that makes
the base game *worse* to sell a fix. These conflict with the product's core appeal
and its education/B2B positioning, which is our most valuable channel.

---

## 3. Pricing (initial hypotheses, to be validated)

Placeholders to be tested against wishlists, demo conversion, and comparable
indie strategy titles — not final numbers.

| Item | Hypothesis | Rationale |
|---|---|---|
| Web build | **Free, forever** | Funnel + goodwill + education reach. |
| Complete Edition (desktop/mobile) | **$8–12 one-time** | Standard for a polished, focused indie strategy game; low enough for impulse, fair enough to respect. |
| Individual plant pack | **$3–5** | Snack-sized, clearly "more game." |
| Season Pass (all planned plants) | **~$15**, discount vs. buying separately | Rewards the committed fan; funds the content roadmap. |
| Cosmetic pack | **$2–4** | Impulse, purely optional. |
| Education/B2B license | **Custom (seat- or site-based)** | Value-priced to the institution; the highest-margin channel. See §5. |

Regional pricing from day one on any store that supports it.

---

## 4. Funnel

```
  Free web build  ──►  Wishlist / email capture  ──►  Complete Edition sale
  (instant, no install)     (end-of-run CTA,            (Steam/itch/mobile)
        │                     personal-best hook)              │
        │                                                      ▼
        └──►  Education/B2B inquiry  ────────────────►  Licensed deployment
              ("use this in your maintenance-training program")
```

- The **free web build is the demo and the ad.** It's shareable as a single
  URL, runs on a phone, and shows off the exact loop buyers are paying to get
  more of. Protect its quality above almost everything else.
- **Conversion moment:** the end-of-shift screen (post-mortem + personal best)
  is where a satisfied player is most receptive — a light, non-nagging "more
  plants / get the full game" CTA belongs there, not mid-run.
- **Education inquiries** likely arrive by a different door (a trainer finds it,
  not a gamer). A visible "Using this to teach? Get in touch" link costs nothing
  and opens the highest-value channel.

---

## 5. The education / B2B channel (why it's the strongest bet)

Most "educational games" bolt a quiz onto an unrelated toy. Here it's inverted:
**the game is a maintenance-strategy simulator first**, and the teachable lesson
falls out of the sim math rather than being scripted on top. That's rare and
sellable.

- **Who buys:** trade schools and community colleges (industrial-maintenance and
  mechatronics programs), CMMS/EAM software vendors wanting an onboarding or
  marketing tool, corporate maintenance-reliability training teams, and
  professional bodies around RCM (reliability-centered maintenance).
- **What they pay for:** a branded/configurable build, an instructor dashboard
  (which strategies students chose, where they failed), a scenario library
  mapped to learning outcomes, and the right to deploy it internally.
- **Why it's defensible:** the underlying model — per-part wear, chokepoint as
  minimum-of-chain, moisture cascade coupling, condition-based vs. calendar vs.
  run-to-failure economics — is genuinely correct in shape and hard to
  fast-follow with a reskin. The `window.__matrix()` policy sweep already
  *demonstrates* the reliability lesson empirically; that's a selling point to
  an educator, not just a dev tool.

This channel has the best revenue-per-customer and the least dependence on
consumer-games marketing luck. **Treat it as a co-priority with the content
packs, not an afterthought.**

---

## 6. Phased roadmap

Each phase is gated on the previous one clearing a bar, so we don't fund content
for an audience that isn't there.

**Phase 0 — Prove interest (now, ~free).**
Free web build stays live. Add lightweight, privacy-respecting analytics
(sessions, completion rate, retry rate, grade distribution) and a wishlist/email
capture + an "using this to teach?" link. *Gate to Phase 1:* real, sustained
inbound and a healthy demo-completion rate.

**Phase 1 — First paid content.**
Ship Plant #2 as the first premium pack and stand up the paid **Complete
Edition** on itch.io (lowest-friction store). Validate that people will pay for
"more plants." *Gate:* pack conversion clears a set threshold.

**Phase 2 — Storefront + platform.**
Steam page (wishlist engine) and a mobile release of the Complete Edition. Add
cosmetics. Formalize the Season Pass around the plant roadmap. *Gate:* wishlist
velocity and Complete-Edition sell-through.

**Phase 3 — Scale the two winners.**
Whichever of {consumer content packs, education/B2B} is pulling hardest gets the
investment: more plants and a workshop/editor on the consumer side, or an
instructor dashboard and pilot deals on the B2B side. Likely both, weighted by
the data.

---

## 7. Metrics that decide the next move

- **Demo completion rate** — do players finish a shift? (core-loop health)
- **Retry rate** — do they replay the seed? (depth / stickiness)
- **Grade distribution** — are ★★/★★★ reachable but earned? (difficulty balance)
- **Wishlist → purchase conversion** (Phase 2+)
- **Pack attach rate** — of buyers, how many buy a second plant? (content-value proof)
- **B2B inbound volume and deal size** (channel-viability signal)

We do **not** track or optimize for engagement-maximizing "time in app" —
session length here should be *short and satisfying*. Sessions-per-week and
completion quality matter; raw minutes do not.

---

## 8. Principles (the short version)

1. The free web build stays free and stays excellent — it's the funnel.
2. Sell **more game**, never **less friction in a game we made worse on purpose**.
3. No mechanic that trades the calm, competent feel for compulsion.
4. Cosmetics never touch the simulation.
5. Education/B2B is a first-class channel, not a slide at the end of the deck.
6. Every phase is gated on evidence, so we never over-build for an audience that
   hasn't shown up.

---

*This is a planning document, not a commitment to any specific price or ship
date. Numbers in §3 are hypotheses to validate against real funnel data.*
