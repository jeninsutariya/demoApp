# Parity: Cat Logic (iOS) vs Meowdoku!

Date: 2026-10-22

| measure | score | note |
| --- | --- | --- |
| Features, all rows | **89.1** | 22 rows scored, must-haves 12 of 13 |
| Features, confirmed rows only | **91.1** | 17 rows; leaves out 5 rows where the recon couldn't confirm the original has the feature |
| Layout | **not measured** | no screenshots of either app (see below) |
| Verified on a device | **none** | the iOS app has never been compiled or run |

**Verdict: not shippable.** One must-have is missing (cat art), the iOS app
has never been built, and `/replica-test` hasn't run, so there's no bug list
to show that no S1 or S2 bugs are open.

Read the feature score as "the code exists and the logic under it is tested".
The engine, rules, saving, timer, hints and leaderboard rules have 29 passing
Swift tests. None of the screens have been seen working on iOS.

## Feature parity

From `python3 .claude/skills/replica-diff/parity.py replica/features.csv`:

| area | score | rows |
| --- | --- | --- |
| monetization | 25.0 | 2 |
| social (leaderboard) | 50.0 | 1 |
| progress (stats) | 50.0 | 1 |
| settings | 50.0 | 1 |
| design (cat art) | 50.0 | 1 |
| puzzle | 100.0 | 11 |
| content (generator) | 100.0 | 1 |
| modes (daily, levels, difficulty) | 100.0 | 3 |
| platform (offline) | 100.0 | 1 |

Missing, in build order:

1. **[must] Cat art and animations:** partial. Placeholder cat shape, shake on a mistake, no win animation.
2. [should] Stats: partial. Solved count, best times and streak exist; no stats screen.
3. [should] Settings: partial. The sound toggle exists, but there are no sounds.
4. [should] Global leaderboard: partial. Game Center code is written but has never run, and the App Store Connect leaderboard doesn't exist yet.
5. [could] Interstitial ads: no, on purpose. They're the original's top complaint.
6. [could] Hints refilled by ads: partial. Hints are earned by solving dailies, and a hint doesn't explain itself.

Not scored: Android (dropped, iOS only), the original's cat characters, its
puzzle set and its leaderboard data (theirs), and an ad-free purchase (not in
the original on Android).

The 5 unconfirmed rows (undo/restart, level progression, difficulty, stats,
settings) are worth checking on the real app. If it lacks them, they become
features you added rather than parity.

## Layout parity: not measured

`imgdiff.py` needs the same screen from both apps at the same size:

- **Original** (`replica/screens/`): empty. This environment's network
  policy blocked the App Store page and Apple's image servers
  (`apps.apple.com`, `*.mzstatic.com`), so nothing could be saved.
- **Clone** (`replica/clone-screens/`): empty. The web screenshots went with
  the Expo app, and the iOS app needs the Simulator.

To get a score: take screenshots of the original on your phone (one per
screen, in the states listed in `recon.md`), and the clone's in the iPhone
Simulator at the same device size. Name them by screen ID (`S03.png`) and run:

```bash
for s in replica/screens/S*.png; do
  id=$(basename "$s" .png)
  python3 .claude/skills/replica-diff/imgdiff.py "$s" "replica/clone-screens/$id.png" --out "replica/diffs/$id.png" --json > "replica/diffs/$id.json"
done
python3 .claude/skills/replica-diff/parity.py replica/features.csv --visual replica/diffs/*.json --markdown
```

## Behaviour differences

From the recon's sources (App Store listing, Google Play listing, Android
Central review). Lines marked *unverified* need a check on the real app.

| flow | original does | clone does | fix or keep |
| --- | --- | --- | --- |
| F01 place a cat | double-tap a cell | double-tap, or tap twice (mark, then cat); hold to clear | keep: same gesture, and marking is one tap |
| F01 clicks on the happy path | 2 taps per cat (double-tap) | 2 taps per cat; 1 tap from Home to the next level | equal; the original's navigation clicks are *unverified* |
| F01 wrong cat | costs one of 3 hearts | costs one of 3 lives; the cell becomes an X | keep |
| F01 X marks | shown for impossible cells; whether automatic is *unverified* | manual only | check; if the original auto-marks, add it as a setting |
| F01 after a level | an ad after almost every level (Android Central) | no ad; straight to Next level | keep: this is the main complaint |
| F03 out of lives | *unverified* | Try again or Home; the daily keeps its clock on retry | check |
| F04 hints | limited; refilled by watching ads or rewards | 3 to start, +1 per solved daily, no ads; rings a cell without saying why | fix: explain the deduction (should) |
| F02 daily | new puzzle every day; global fastest-time board; reset time *unverified* | one board per UTC day with a countdown; Game Center board, top 50 plus your rank | check the original's reset time |
| offline | plays offline | plays offline; a daily time solved offline posts later the same UTC day | keep |
| remembered between visits | *unverified* | the board in progress after every move, best times, streak, settings | keep |

## Top five to build next

1. **First Xcode build and a run in the Simulator.** Fix whatever doesn't compile. Everything else depends on this.
2. **Cat art and a win animation:** the only missing must-have. Commission or draw it, then swap `CatIcon`.
3. **`/replica-test` in the Simulator:** walk F01 to F05, save `replica/clone-screens/S01..S12.png`, and log bugs. Without a bug list the verdict can't move.
4. **Game Center for real:** create the `catlogic.daily.fastest` leaderboard in App Store Connect (`replica/backend.md`) and post a time from a Sandbox account.
5. **Original screenshots** into `replica/screens/`, then the layout diff above. Settle the 5 unconfirmed rows while you're in the app.

After that, run `/replica-entrepreneur`. Feature parity is already high, and
"better than the original" comes from fixing what its users complain about.
