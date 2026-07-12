# Play Store submission kit — Retrofit Factory 3D

Everything needed to finish the Play Console listing for
`io.github.tlaba.retrofit3d`, in copy-paste form. The `.aab` is already
uploaded to Internal testing and `assetlinks.json` is live — what's left is
paperwork, and this folder is all of it.

## Files

| File | Feeds Console section |
|---|---|
| `listing.md` | Main store listing — name, descriptions, category, contact + which screenshot goes where |
| `screenshots/` | 8 phone shots (1080×1920), 3 landscape/tablet (1920×1080), feature graphic (1024×500) — captured from the real game |
| `content-rating.md` | App content → Content ratings questionnaire (incl. the brewery/alcohol answer) |
| `data-safety.md` | App content → Data safety (audited against the actual network code) |
| `declarations.md` | Everything else under App content: privacy policy, ads, app access, target audience + release-day checklist |

## Hosted pages (deploy with the game site)

| URL | Purpose |
|---|---|
| `https://tlaba.github.io/workbench/retrofit3d/privacy-policy.html` | Privacy policy (required) |
| `https://tlaba.github.io/workbench/retrofit3d/account-deletion.html` | Account-deletion request page (required because the app supports sign-in) |

Sources live beside the game at `retrofit3d/privacy-policy.html` and
`retrofit3d/account-deletion.html`; the Pages workflow stages both.

## Suggested order in Play Console

1. **App content** (Policy section): privacy policy URL → ads → app access →
   content ratings → target audience → data safety — answers in the files above.
2. **Main store listing**: paste text from `listing.md`, upload
   `../icons/icon-512.png`, `screenshots/feature-graphic.png`, then the phone
   screenshots in the order listed in `listing.md`.
3. Promote the Internal-testing release when everything shows a green check.
