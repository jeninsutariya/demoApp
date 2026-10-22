# Brand: Napspot

Date: 2026-10-22

**Built on a provisional angle.** `/replica-entrepreneur` collected 0 reviews
(every review source was blocked), so the angle below comes from one press
review plus a hypothesis, not from ranked user complaints. Revisit the name
and voice once `replica/feedback.md` exists. Name changes are cheap until the
App Store listing goes live.

Provisional angle: *a calm daily logic puzzle with no ads*. Grounded only in
Android Central's "one big problem" (ads after almost every level; see
`fixes.md`).

## Name

**Recommended: Napspot.** Every cat needs its own spot to nap: the game's
rule (one per row, column and colour, none touching) in two words. Calm,
and says nothing about ads either way.

### 20 candidates

| style | candidates |
| --- | --- |
| descriptive | Cat Logic, Catgrid, Nap Grid, Lap Logic |
| compound | **Napspot**, **Sunpatch**, Sillspace, Catnap Daily |
| invented | **Tabbi**, Felo, Purrlo, Nekoro |
| metaphor | **Windowsill**, Hearthrug, Cushion, Basket |
| verb | **Curlup**, Settle, Perch, Snooze |

Cut before checks:
- Anything with *meow*, *miaw*, *-doku* or *cat sudoku*. That covers the
  original and the many same-category apps the recon found (Meawdoku,
  MiawDoku, Catdoku, Meow Sudoku, Meow Puzzle, Meowoof).
- *Queens* and *Star Battle*: other well-known names for this puzzle type.
- Cat Logic, Catgrid, Nap Grid and Lap Logic are too generic to protect as a
  trademark.
- Purrlo: a cat pun, which is the original's style of name.
- Settle, Perch, Snooze, Cushion and Basket are common words already used by
  many apps.

### Checks on the shortlist

Only the web check could be run here. Trademark databases, domain lookups,
the App Store and social sites were all blocked by the environment's network
policy. Nothing below says "available", because none of those checks has
been run.

| check | Napspot | Sunpatch | Curlup | Windowsill | Tabbi |
| --- | --- | --- | --- | --- | --- |
| web: name + app/game (2026-10-22) | no app or game found; nearest "SnapSpots" (photo app) [1] | no app or game; "Sun Patch" is a UV sticker brand with sunpatch.com [2] | no app; nearest "Curl Up and Die" (itch.io game) [3] | **conflict**: *Windosill*, a known puzzle game [4] | **conflict**: *Tabby*, a cat-lovers' dating app [5] |
| US trademark (USPTO, classes 9 and 41) | to run | to run | to run | cut | cut |
| EU trademark (EUIPO / TMview) | to run | to run | to run | cut | cut |
| Canada (CIPO) | to run | to run | to run | cut | cut |
| WIPO Global Brand Database | to run | to run | to run | cut | cut |
| domain (.com, .app) | to run | sunpatch.com in use [2] | to run | cut | cut |
| App Store and Google Play exact search | to run | to run | to run | cut | cut |
| handles (X, Instagram, TikTok, GitHub) | to run | to run | to run | cut | cut |

[1] https://appgoblin.info/apps/6781947475
[2] https://www.naturebabyoutfitter.com/products/sunnypatch-uv-detecting-stickers
[3] https://kwoodring.itch.io/curl-up-and-die
[4] https://www.mobygames.com/game/41970/windosill/
[5] https://www.datingnews.com/apps-and-sites/tabby-improves-dating-for-cat-people/amp/

Order: **Napspot**, then Curlup, then Sunpatch (its .com is taken).

These are screening checks, not legal clearance. Before paying for a domain,
an icon or a listing, have a trademark lawyer search the name.

## Palette

The only brand change is the accent: **plum `#6b3fa0`**, replacing the
neutral placeholder blue `#3a5bd9`. Plum is warm and evening-ish, which suits
"nap", and it sits apart from the danger red, the success green and the ten
region colours. Every other role (cream background, ink text, the region set)
is unchanged.

The original's brand colours are unknown: its screenshots were never seen. So
plum couldn't be checked against them, and `brand.json` has no colours to
sweep for. When you have screenshots, add its main colours to `brand.json`
and pick a new accent if plum turns out close to theirs.

`contrast.py`: 56 pairs, **0 AA failures**. Plum improves every pair the
old blue had: on-accent 7.38:1 (was 5.71), accent on regions at least
4.33:1 (was 3.35).

Files: `replica/design/tokens.json`, regenerated `tokens.css`,
`tailwind.tokens.js`, `ios-native/CatLogic/Theme/Tokens.swift`.

## Logo brief

- **Idea:** one cat curled asleep, filling exactly one square of a grid. It
  found its spot.
- **Mark:** a symbol plus a wordmark. The symbol alone is the app icon: a
  rounded square, a hint of grid lines, one curled cat shape in plum on cream
  (or cream on plum).
- **Wordmark:** "Napspot" in a rounded sans (Nunito ExtraBold works),
  lowercase or title case. No cat ears on letters, no paw prints: that's
  where every cat app goes.
- **Scale:** it must read at 16 px as a curl in a square, and fill a 1024 px
  icon without detail getting lost.
- **Deliverables:**
  - SVG master
  - iOS app icon 1024×1024 PNG, no transparency (Xcode makes the sizes from
    one image)
  - a dark and a tinted icon variant (iOS 18 and later)
  - favicon set for the landing page
  - social image 1200×630
- **Must not look like the original's icon.** It hasn't been seen (blocked),
  so put the drafts next to it on the App Store before choosing: no shared
  shape, colour pair or character pose. Also avoid looking like the other
  cat sudoku apps' icons.
- Never trace or "adapt" the original's cats. The placeholder `CatIcon` in
  the app is ours and goes once the real art exists.

## Voice

| word | not |
| --- | --- |
| **cosy** | not cutesy: no baby talk, no puns in every line |
| **clear** | not clinical: plain instructions, warm wording |
| **calm** | not sleepy: no pressure, but every line moves you on |

| do | don't |
| --- | --- |
| "Every cat found its spot" | "Purr-fect!! You're a meow-ster!" |
| "That's three slips" | "GAME OVER" |
| "Tap once to rule a spot out" | "Use elimination marking to constrain candidates" |
| "No rush" (once, where it matters) | "Hurry! Time's ticking!" |
| "Finish today's board to earn another" | "Watch an ad to get more hints!" |

### The 10 most-seen strings, rewritten

| where | before | after |
| --- | --- | --- |
| Home title | Cat Logic | Napspot |
| Home tagline | One cat per row, column and colour. | Every cat needs its own spot. |
| Daily card | Play today's board | Today's board is ready |
| Levels card | Continue: level 12 | Carry on: level 12 |
| Board help | Tap to mark a cell. Tap again (or double tap) for a cat. Hold to clear. | Tap once to rule a spot out. Tap again, or double tap, to place a cat. Hold to clear. |
| Win sheet | Every cat has a home | Every cat found its spot |
| Fail sheet | Out of lives / Try again | That's three slips / Start fresh |
| Fail (level) | Every board has one answer you can reach with logic alone. | Every board can be solved by logic alone. Have another go. |
| Hint sheet | Use a hint? … Solve the daily puzzle to earn another one. | Want a hint? … Finish today's board to earn another. |
| Daily done | Solved today in 2:13. A new board arrives tomorrow. | Done for today in 2:13. The next board appears at midnight UTC. |

Also: the leaderboard's empty state ("Nobody has finished today's board yet.
You could be first."), the tutorial's last button ("Let's play"), and the
missing-board screen ("This board isn't here"). None of these strings came
from the original; its copy was never seen.

## Where the name changed

- App display name: `Napspot` (Info.plist, via `project.yml`)
- Bundle id: `com.example.napspot`. Swap `com.example` for your own reverse
  domain.
- Game Center leaderboard id: `napspot.daily.fastest` (`backend.md` updated)
- READMEs

Not changed: the internal Xcode target and Swift module names (`CatLogic`,
`CatLogicKit`). Players never see them. Rename them with a project-wide find
and replace plus `xcodegen generate` if you want the repo to match.

## Sweep

`python3 .claude/skills/replica-brand/sweep.py . --config replica/brand.json`
reported: **Clean** (2026-10-22). It checks names and domains only, since
there are no colours to check (see Palette).

Still to check by eye once they exist: the app icon, the App Store
screenshots, the landing page and its social image.
