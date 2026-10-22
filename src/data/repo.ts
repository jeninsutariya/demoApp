import AsyncStorage from '@react-native-async-storage/async-storage';
import { DEFAULT_SETTINGS, type DailyRecord, type GameRepo, type LevelRecord, type PuzzleKind, type SavedAttempt, type Settings } from './types';

const START_HINTS = 3;

async function read<T>(key: string, fallback: T): Promise<T> {
  try {
    const raw = await AsyncStorage.getItem(key);
    return raw == null ? fallback : (JSON.parse(raw) as T);
  } catch {
    return fallback;
  }
}

const write = (key: string, value: unknown) => AsyncStorage.setItem(key, JSON.stringify(value));

const attemptKey = (kind: PuzzleKind, key: string) => `attempt:${kind}:${key}`;

function previousDay(date: string): string {
  const [y, m, d] = date.split('-').map(Number);
  const t = new Date(Date.UTC(y, m - 1, d - 1));
  return t.toISOString().slice(0, 10);
}

export const repo: GameRepo = {
  async getSettings() {
    return { ...DEFAULT_SETTINGS, ...(await read<Partial<Settings>>('settings', {})) };
  },
  saveSettings: (s) => write('settings', s),
  getFlag: (name) => read(`flag:${name}`, false),
  setFlag: (name, on) => write(`flag:${name}`, on),

  loadAttempt: (kind, key) => read<SavedAttempt | null>(attemptKey(kind, key), null),
  saveAttempt: (a) => write(attemptKey(a.kind, a.key), a),
  clearAttempt: (kind, key) => AsyncStorage.removeItem(attemptKey(kind, key)),

  getLevels: () => read<Record<number, LevelRecord>>('levels', {}),
  async recordLevelSolve(level, ms) {
    const all = await read<Record<number, LevelRecord>>('levels', {});
    const was = all[level];
    const rec = { bestMs: was ? Math.min(was.bestMs, ms) : ms, solves: (was?.solves ?? 0) + 1 };
    await write('levels', { ...all, [level]: rec });
    return rec;
  },

  getDaily: (date) => read<DailyRecord | null>(`daily:${date}`, null),
  recordDaily: (rec) => write(`daily:${rec.date}`, rec),
  async dailyStreak(today) {
    let streak = 0;
    let day = today;
    // today counts if solved; an unsolved today does not break yesterday's run
    const t = await read<DailyRecord | null>(`daily:${day}`, null);
    if (t?.status === 'solved') streak++;
    for (;;) {
      day = previousDay(day);
      const rec = await read<DailyRecord | null>(`daily:${day}`, null);
      if (rec?.status !== 'solved') return streak;
      streak++;
    }
  },

  getHints: () => read('hints', START_HINTS),
  async addHints(n) {
    const left = Math.max(0, (await read('hints', START_HINTS)) + n);
    await write('hints', left);
    return left;
  },
};
