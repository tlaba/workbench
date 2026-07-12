# App content declarations — answers

**Play Console → Monitor and improve → Policy → App content.** One section per heading below.

## Privacy policy
```
https://tlaba.github.io/workbench/retrofit3d/privacy-policy.html
```

## Ads
- Does your app contain ads? **No**

## App access
- **All functionality in my app is available without special access requirements.**
- Rationale: the game is fully playable with zero sign-in. The only gated feature
  (cloud-save sync) uses open self-service sign-up (any email works, one-time code),
  so reviewers are never blocked. No demo credentials needed.

## Content ratings
- See `content-rating.md`.

## Target audience
- Age groups: select **13–15, 16–17, 18+** (nothing under 13).
- "Could your store listing unintentionally appeal to children?" → **No**
  (industrial-maintenance theme, no childlike characters or art style).
- Selecting no under-13 group keeps you out of the Families policy track —
  the right call for this game.

## Data safety
- See `data-safety.md`.

## Government / news / financial / health declarations
- News app? **No** · Government app? **No**
- Financial features? **None of the above**
- Health features? **None / not a health app**
- COVID-19 app? **No**

## Store settings
- App or game: **Game** · Category: **Simulation** · Free
- Contact email (public): `legops@gmail.com`

## Advertising ID
- Does your app use an advertising ID? **No**
  (No ads SDK, no analytics — the audit found zero references.)

## Release-day checklist (in order)

1. Upload `app-release-bundle.aab` to **Internal testing** ✅ (done)
2. Complete every App-content section above (this folder has all the answers)
3. Main store listing: paste from `listing.md`, upload graphics from `screenshots/`
4. Verify the privacy-policy + account-deletion URLs return 200 (they deploy with the game site)
5. Promote Internal → Closed/Open testing → Production when ready
6. **The day the in-game store ships:** update the description's "free preview" +
   "no in-app purchases" lines, re-run the content-rating questionnaire (digital
   purchases = Yes), and declare Play Billing.
