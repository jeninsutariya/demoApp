# Deploy: Napspot

Date: 2026-10-22

## Verdict: preflight failed, nothing deployed

Two checks fail, and either one stops the deploy:

1. **The app has never been built.** There's no Xcode or iOS SDK in this
   environment, so the SwiftUI app has never compiled, run or been tested on
   a device or Simulator. A production build is the first preflight line.
2. **A must-have is missing:** cat art (12 of 13 must-haves done). The app
   still uses a placeholder cat, and there's no app icon.

Also not yet true, and required before going live: no `/replica-test` run
(so no bug list showing zero open S1 or S2 bugs), trademark checks on the
name not run, privacy page not hosted, no favicon or social image.

The landing page could technically go up today, but it would publish the
name "Napspot" before any trademark screening. It stays down until you've
run the checks in `brand.md` and say go.

## Preflight results

| check | command | result |
| --- | --- | --- |
| end-to-end tests | `npx playwright test` (the skill's default) | **n/a**: no web app. The iOS equivalent is UI testing in the Simulator, which hasn't happened |
| iOS logic tests | `cd ios-native/CatLogicKit && swift test` | **pass**: 32 tests, 0 failures (Swift 6.1.3, Linux) |
| reference engine | `npm test` | **pass**: 6 tests |
| feature parity | `parity.py replica/features.csv` | **fail**: 89.1, must-haves 12 of 13; "Not shippable yet" |
| rebrand sweep | `sweep.py . --config replica/brand.json` | **pass**: "Clean", exit 0 |
| store listing | `listing.py replica/launch/listing.json` | **pass**: 0 errors, 0 warnings |
| production build | Xcode > Product > Archive | **not run**: impossible here |
| open S1/S2 bugs | `/replica-test` bug list | **unknown**: never tested |
| privacy policy | `site/privacy.html` | **draft**, not hosted, not legally reviewed |
| terms | none | OK for the App Store: Apple's standard licence agreement applies unless you add your own |
| cookie banner | site sets no cookies, no third-party requests | **not needed** (fixed today: fonts were loaded from Google Fonts, now self-hosted) |
| account deletion | the app creates no accounts | **n/a** |
| favicon, titles, social image | titles yours; no favicon or social image | **fail**: wait for the logo brief's deliverables |

## When the checks pass: the landing page

Static files only (`site/`), no build step, no env vars, no database.
**Cloudflare Pages** is the suggested host (free, HTTPS, previews per branch);
Netlify or GitHub Pages work the same way.

1. You: create a Cloudflare account, then Workers & Pages > Create > Pages >
   connect this GitHub repo.
2. Build settings: framework none, build command empty, output directory
   `site`, production branch `main`.
3. Pull requests get preview URLs automatically. Check the preview on your
   phone before merging.

Domain (after you buy it; `napspot.com` was not checked, see `brand.md`):

| record | name | value |
| --- | --- | --- |
| CNAME | www | `<your-pages-project>.pages.dev` |
| CNAME (flattened) or ALIAS | @ | `<your-pages-project>.pages.dev`. Cloudflare DNS flattens apex CNAMEs; other registrars call it ALIAS or ANAME |

Then in Pages > Custom domains, add both, make the apex canonical, and
redirect `www` to it. HTTPS is issued automatically; open both URLs to
check.

Email: the app and site send no email, so you only need a mailbox for
`support@` (the site still says `support@example.com`). Your mail provider
gives the MX, SPF (TXT) and DKIM records. Add DMARC as well:

| record | name | value |
| --- | --- | --- |
| TXT | _dmarc | `v=DMARC1; p=none; rua=mailto:you@yourdomain` (tighten to `p=quarantine` once reports are clean) |

## When the checks pass: the iOS app

Owned by you: the Apple Developer Program ($99 a year), App Store Connect,
signing.

1. App Store Connect: create the app (bundle id from `project.yml`, with
   your own reverse domain in place of `com.example`), the Game Center
   leaderboard (`backend.md`) and the `napspot.levels.all` purchase
   (`launch/pricing.md`). Sign the Paid Apps agreement.
2. Xcode: set the team, choose Any iOS Device, Product > Archive >
   Distribute App > App Store Connect > Upload.
3. **TestFlight first:** internal testers, then a public link for the beta in
   `launch/launch-plan.md`. Test the purchase and Game Center with Sandbox
   accounts.
4. Then submit for review with `launch/listing.json`, screenshots, the 4+
   age rating and the review notes in the launch plan.

There are no production services to create: no database, no server, no
API keys. Game Center and StoreKit are Apple's, so nothing needs to be set up
or rotated for "production".

## The first week (once live)

- **Every day:** Xcode Organizer > Crashes; App Store Connect > TestFlight
  feedback.
- **Retention:** App Analytics, day-1 and day-7 retention, to see whether
  the daily habit forms.
- **Unlocks:** sales and trends; the share of players who reach level 60
  and buy.
- **Daily rollover:** check the Game Center board after 00:00 UTC. It should
  reset, and the app's new board should match for everyone. Ask a beta tester
  in another time zone.
- **Site:** add an uptime check (Cloudflare's own, or any free monitor) on
  the home page, alerting your email.
- **Do it yourself:** install from TestFlight, solve the daily, post a time,
  unlock levels in the sandbox, restore on a second device.

## Next action

You build in Xcode and send me the errors, if any. Everything else follows
from that build.
