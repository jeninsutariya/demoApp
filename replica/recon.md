# Recon map: Meowdoku! by Oakever Games (iOS, also Android)

Scope (proposed): the puzzle core loop (board, rules, lives, win/fail), the
Daily Puzzle, level progression and a fastest-time leaderboard.
For: your own puzzle app to sell (assumed; change if not).
Date: 2026-10-22

**Confidence note.** This environment's network policy blocked apps.apple.com,
play.google.com and the review sites, so this map is built from search-engine
summaries of those pages, not from the pages or screenshots themselves. Rules
and headline features are confirmed by several sources. The screen list is
inferred and marked as such. Before `/replica-build`, play the app on your
phone for 15 minutes and correct the Screens table and the `unknown` rows in
`features.csv`.

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | App Store listing | https://apps.apple.com/us/app/meowdoku/id6761760135 | "Meowdoku!": double-tap to place a cat, 3 chances (hearts), Daily Puzzles, global leaderboards, offline. Read via search summary only |
| 2 | Google Play listing | https://play.google.com/store/apps/details?id=com.oakever.meowdoku&hl=en | "Meowdoku: Brain Puzzle Games", com.oakever.meowdoku, no internet needed |
| 3 | Android Central review (2026-09-20) | https://www.androidcentral.com/apps-software/meowdoku-is-sudoku-but-with-cats-and-it-is-highly-addictive-but-it-has-one-big-problem | rules; ads after almost every level; limited hints refilled by ads; no ad-free option on Android |
| 4 | App aggregator | https://mwm.ai/apps/meowdoku/6761760135 | listing text incl. "non-intrusive ads" claim |
| 5 | Fan site (unofficial) | https://meowdokugame.io/how-to-play/ | fish-cracker lives, Daily Challenge, Campaign 5x5 to 10x10 (150 levels). Not affiliated; treat as unverified |
| 6 | Fan site (unofficial) | https://www.meowdoku.org/ | rules restated |

Same-name apps by other developers exist (e.g. "Meowdoku: Sudoku Cat Puzzle",
id6763880105). Their features are not mixed in here.

## Core loop

Place one cat in every coloured region so no two cats share a row or column
or touch (even diagonally), using logic, with three mistakes allowed.

This is the "Queens" / "Star Battle (1 star)" logic puzzle family. The rules
are a well-known public puzzle genre; only the cat theme, art and content are
Oakever's.

## Screens

Inferred unless marked. IDs are stable.

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Home | app launch | pick Daily or Levels | ModeCard x2, streak/progress badge, settings button | first launch, returning (guess) |
| S02 | Level select | S01 -> Levels | choose next level | LevelGrid, LockedLevel, size/difficulty labels | locked, unlocked, completed (guess) |
| S03 | Puzzle board | S01 Daily or S02 level | solve | Board, RegionCell, Cat, XMark, LivesBar (3 hearts), Timer, HintButton, Undo/Restart (unconfirmed) | empty, in progress, mistake flash, last life (confirmed: board, cats, lives) |
| S04 | Mistake feedback | wrong placement on S03 | show the broken rule, lose a life | cell shake/red, life-lost animation | 3 -> 2 -> 1 lives |
| S05 | Puzzle failed | lives reach 0 | retry or watch ad | FailModal, Retry, (ad offer) | (guess) |
| S06 | Puzzle solved | last region filled | celebrate, show time | WinModal, time, Next, share? | daily vs level (guess) |
| S07 | Daily puzzle | S01 -> Daily | one shared board per day | Board + date header, "come back tomorrow" | not started, solved today (confirmed exists) |
| S08 | Leaderboard | S06 or S01 | fastest times | LeaderboardRow, rank, you-row | loading, offline, empty (confirmed exists) |
| S09 | Hints / rewards | S03 HintButton | spend or refill hints | hint count, watch-ad button | hints left, none left (Android Central) |
| S10 | Interstitial ad | after levels | monetization | system ad | (Android Central) |
| S11 | Settings | S01 gear | sound, haptics, privacy, restore purchase | Toggle rows | (guess) |
| S12 | How to play | first launch / settings | teach the 3 rules | animated rule cards | (guess) |

## Flows

```
F01 Solve a level (core loop)
    S01 -> S02 -> S03 (place cats, mark X) -> S06
    happy path clicks: 3 + 2 per cat (double-tap) = ~15 on 6x6
    edge: mistake (S04), last life lost (S05), app backgrounded mid-solve,
          tap on an already-marked cell, 10x10 board on a small phone

F02 Play today's Daily Puzzle
    S01 -> S07/S03 -> S06 -> S08
    edge: already solved today, date rollover mid-solve, time zone, offline
          (submit time later)

F03 Fail and retry
    S03 -> S04 x3 -> S05 -> S03 (fresh lives)
    edge: ad fails to load, offline

F04 Use a hint
    S03 -> S09 -> S03 (cell revealed or rule highlighted)
    edge: zero hints, ad not available

F05 First launch tutorial
    S12 -> S03 (tiny guided board) -> S01
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Board | 5x5 .. 10x10 | idle, solved, failed | S03, S07 |
| RegionCell | one colour per region | empty, X-marked, cat, error, hinted | S03 |
| Cat token | (your own art) | placed, wrong, celebrating | S03, S06 |
| LivesBar | 3 icons | full, losing, empty | S03 |
| Timer | running, paused | | S03, S06 |
| ModeCard | daily, levels | locked, done today | S01 |
| LevelGrid tile | by size | locked, open, solved (+best time) | S02 |
| Modal | win, fail, hint | | S05, S06, S09 |
| LeaderboardRow | top, you | loading | S08 |
| Toggle row | | on, off | S11 |

## Inferred data model

```
Puzzle      id, size (5..10), regions (int[size][size]), solution (cell[size]),
            difficulty, source (daily | level), daily_date?
            evidence: rules in sources 1,3,5; daily in 1
            confidence: high (shape), medium (difficulty field)

Attempt     puzzle_id, started_at, finished_at, lives_left, status
            (in_progress | solved | failed), cells (cat | x | empty)[]
            evidence: lives in 1,3; leaderboard times in 1
            confidence: high

Progress    unlocked_level, best_times {puzzle_id: ms}, daily_streak,
            hints_left
            evidence: hints in 3; streak is a guess
            confidence: medium

LeaderboardEntry  puzzle_id (daily), player (Game Center id or own account),
            time_ms, submitted_at
            evidence: source 1
            confidence: medium (could be Game Center, own backend unknown)
```

Relationships: Puzzle 1-n Attempt; Player 1-1 Progress; Puzzle(daily) 1-n
LeaderboardEntry. Everything except the leaderboard lives on-device (offline).

## Feature matrix

See `features.csv`. Must: 13, should: 8, could: 3, skip: 2.

## Out of scope (cannot or should not be cloned)

- Oakever's cat characters, art, sounds, name and icon. Draw your own.
- Their puzzle set. Generate your own with a solver (the genre is public).
- Their leaderboard data and players.

## Size

Screens 12, flows 5, entities 4. Hard parts:
1. Generating puzzles with exactly one solution across 5x5 to 10x10, and
   rating their difficulty (a backtracking solver plus a deduction-based
   grader).
2. Deterministic Daily Puzzle that is identical for every player offline
   (seeded generator by date) plus a leaderboard that accepts late, offline
   submissions without obvious cheating.
3. Feel: tap targets on a 10x10 board, mistake feedback, cat animations.

Size: **S to M** (a weekend for a playable web/iOS core loop; a few weeks for
polished iOS with daily, leaderboard and art).

Obvious improvement (feeds `/replica-entrepreneur`): the top public complaint
is ads after almost every level with no way to pay them off on Android.
