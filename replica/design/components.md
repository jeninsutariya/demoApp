# Components: cat logic puzzle clone

Proposed system, not measured from the original: its screenshots could not be
fetched in the recon. Re-check sizes against `replica/screens/` once you add
them. Tokens: `tokens.json` (`bg-surface`, `text-muted`, `rounded-md`...). Never
raw hex in a component.

**Assets, all our own or open:**
- Icons: Lucide (ISC licence): `cat` (placeholder token only), `heart`,
  `x`, `undo-2`, `rotate-ccw`, `lightbulb`, `trophy`, `settings`, `calendar`,
  `lock`, `check`.
- Cat art: commission or draw your own (idle, placed, wrong, celebrating).
  Until then, Lucide `cat` in `cat` colour. Never trace the original's cats.
- Lives icon: Lucide `heart` for now; `/replica-brand` can pick a signature
  (not the original's fish crackers).
- Font: Nunito (SIL OFL), loaded with expo-font. Tabular numbers for the timer
  and leaderboard.
- Sounds: your own or CC0 (e.g. Kenney). Never the original's.
- Copy: every label below is written fresh.

## Board

```
Board
  sizes     5x5 .. 10x10. Board width = min(screen - 2*gutter, board-max 480).
            cell = width / N. Below cell-min-touch (44pt), enable pinch-zoom
            (1x..2x) and a "zoom to region" double-tap on empty space
  states    idle, in-progress, mistake (shake: motion-shake), solved
            (cat cascade: motion-stagger per cat, then modal), failed (dim 40%)
  tokens    radius lg outer, region-edge border-region (3) between regions,
            grid-line border-grid (1) inside a region, shadow card
  a11y      accessibilityRole "grid"; announces "Row 3, column 5, peach region,
            empty". Switch Control and VoiceOver move cell by cell; the
            actions are Place cat, Mark, Clear
  used on   S03, S07, S12 (tutorial mini board)
```

## RegionCell

```
RegionCell
  variants  region-1 .. region-10 fill; pattern overlay when Settings >
            "Region patterns" is on (dots, stripes, checks, waves, cross...
            one per region) because colour alone fails for colour-blind
            players (measured: deutan min dE 0.4 between region-6 and region-8)
  states    empty, marked (X in mark), cat, mistake (cat in danger + 2px danger
            ring, then the cat is removed), hinted (accent ring, pulse once),
            focused (border-focus 3px accent ring), locked (solved board)
  input     tap = cycle empty -> X -> cat -> empty (default, setting:
            "Tap places cat first"). Double-tap = cat. Long-press = clear.
            Drag across cells = mark X on each (fast elimination)
  tokens    region fill, cat/mark colours, radius cell, motion-place spring
  a11y      every state in the label; mistake is announced, not just shown
  used on   S03, S07, S12
```

Note: the original's control (double-tap to place) is confirmed; the tap
cycle and drag-to-mark are our choices. Confirm feel in the vertical slice.

## Cat

```
Cat
  variants  idle, placed (scale 0.6 -> 1, motion-place), wrong (danger tint,
            wobble), celebrating (hop, solved cascade)
  tokens    cat colour; size = 72% of the cell
  a11y      decorative image; the cell carries the label
  used on   S03, S06, S12
```

## LivesBar

```
LivesBar
  variants  3 icons
  states    full, losing (icon pops and greys, motion-base, haptic warning),
            last life (remaining icon pulses slowly), empty
  tokens    danger for live icons, border for lost ones, space 4 between
  a11y      "2 of 3 lives left", announced on change
  used on   S03, S07
```

## Timer

```
Timer
  states    running, paused (app backgrounded or a modal open), stopped
  tokens    type sm/600, tabular numbers, text-muted
  a11y      not announced live (noise); read on focus. Setting: "Hide timer"
  used on   S03, S06, S07
```

## TopBar (puzzle)

```
TopBar
  contains  back, title (Level 12 / Daily · 22 Oct), Timer, LivesBar
  height    layout header 56
  used on   S03, S07
```

## Toolbar (puzzle)

```
ToolButton
  variants  undo, restart, hint (with count badge), mode toggle (cat / X)
  sizes     48pt square, icon 24
  states    default, pressed (scale .96), disabled (undo with no history;
            hint at 0 -> shows "get more"), badge
  tokens    bg surface, text text, radius md, shadow card
  a11y      label + hint count ("Hint, 2 left")
  used on   S03, S07
```

## Button

```
Button
  variants  primary (bg accent / on-accent), secondary (bg surface, border),
            ghost (text accent), danger (bg danger / on-accent)
  sizes     md 44pt, lg 52pt (modal actions); full-width in modals
  states    default, pressed, focus-visible (3px accent ring), disabled (40%),
            loading (spinner, label kept for screen readers)
  tokens    radius pill, type base/700
  a11y      role button, label always text
  used on   S01, S05, S06, S08, S09, S11, S12
```

## ModeCard

```
ModeCard
  variants  daily (date, streak, "done" check), levels (next level number, size)
  states    default, pressed, done-today (daily), loading (generating daily)
  tokens    bg surface, radius lg, shadow card, padding 16 / 24
  used on   S01
```

## LevelTile

```
LevelTile
  variants  by board size (small label "6x6")
  states    locked (lock icon, text-muted), open (accent border), solved
            (check + best time), current (pulsing accent ring)
  layout    4 per row on phone, 6 on tablet, gap 8
  a11y      "Level 12, 6 by 6, solved in 1:42"
  used on   S02
```

## Modal

```
Modal
  variants  win (cat celebrating, time, best, mistakes, Next / Share / Leaderboard
            for daily), fail ("Out of lives", Retry, optional "Watch ad for a
            life" only if ads are kept), hint (spend / get more), confirm
            (restart?)
  states    entering (fade + rise, motion-base), shown, leaving
  tokens    bg surface, radius lg, shadow pop, scrim text at 40%
  a11y      focus moves into the modal and returns after; Escape/back closes
            non-blocking modals
  used on   S05, S06, S09
```

## LeaderboardRow

```
LeaderboardRow
  variants  top-3 (rank badge), normal, you (accent-tinted bg, pinned at bottom
            when you are outside the top 50)
  states    loading (skeleton x8), empty ("Be the first today"), offline
            ("Your time is saved and will be sent when you're online"), error
  tokens    type sm, tabular numbers, border bottom
  used on   S08
```

## Settings rows

```
ToggleRow   label + Switch (system). Sound, Haptics, Hide timer, Region
            patterns, Tap places cat first
LinkRow     How to play, Restore purchase, Privacy, Delete my leaderboard
            account (danger, confirm modal)
  used on   S11
```

## RuleCard (how to play)

```
RuleCard
  content   mini board animation + one sentence per rule (one per row/column,
            one per colour, no touching, 3 lives); our own words
  states    1 of 4 .. 4 of 4, pager dots
  used on   S12
```

## Toast

```
Toast
  variants  info (surface), success, danger
  use       "Saved offline", "Time submitted, #12 today"
  a11y      announced politely; never the only signal for a mistake
```

## Motion and haptics

- Place cat: spring scale, light haptic. Mark X: no haptic. Mistake: shake
  `motion-shake` plus warning haptic. Solve: cascade plus success haptic.
- `prefers-reduced-motion` / iOS Reduce Motion: no shake or cascade; use a
  colour flash and a static modal instead.

## Not covered yet

- Dark mode (could): add a `dark` token set; the regions need their own darker
  set and a new contrast run.
- Tablet layout: board-max goes to 640 and the toolbar moves to the side.
