# Architecture: your cat logic puzzle (a rebuild of Meowdoku!'s core features)

Reads `replica/recon.md` and `replica/features.csv`. Working name until
`/replica-brand`: "the app".

**Update 2026-10-22 (backend):** the leaderboard is Game Center, the daily runs
on the UTC date, and the Expo app is removed (iOS only). The Supabase schema,
API and edge functions below are superseded and kept only as the plan for a
server-verified leaderboard. Current state: `replica/backend.md`.

**Update 2026-10-22:** the app is now built natively for iOS in SwiftUI
(`ios-native/`, iOS 17+), as asked. The Expo app in the repo root still
exists and shares the engine rules, levels and tokens; decide whether to keep
it for Android and web. On iOS, Game Center's recurring (daily) leaderboards
could replace the Supabase leaderboard below: weigh that in `/replica-backend`.
Payments on iOS go through StoreKit 2 directly (RevenueCat optional).

The original is an offline-first mobile puzzle game, so the default web/SaaS
stack is adapted: the app does almost everything on the device, and the server
exists only for the daily leaderboard.

## Stack

| layer | choice | why |
| --- | --- | --- |
| app | Expo (React Native) + TypeScript, expo-router | one codebase for iOS and Android (Android is nearly free) |
| puzzle engine | pure TypeScript in `engine/`, no dependencies | shared by the app and the server, so both check solutions the same way |
| styling | NativeWind (Tailwind for RN), tokens from `/replica-design` | same token pipeline the pack uses |
| animation | react-native-reanimated + react-native-gesture-handler | smooth cat placement and mistake feedback on large boards |
| on-device data | expo-sqlite + Drizzle | progress and in-progress boards survive app kills; fully offline |
| database | Postgres on Supabase | leaderboard only; free tier covers launch |
| auth | Supabase anonymous sign-in, created the first time a player opens the leaderboard | no sign-up wall for a casual game; can link Sign in with Apple later |
| server code | one Supabase Edge Function (`submit-daily`) | re-checks the solution before a time is ranked |
| payments | RevenueCat over Apple/Google in-app purchase | the stores require their own IAP for digital goods; Stripe is not allowed here |
| ads (could) | react-native-google-mobile-ads (AdMob), rewarded only | only if `/replica-entrepreneur` keeps ads; the main complaint is the original's ads |
| email | none | nothing to send |
| jobs | none needed | the daily puzzle is generated from the date, not published by a job |
| builds | EAS Build + EAS Submit | TestFlight and Play builds without a Mac |
| web (could) | Expo web on Vercel | playable demo for the landing page |

One database, one function, no microservices.

### How puzzles work

- **Rules:** N×N board, N coloured regions; exactly one cat per row, column
  and region; no two cats touch, even diagonally.
- **Uniqueness:** every puzzle has exactly one solution. The engine's solver
  counts solutions (stops at 2) and the generator keeps only boards with
  exactly 1. This is what makes "mistake" well defined: placing a cat on a cell
  that is not in the solution costs a life, even if no rule is visibly broken
  yet.
- **Generator:** seeded PRNG (mulberry32 or similar; `Math.random` is banned
  in `engine/`). Place a valid solution, grow regions from each cat, check
  uniqueness, retry. Difficulty is graded by which deduction techniques a
  human-style solver needs (singles, region-in-line, touching eliminations,
  pairs), not by size alone.
- **Levels:** generated at build time by `scripts/gen-levels.ts` into
  `assets/levels.json` (about 300 levels, 5×5 to 10×10, rising difficulty).
  Fixed forever once shipped, so best times stay meaningful.
- **Daily:** generated on the device from `seed = "daily-v1:" + YYYY-MM-DD`
  (the player's local date, like Wordle). The server builds the same board
  from the same seed to check submissions. Size by weekday (Mon 6×6 ... Sun
  9×9).

## Schema

Tables: 6 (2 on the server, 4 on the device). Access rules: Postgres RLS on
the server; the device is single-user with no access rules.

- Server: `replica/schema.sql`: `profiles`, `daily_results`, plus the
  `daily_leaderboard(date, limit)` function. Clients can read; only the edge
  function can insert.
- Device: `replica/schema.local.sql`: `attempts`, `level_progress`,
  `daily_progress`, `kv`.

Hard constraints held by the database, not the UI:
- one leaderboard result per player per day: `unique (user_id, puzzle_date)`;
- only one live attempt per puzzle on the device: partial unique index;
- lives 0..3, mistakes 0..2 and board size 5..10 are check constraints.

Puzzles are not tables. A level is an entry in the bundled JSON; a daily is a
pure function of the date.

## API

The app has no API for anything except the leaderboard. Screens call the
engine and SQLite directly.

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| `supabase.auth.signInAnonymously()` | creates a player and their profile (trigger) | anyone, once per install | none | session | F02 |
| `PATCH /rest/v1/profiles?id=eq.{me}` | rename yourself | the player (RLS) | `display_name` (1-20 chars, filtered for bad words on the client) | profile | F02 |
| `POST /functions/v1/submit-daily` | rebuild the day's board from the seed, check the cells are the unique solution, check the time is plausible (at least about 0.8 s per cat) and the date is within ±1 day of server UTC, then insert, or return the existing row if already submitted | signed-in player | `puzzle_date`, `engine_version`, `cells`, `time_ms`, `mistakes` | `{rank, total}` | F02 |
| `POST /rest/v1/rpc/daily_leaderboard` | top 50 for a date plus your own row | anyone | `p_date`, `p_limit` | rows `{rank, display_name, time_ms, is_me}` | F02 |
| `POST /functions/v1/delete-me` | deletes the auth user; profile and results cascade | signed-in player | none | 204 | settings |

On the device (no network): load level, load/generate daily, place cat, mark
X, clear cell, undo, restart, use hint, save attempt. All are engine and
SQLite calls in F01, F03, F04 and F05.

Webhooks in: none (RevenueCat entitlements are read by the client SDK).
Webhooks out: none.
Jobs: none. Optional later: a weekly SQL job that hides results under the
plausibility floor of a newer engine version.

## The parts that bite

- **Time zones:** the daily runs on the player's local date, so the server
  accepts dates within ±1 day of UTC "today". A player who changes their phone
  clock gets at most one extra day early, and the board is still checked.
- **Determinism:** the daily depends on the generator never changing. Freeze
  `daily-v1`; any change ships as `daily-v2` with a new `engine_version`, and
  golden tests pin the first 30 dates' boards.
- **Generator speed:** a 10×10 board with a uniqueness check must generate in
  under 300 ms on a mid-range phone. Measure in the vertical slice. If it is
  slower, ship two years of dailies pre-generated in `assets/dailies.json` and
  give the server the same file.
- **Offline:** everything works with no network. A solved daily is saved with
  `submitted = 0` and sent when the app next comes online.
- **Idempotency:** retries of `submit-daily` hit `one_result_per_day` and
  return the existing result; the first time stands.
- **Cheating:** times come from the client. The checks are a verified
  solution, a minimum plausible time and one result per day, plus a `hidden`
  flag for moderation. Anonymous accounts are cheap to make, so the
  leaderboard can be gamed; acceptable for a casual game, but say "for fun" in
  the UI.
- **App lifecycle:** the timer pauses on background, and the attempt is saved
  after every move, so killing the app loses nothing.
- **Touch targets:** a 10×10 board on an iPhone SE gives cells of about 33 pt,
  under Apple's 44 pt guideline. Use pinch-zoom or a cell-cursor mode on small
  screens.
- **Store rules:** apps that create accounts must offer account deletion
  (`delete-me`). Digital purchases must use IAP. Ads need an App Tracking
  Transparency prompt only if they track; prefer non-personalised ads.
- **GDPR:** an anonymous user id plus a display name is the only personal
  data, and `delete-me` removes both.
- Rate limits, search, realtime, email, files, multi-tenancy: not applicable.

## Build order

1. **Vertical slice:** the engine (seeded PRNG, solver, uniqueness check,
   6×6 generator) plus S03 board on one generated puzzle with cats, X marks,
   3 lives, and the S05/S06 fail and win states. Table: `attempts`. No server.
   Proves the engine, the generator speed and the feel on a phone.
2. **Must-haves:** generator for every size from 5×5 to 10×10; S04 mistake
   feedback; remove a cat or mark; S01 home; S07 daily from the date seed;
   S12 how-to-play; persist and resume with `attempts`, `daily_progress` and
   `kv`; offline everywhere; placeholder cat art (real art from
   `/replica-design`).
3. **Should-haves:** difficulty grader and `scripts/gen-levels.ts`; S02
   level select with `level_progress`; timer; undo/restart; S08 leaderboard
   (Supabase project, `schema.sql`, `submit-daily`, `daily_leaderboard`,
   anonymous auth, offline submit queue, `delete-me`); stats; S11 settings
   (sound, haptics); RevenueCat with one purchase (what it sells, ad-free or
   level packs, depends on step 4).
   **Could-haves:** S09 hints (a hint highlights the next forced deduction
   rather than revealing a cell); rewarded ads to refill hints; Android
   release; Expo web demo. Interstitial ads (S10) are left out on purpose
   until `/replica-entrepreneur` weighs in, since they are the original's top
   complaint.
4. **Fixes from replica-entrepreneur:** to be filled in once it has run.

Repo layout:

```
app/            expo-router screens (S01..S12)
components/     Board, RegionCell, Cat, LivesBar, Timer, Modal...
engine/         rng.ts, solver.ts, generator.ts, grader.ts, rules.ts (+ tests)
db/             drizzle schema for schema.local.sql, migrations
scripts/        gen-levels.ts, gen-golden-dailies.ts
assets/         levels.json, your own cat art, sounds
supabase/       migrations/0001_init.sql (= replica/schema.sql), functions/submit-daily, functions/delete-me
```
