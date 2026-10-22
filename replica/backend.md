# Backend: Napspot (iOS)

Date: 2026-10-22. Decisions taken with the user:

- **Leaderboard: Game Center**, not Supabase. No server, no keys, no
  accounts of our own.
- **iOS only.** The Expo app is removed; the TypeScript engine stays as the
  reference the Swift engine is tested against and as the level generator.

The skill's default stack (email sign-up, Stripe, Resend, jobs) does not
apply. This is an offline puzzle game whose only online feature is a daily
leaderboard. What each part became:

| part | what we have | why |
| --- | --- | --- |
| Auth | Game Center sign-in (Apple's sheet, at launch, skippable) | the only thing needing an identity is the leaderboard |
| Database | none on a server; progress in one JSON file on the device (`FileStore`) | nothing is shared except leaderboard times |
| Leaderboard | Game Center recurring leaderboard, resets daily 00:00 UTC | free, no server to run, friends and history come with it |
| Payments | none yet | nothing to sell until `/replica-entrepreneur`; iOS digital goods must use StoreKit 2, never Stripe |
| Email, jobs | none | the daily is computed from the date; nothing to send |
| Account deletion | not needed | the app creates no accounts; Game Center accounts are Apple's |
| Backups | n/a | no server; the progress file is in Application Support, which device and iCloud backups include |
| `.env.example` | not needed | there are no secrets or API keys anywhere |

## What changed in the app

- **The daily runs on the UTC date** (`Daily.todayKey`). A Game Center daily
  leaderboard resets at one moment worldwide, and everyone on it must be
  solving the same board. Before, each player got their local date's board.
  Trade-off: the new board arrives at 00:00 UTC, which is evening in the
  Americas (8 pm New York, 5 pm Los Angeles). The home screen and leaderboard
  show a countdown ("next board in 5 hr").
- **Submitting** (`GameCenterLeaderboard`): score = time in hundredths of a
  second, context = generator version × 100 + mistakes.
- **Too-fast times aren't posted:** under 0.8 s per cat (`Daily.isPlausible`).
  Game Center has no server-side check of the answer, so this, plus the score
  range set in App Store Connect, is all the anti-cheat there is.
- **Offline or signed out:** the time is saved and posted the next time the
  player signs in or opens the leaderboard, but only while it's still the
  same UTC day. It is never posted onto the next day's board.
- **Leaderboard screen:** today's top 50 plus your own rank, a signed-out
  state, and a button to Apple's Game Center screen (friends, past days).
- **Settings:** shows the signed-in player; the old "delete my leaderboard
  data" row is gone (the iOS Settings app manages Game Center).
- **Testing without App Store Connect:** launch with `-sampleLeaderboard`
  (Xcode > Scheme > Run > Arguments) to use sample players.

## What you need to do (Claude can't: it's your Apple account)

1. **Apple Developer Program** membership. In Xcode, set your team and change
   the bundle id `com.example.napspot` to yours. The Game Center capability
   is already in `CatLogic.entitlements`.
2. **App Store Connect** > your app > Features > **Game Center** >
   Leaderboards > **+** > **Recurring Leaderboard**:

   | field | value |
   | --- | --- |
   | Reference name | Daily fastest |
   | Leaderboard ID | `napspot.daily.fastest` (must match `GameCenter.dailyLeaderboardID`) |
   | Score format | Elapsed Time: To the Hundredth of a Second |
   | Sort order | Low to High |
   | Score range (optional) | min 480 (4.8 s, the fastest plausible 6×6), max 8640000 (24 h) |
   | Start date | the next 00:00 UTC |
   | Duration / restarts | 1 day / every 1 day |
   | Localization | English: name "Today's fastest", format "Elapsed time" |

3. On the app version's page in App Store Connect, add the leaderboard under
   **Game Center** before you submit.
4. Test on a device signed in with a **Sandbox** Apple ID (Settings >
   Developer > Sandbox Apple Account). Debug builds use the Game Center
   sandbox automatically.

## Security checklist

- [x] secrets only in env vars: there are none (no API keys; Game Center uses the device's Apple account)
- [x] input validated on the server: no server of ours. The client refuses implausible times and App Store Connect's score range drops out-of-range ones
- [x] authorisation on every read and write: scores can only be posted as the signed-in Game Center player; Apple enforces it
- [x] rate limits on auth, sign-up, email, SMS: none of these exist
- [x] webhooks verify signatures: no webhooks
- [x] uploads: none
- [x] no user data in URLs or logs: the app logs nothing about players
- [x] dependencies audited: `npm audit` 0 vulnerabilities (engine tooling only); the iOS app has no third-party packages
- [ ] privacy policy lists every processor: Apple (Game Center). Write it in `/replica-launch`. The app collects nothing itself; answer App Store Connect's privacy questions with that in mind

## Known limits

- **Cheating:** a modified app could post any time within the score range.
  Acceptable for a casual board. The fix would be our own server rebuilding
  the daily (the original Supabase plan in `architecture.md`).
- **Progress is per device.** iCloud sync (NSUbiquitousKeyValueStore or
  CloudKit) would be a later addition.
- **Not run on a device.** GameKit can't run in the Linux container. The
  behaviour around it (UTC day, plausibility, retry rules, signed-out state)
  is tested against a fake board in `LeaderboardTests`, but the GameKit calls
  themselves have never executed.
