import { rngFrom } from '../../engine';
import type { LeaderboardApi, LeaderboardRow } from './types';

// SAMPLE leaderboard until /replica-backend connects Supabase. The other
// players are generated from the date and the screen says so; nothing here
// pretends to be real players.
const SAMPLE_PLAYERS = 40;

function sampleTimes(date: string): number[] {
  const rng = rngFrom(`sample-board:${date}`);
  return Array.from({ length: SAMPLE_PLAYERS }, () => Math.round(60_000 + rng() * rng() * 600_000)).sort((a, b) => a - b);
}

export const leaderboard: LeaderboardApi = {
  async submitDaily({ date, timeMs }) {
    const times = sampleTimes(date);
    const rank = times.filter((t) => t < timeMs).length + 1;
    return { rank, total: times.length + 1 };
  },

  async getDaily(date, myTimeMs) {
    const times = sampleTimes(date);
    const rows: LeaderboardRow[] = times.map((t, i) => ({ rank: i + 1, name: `Sample player ${i + 1}`, timeMs: t, isMe: false }));
    if (myTimeMs != null) {
      rows.push({ rank: 0, name: await this.myName(), timeMs: myTimeMs, isMe: true });
      rows.sort((a, b) => a.timeMs - b.timeMs);
      rows.forEach((r, i) => (r.rank = i + 1));
    }
    return { state: 'ok', rows, total: rows.length, sample: true };
  },

  async myName() {
    return 'You';
  },

  async deleteMe() {
    // nothing stored remotely yet
  },
};
