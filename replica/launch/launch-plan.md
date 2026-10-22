# Launch plan: Napspot

Date: 2026-10-22. Nothing here can start until the app builds; that's step 0.

## 0. Before anyone sees it

| # | task | who | status |
| --- | --- | --- | --- |
| 1 | First Xcode build; fix compile errors; run every flow in the Simulator | you + Claude | not started: the SwiftUI has never been compiled |
| 2 | Cat art and app icon from the brief in `brand.md` | designer / you | not started |
| 3 | Trademark and domain checks for "Napspot" (`brand.md`), then a lawyer | you | not started |
| 4 | Real reviews of the original, then `/replica-entrepreneur` again, to confirm or change the angle | you allow `itunes.apple.com`, Claude runs it | blocked |
| 5 | App Store Connect: app record, bundle id, Game Center leaderboard (`backend.md`), the `napspot.levels.all` purchase (`launch/pricing.md`), Paid Apps agreement, Small Business Program | you | not started |
| 6 | Privacy: App Privacy answers ("Data Not Collected" if nothing changes; confirm Game Center's treatment in App Store Connect's help), privacy policy at `site/privacy.html` reviewed and hosted | you | draft written |
| 7 | Support URL and a real support email (the site uses `support@example.com`) | you | placeholder |
| 8 | Host `site/` (`/replica-deploy`) | Claude + you | written |

## 1. App Store submission kit

- **Listing:** `replica/launch/listing.json` (passes `listing.py`). Paste
  the fields into App Store Connect.
- **Screenshots:** from the Simulator at the sizes App Store Connect asks for
  when you upload (they change; currently the largest iPhone and iPad sizes
  are required). Show the fixes first:
  1. a board mid-solve, captioned "No ads. Not ever."
  2. the daily board and leaderboard: "One board a day, the same for everyone"
  3. the level list: "300 levels, 5×5 to 10×10"
  4. region shapes on: "Shapes for every colour"
  5. a hint: "Hints you earn by playing"
- **Age rating:** 4+ (no objectionable content, no unrestricted web access,
  no user-generated content).
- **Review notes for Apple:**
  - No account is needed.
  - Game Center sign-in is optional and only used for the daily leaderboard.
  - The "All levels" purchase can be tested in the sandbox. Level 61 and up
    shows it.
  - The daily board changes at 00:00 UTC.
- **Guideline 4.1 (copycats):** the name, cats, colours, words and level set
  are all our own. The screenshots lead with what's different (no ads, earned
  hints, region shapes).

## 2. Beta (2 to 4 weeks before launch)

- **TestFlight** external testing, 20 to 50 people. A waitlist needs a form
  service the site doesn't have yet. Until then the "Coming soon" button stays
  unlinked; add a TestFlight public link to it once the beta is up.
- Ask every tester three things: where they got stuck, whether the daily
  reset time works for them (UTC midnight is evening in the Americas), and
  whether $3.99 for 240 levels feels fair.
- Quotes from testers can go on the site **only with their written
  permission**. Never use quotes from the original's reviews.

## 3. Watching it

- **Crashes:** Xcode Organizer (from App Store and TestFlight users who opt
  in). No third-party SDK, so the privacy answers stay "no data collected".
- **Usage:** App Store Connect's App Analytics (opt-in, aggregated):
  downloads, retention, purchases.
- **The two numbers that matter early:** day-7 retention (does the daily
  habit form?) and the share of people who reach level 60 and then unlock.

## 4. Where to tell people

The research that would show where the original's unhappy players talk was
blocked, so these are **places to check, not findings**:

- the original's own App Store and Google Play reviews (who complains about
  ads, and on what platforms)
- Reddit: puzzle and iPhone-gaming communities. Read each one's rules on
  self-promotion first, and post once, as the maker, with what's different.
- people who already play daily logic puzzles (word, number and "queens"
  style grids). They're the audience, not the original's users.

**Launch post** (Product Hunt, or a Hacker News "Show HN"), leading with the
fix:

> **Show HN: Napspot, a daily cat logic puzzle with no ads**
> I wanted a calm daily logic puzzle without an ad after every level, so I
> made one. One board a day, the same for everyone; 300 levels, each with
> exactly one answer you can reach by logic. Free to play daily; one optional
> purchase for the extra levels. Happy to talk about the puzzle generator: it
> grades difficulty by the deductions a person needs.

Don't name the original in posts or ads. A factual comparison is a question
for a lawyer.

## 5. The first 10 users

Talk to them one by one, by message or a 15-minute call, in the first two
weeks:

- 5 people who play a daily puzzle every morning
- 3 people who've paid to remove ads from a game
- 2 colour-blind players (for the region shapes)

Ask what they did on day 1, day 3 and day 7, and what would make them tell a
friend. Write the answers in `replica/launch/interviews.md`.
