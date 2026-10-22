# Fixes: what Meowdoku!'s users hate, and what to do about it

Date: 2026-10-22

**Sample: 0 user reviews.** Nothing below is ranked, because there is
nothing to rank yet.

Every review source was blocked by this environment's network policy:
Apple's review feed (`itunes.apple.com`), Google Play, Reddit, Hacker News
(`hn.algolia.com`) and the press sites. Web search still works, but it returns
summaries in its own words, not the reviewers' text. The rules for this step
are verbatim quotes with links and never anything made up, so no reviews were
collected from search summaries.

## What we have instead (not reviews)

- **One press review:** Android Central, 2026-09-20,
  https://www.androidcentral.com/apps-software/meowdoku-is-sudoku-but-with-cats-and-it-is-highly-addictive-but-it-has-one-big-problem.
  According to a search summary (the page itself couldn't be opened, so
  there's no verbatim quote): its "one big problem" is mandatory ads after
  almost every level, with no paid ad-free option on Android, and hints are
  limited and refilled by watching ads.

That is one source, a journalist rather than users. Under the skill's rules it
is **thin**: it supports a direction, not a plan.

## Bets the clone already makes on that one source

These were built before any reviews existed. Check them against the real
sample:

| bet | in the clone | holds if reviews show |
| --- | --- | --- |
| No ads between levels | no ads at all | an "Ads" theme with many low-star reviews |
| Hints without ads | 3 hints, +1 per solved daily | a "Hints" theme about ads or scarcity |
| One-time purchase, not ads | not built (nothing to sell yet) | "would pay to remove ads" requests |

## Hypotheses to test (not angles yet)

- People like the puzzle and the cats but hate how it's paid for.
- A daily habit (streaks, the daily board) is what keeps people. If so,
  reviews will mention streaks, the daily and resets.

The three angles, the ranked lists and the fix plan get written once
`feedback.md` exists. No rows were added to `features.csv`, because there's no
evidence yet.

## How to get the sample (about 10 minutes)

1. **Allow `itunes.apple.com`** in this environment: the cloud environment
   menu in the session's title bar, then Edit, then Network access. Add it
   under Allowed domains (keep "Allow package managers" ticked), or choose a
   broader level. Steps: https://code.claude.com/docs/en/cloud-environments#network-access
2. Fetch App Store reviews from Apple's official feed (up to 500 per
   country, most recent first):

   ```bash
   python3 scripts/fetch_app_store_reviews.py              # us, gb, ca, au
   ```

3. **Add at least two more sources by hand.** Copy reviews into
   `replica/reviews.csv` exactly as written, one row each:
   `source,url,date,rating,text`.
   - Google Play: https://play.google.com/store/apps/details?id=com.oakever.meowdoku (See all reviews, newest first; read the 2 to 4 star ones too)
   - Reddit: search "meowdoku", "meowdoku ads", "meowdoku alternative"

   Or allow `play.google.com` and `www.reddit.com` too, and I'll read the
   pages and copy them in the same way.
4. Rank them, then run `/replica-entrepreneur` again:

   ```bash
   python3 .claude/skills/replica-entrepreneur/reviews.py replica/reviews.csv \
     --themes replica/themes-puzzle.json --out replica/feedback.md
   ```

`replica/themes-puzzle.json` sorts reviews for this kind of game: ads,
paying to remove ads, hints, lives, puzzles that need guessing, difficulty,
running out of puzzles, controls, bugs, the daily and streaks, leaderboards,
price, readability and colour-blindness, and the cats and art.
