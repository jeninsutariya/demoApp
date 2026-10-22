import { generateWithDifficulty, GENERATOR_VERSION } from './generator';
import type { Difficulty, SolvedPuzzle } from './types';

// The daily puzzle is a pure function of the player's local date, so it works
// offline and the server can rebuild it to check a submitted time.
export const DAILY_SEED_PREFIX = `daily-v${GENERATOR_VERSION}`;

// Mon..Sun get bigger and harder (getDay(): Sun = 0)
const BY_WEEKDAY: { size: number; min: Difficulty; max: Difficulty }[] = [
  { size: 9, min: 3, max: 3 }, // Sun
  { size: 6, min: 1, max: 2 }, // Mon
  { size: 6, min: 2, max: 2 }, // Tue
  { size: 7, min: 2, max: 2 }, // Wed
  { size: 7, min: 2, max: 3 }, // Thu
  { size: 8, min: 2, max: 2 }, // Fri
  { size: 8, min: 2, max: 3 }, // Sat
];

export function isDateKey(key: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(key);
}

export function localDateKey(d = new Date()): string {
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${m}-${day}`;
}

export function dailyPuzzle(dateKey: string): SolvedPuzzle {
  if (!isDateKey(dateKey)) throw new Error(`bad date ${dateKey}`);
  const [y, m, d] = dateKey.split('-').map(Number);
  const weekday = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  const spec = BY_WEEKDAY[weekday];
  return generateWithDifficulty(`${DAILY_SEED_PREFIX}:${dateKey}`, spec.size, spec.min, spec.max);
}
