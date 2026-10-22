import type { CellState, Move } from '../game/game';

export type PuzzleKind = 'level' | 'daily';

export type Settings = {
  sound: boolean;
  haptics: boolean;
  hideTimer: boolean;
  regionPatterns: boolean;
};

export const DEFAULT_SETTINGS: Settings = {
  sound: true,
  haptics: true,
  hideTimer: false,
  regionPatterns: false,
};

export type SavedAttempt = {
  kind: PuzzleKind;
  key: string; // level number or YYYY-MM-DD
  cells: CellState[];
  history: Move[];
  lives: number;
  mistakes: number;
  elapsedMs: number;
};

export type LevelRecord = { bestMs: number; solves: number };

export type DailyRecord = {
  date: string;
  status: 'solved' | 'failed';
  timeMs: number;
  mistakes: number;
  submitted: boolean;
};

export type LeaderboardRow = { rank: number; name: string; timeMs: number; isMe: boolean };

export type LeaderboardResult =
  | { state: 'ok'; rows: LeaderboardRow[]; total: number; sample: boolean }
  | { state: 'offline' }
  | { state: 'error'; message: string };

// What the screens use. The build ships an AsyncStorage version (repo.ts);
// /replica-backend swaps in expo-sqlite (schema.local.sql) behind the same calls.
export interface GameRepo {
  getSettings(): Promise<Settings>;
  saveSettings(s: Settings): Promise<void>;
  getFlag(name: string): Promise<boolean>;
  setFlag(name: string, on: boolean): Promise<void>;

  loadAttempt(kind: PuzzleKind, key: string): Promise<SavedAttempt | null>;
  saveAttempt(a: SavedAttempt): Promise<void>;
  clearAttempt(kind: PuzzleKind, key: string): Promise<void>;

  getLevels(): Promise<Record<number, LevelRecord>>;
  recordLevelSolve(level: number, ms: number): Promise<LevelRecord>;

  getDaily(date: string): Promise<DailyRecord | null>;
  recordDaily(rec: DailyRecord): Promise<void>;
  dailyStreak(today: string): Promise<number>;

  getHints(): Promise<number>;
  addHints(n: number): Promise<number>;
}

// The leaderboard. /replica-backend swaps the sample version for Supabase.
export interface LeaderboardApi {
  submitDaily(input: { date: string; cats: number[]; timeMs: number; mistakes: number }): Promise<{ rank: number; total: number } | null>;
  getDaily(date: string, myTimeMs: number | null): Promise<LeaderboardResult>;
  myName(): Promise<string>;
  deleteMe(): Promise<void>;
}
