/// <reference types="node" />
// Builds assets/levels.json (and the iOS copy): 300 levels from 5x5 to 10x10, getting harder.
// Levels are fixed once shipped (best times depend on them), so this only
// runs when you mean to change the level pack.
//   npx tsx scripts/gen-levels.ts
import { writeFileSync } from 'node:fs';
import { encode, generateWithDifficulty, type Difficulty } from '../engine';

const BANDS: { size: number; count: number; ramp: [Difficulty, Difficulty][] }[] = [
  { size: 5, count: 20, ramp: [[1, 1], [1, 2], [2, 2]] },
  { size: 6, count: 40, ramp: [[1, 2], [2, 2], [2, 3]] },
  { size: 7, count: 50, ramp: [[1, 2], [2, 2], [2, 3]] },
  { size: 8, count: 60, ramp: [[2, 2], [2, 3], [3, 3]] },
  { size: 9, count: 70, ramp: [[2, 2], [2, 3], [3, 3]] },
  { size: 10, count: 60, ramp: [[2, 3], [3, 3], [3, 4]] },
];

const levels: string[] = [];
for (const band of BANDS) {
  for (let i = 0; i < band.count; i++) {
    const [min, max] = band.ramp[Math.min(band.ramp.length - 1, Math.floor((i / band.count) * band.ramp.length))];
    levels.push(encode(generateWithDifficulty(`level-v1:${levels.length + 1}`, band.size, min, max)));
  }
}
// The native iOS app ships the same pack inside CatLogicKit
for (const out of ['../assets/levels.json', '../ios-native/CatLogicKit/Sources/CatLogicKit/Resources/levels.json']) {
  writeFileSync(new URL(out, import.meta.url), JSON.stringify(levels) + '\n');
}
console.log(`wrote ${levels.length} levels`);
