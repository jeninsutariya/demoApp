import { dailyPuzzle, decode, type SolvedPuzzle } from '../../engine';
import levelPack from '../../assets/levels.json';

export const LEVELS = (levelPack as string[]).map(decode);
export const LEVEL_COUNT = LEVELS.length;

export function levelPuzzle(n: number): SolvedPuzzle | null {
  return Number.isInteger(n) && n >= 1 && n <= LEVEL_COUNT ? LEVELS[n - 1] : null;
}

const dailyCache = new Map<string, SolvedPuzzle>();
export function cachedDaily(date: string): SolvedPuzzle {
  if (!dailyCache.has(date)) dailyCache.set(date, dailyPuzzle(date));
  return dailyCache.get(date)!;
}
