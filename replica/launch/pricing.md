# Pricing: Napspot

Date: 2026-10-22. Model chosen by the user: **free, plus one optional
one-time unlock**.

## The market (what could be read)

Pages were read through search summaries only, because the store pages
themselves were blocked here. Check each line on the page before relying on it.

| app | price | ads | source, date read |
| --- | --- | --- | --- |
| Meowdoku! (the original) | free; in-app purchases not confirmed | yes: after almost every level, per Android Central; no ad-free option on Android | https://apps.apple.com/us/app/meowdoku/id6761760135 and https://www.androidcentral.com/apps-software/meowdoku-is-sudoku-but-with-cats-and-it-is-highly-addictive-but-it-has-one-big-problem (search summaries, 2026-10-22) |
| Meowdoku: Sudoku Cat Puzzle (another developer) | free | listing says no ads | https://apps.apple.com/us/app/meowdoku-sudoku-cat-puzzle/id6763880105 (search summary, 2026-10-22) |

No in-app purchase prices were found for either, so **$3.99 is a starting
guess, not a benchmark**. Revisit it after the first weeks of sales.

What reviewers said about price and billing: **unknown, 0 reviews collected**
(see `replica/fixes.md`). Re-check once `feedback.md` exists, especially for
"would pay to remove ads".

## The model

| tier | for | price | what's in it |
| --- | --- | --- | --- |
| **Daily** | everyone | free | the daily board and Game Center leaderboard, levels 1 to 60, hints (3, plus 1 per daily solved), every setting |
| **Every level** | people who finish the free 60 | **$3.99 once** (suggested) | levels 61 to 300, up to 10×10 |

- **No ads anywhere**, in either tier. That's the angle.
- **No subscription.** There are no server costs to cover, and the billing
  complaints that come with subscriptions don't exist when there's nothing to
  cancel.
- **Family Sharing on.**
- **The offer appears in four places only:** after solving level 60, on a
  locked tile in the level list, on the Home card once level 60 is done, and
  in Settings. Never mid-puzzle, never on launch.

## Billing done right

- One purchase, restorable from Settings ("Restore purchase") and from the
  unlock sheet.
- Refunds go through Apple. A refunded purchase re-locks levels 61 to 300;
  progress and best times are kept.
- Ask to Buy (child accounts) shows "Waiting for approval", and the levels
  open by themselves when it's approved.

## What to create in App Store Connect (you)

| field | value |
| --- | --- |
| Type | Non-Consumable |
| Reference name | All levels |
| Product ID | `napspot.levels.all` (must match `Unlock.productID`) |
| Price | $3.99 USD tier (or your choice) |
| Family Sharing | On |
| Display name / description | "All levels" / "Opens all 300 levels, up to 10x10. One payment, no subscription." |
| Review screenshot | the unlock sheet from the Simulator |

Also: sign the Paid Applications agreement and add tax and banking details,
or the product won't load. Apply for the **App Store Small Business Program**
to pay 15% commission instead of 30%.

Testing before then: the Xcode scheme uses `ios-native/Napspot.storekit`,
so the purchase works in the Simulator with no account.
