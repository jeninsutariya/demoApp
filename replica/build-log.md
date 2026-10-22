# Build log

App: Expo SDK 58 (React Native 0.88), expo-router, TypeScript. Working name
"Cat Logic" until `/replica-brand`. Parity after this build: 88.4, must-haves
12 of 13 (cat art is a placeholder).

How to check it:

```bash
npm test                                          # engine + game rules (12 tests)
npm run typecheck
npx expo export --platform web && npx tsx scripts/screens.ts   # plays every flow, screenshots, fails on console errors
npx expo start                                    # run it on a phone with a development build
```

## Changes from architecture.md

- **Styling:** a generated `src/theme/tokens.ts` with StyleSheet, instead of
  NativeWind. Same tokens, one less build step. `build_tokens.py` writes it.
- **Storage:** AsyncStorage behind the `GameRepo` interface
  (`src/data/types.ts`), not expo-sqlite yet. Same function signatures, so
  `/replica-backend` swaps it without touching screens.
- **Leaderboard:** sample data behind `LeaderboardApi`, and the screen says so.
- **Daily:** generated on the device as planned. 10×10 generation measured at
  36 ms median and 262 ms worst case (Node), under the 300 ms budget.

## Screens

| ID | date | status | missing | harder than expected |
| --- | --- | --- | --- | --- |
| S01 Home | 2026-10-22 | done | | first-launch redirect to S12 created a second home screen; fixed |
| S02 Level select | 2026-10-22 | done | | |
| S03 Puzzle board | 2026-10-22 | partial | pinch-zoom on small screens: a 10×10 on a 390 pt phone gives ~35 pt cells, under 44 pt; drag-to-mark | timer pausing on background, sheets and focus |
| S04 Mistake feedback | 2026-10-22 | done | | |
| S05 Puzzle failed | 2026-10-22 | done | "watch an ad for a life" left out until /replica-entrepreneur | |
| S06 Puzzle solved | 2026-10-22 | partial | cat celebration animation, share | |
| S07 Daily puzzle | 2026-10-22 | done | past dailies are not playable (on purpose) | |
| S08 Leaderboard | 2026-10-22 | partial | real data (Supabase); offline/error states are built but only reachable once a real API exists | |
| S09 Hints | 2026-10-22 | partial | hint rings a cell but doesn't say why; no ads to refill | |
| S10 Interstitial ad | | not built | left out on purpose: the original's top complaint | |
| S11 Settings | 2026-10-22 | partial | sounds don't exist yet; restore purchase and privacy are placeholders | |
| S12 How to play | 2026-10-22 | done | | |
| /design | 2026-10-22 | done | primitives page, not linked from the app | |

## Not verified yet

- **Native:** everything was checked in the web build only (Chromium, 390 and
  1440 wide). Nothing has run on an iPhone or Android device; haptics and
  long-press feel need a real phone.
- **Keyboard only:** cells, buttons and tiles are focusable with visible focus
  rings, but no flow was completed with the keyboard alone.
- **Screen readers:** labels are set on cells, lives, tiles and rows, but
  VoiceOver and TalkBack were not run.
- **Reference screenshots:** `replica/screens/` is still empty (the App Store
  was blocked), so layouts were built from the recon specs, not compared to
  the original.

Screenshots for `/replica-diff`: `replica/clone-screens/` (390 wide, and
`-1440` versions).
