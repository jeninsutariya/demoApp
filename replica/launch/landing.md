# Landing page: Napspot

Built at `site/index.html` (static, no build step; tokens from
`site/tokens.css`). Privacy page: `site/privacy.html`.

**Evidence note:** the problem section rests on one press review (ads after
almost every level), not on user reviews; there are 0 so far. Re-check it
against `feedback.md` once reviews are in.

## 1. Hero
- Headline: **A daily cat logic puzzle. No ads, ever.**
- Under it: Every cat needs its own spot: one per row, column and colour, and
  none touching. A new board every day, the same for everyone.
- Button: **Coming soon to iPhone** (no link until the App Store page exists;
  swap in the App Store badge then).
- Visual: an illustration of a board drawn in HTML from the real level data.
  Replace it with a real Simulator screenshot after the first build.

## 2. The problem
Logic puzzles are meant to be calm. Too many puzzle apps break your
concentration with an ad after nearly every level, and charge you in ads for
a hint. (Paraphrased, not quoted. Source: one press review.)

## 3. How it works
1. Tap a spot once to rule it out.
2. Tap again, or double tap, to place a cat.
3. One cat per row, column and colour, and no two touching. Three slips and
   you start fresh.

## 4. Features (fixes first)
- **No ads.** Not between levels, not for hints, not ever.
- **Hints you earn by playing:** three to start, one more for every daily
  board you finish.
- **One board a day for everyone**, with today's fastest times on Game Center.
- **300 hand-checked levels**, from 5×5 to 10×10, each with exactly one
  answer you can reach by logic.
- **Region shapes** for players who can't tell the colours apart.
- **Plays offline.** A daily time solved offline posts when you're back
  online (the same day).

## 5. Pricing
| Daily, free | Every level, $3.99 once |
| --- | --- |
| daily board, levels 1 to 60, hints, Game Center | levels 61 to 300, up to 10×10 |
No subscription. Family Sharing included.

## 6. FAQ
- **Is it really free?** The daily board and the first 60 levels are, for
  good. The rest is one payment.
- **Do I need an account?** No. Game Center is optional and only for the
  leaderboard.
- **When does the new board arrive?** At midnight UTC, the same moment for
  everyone, so the leaderboard is fair.
- **Android?** Not yet. iPhone and iPad first.
- **What data do you collect?** None. Progress stays on your phone.
- **Refunds?** Through Apple, like any App Store purchase.

## 7. Final call to action
**Find today's spots.** Coming soon to iPhone.

## Proof
None. There are no users yet, and nothing gets invented. Add real quotes
from beta testers, with their permission, after TestFlight.

Contrast: the page only uses token pairs already checked by `contrast.py`
(text and text-muted on bg and surface, on-accent on accent, accent on bg):
0 AA failures.
