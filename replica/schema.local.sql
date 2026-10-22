-- On-device schema (expo-sqlite via Drizzle). Single user, no auth, works offline.
-- Times are ms since epoch (UTC). Board state is JSON: number[] per cell
-- (0 empty, 1 X mark, 2 cat).

create table attempts (
  id text primary key,                       -- uuid
  kind text not null check (kind in ('level','daily','tutorial')),
  puzzle_key text not null,                  -- level number or YYYY-MM-DD
  board_size integer not null check (board_size between 5 and 10),
  cells text not null,                       -- JSON board state
  history text not null default '[]',        -- JSON moves, for undo
  lives integer not null default 3 check (lives between 0 and 3),
  mistakes integer not null default 0,
  elapsed_ms integer not null default 0,     -- paused while backgrounded
  status text not null default 'in_progress'
    check (status in ('in_progress','solved','failed')),
  created_at integer not null,
  updated_at integer not null
);
-- one live attempt per puzzle; a retry replaces it
create unique index attempts_live on attempts (kind, puzzle_key) where status = 'in_progress';

create table level_progress (
  level_no integer primary key,
  best_ms integer,
  solves integer not null default 0,
  first_solved_at integer
);

create table daily_progress (
  puzzle_date text primary key,              -- local YYYY-MM-DD
  status text not null check (status in ('solved','failed')),
  time_ms integer,
  mistakes integer not null,
  cells text,                                -- final board, re-sent if submit failed
  submitted integer not null default 0       -- 0 = queued for the leaderboard
);

create table kv (                            -- settings, hints_left, streak, flags
  key text primary key,
  value text not null
);
