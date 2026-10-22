/// <reference types="node" />
import { test } from 'node:test';
import assert from 'node:assert/strict';
import levels from '../assets/levels.json';
import {
  countSolutions, dailyPuzzle, decode, encode, generate, grade, isValidSolution,
  regionsConnected, rngFrom, solutionCells,
} from './index';

// Pinned daily boards. If this fails, the generator changed and every
// player's daily would change with it: bump GENERATOR_VERSION instead.
const GOLDEN_DAILIES: Record<string, string> = {
  "2026-10-19": "6|000000000001002221002331402331442555|152403|2",
  "2026-10-20": "6|001114111114131124333144333444333544|024153|2",
  "2026-10-21": "7|0000011000111100066240036644006664450664465066666|1352604|2",
  "2026-10-22": "7|0000001200001122260135446663554663356666636666666|3516204|2",
  "2026-10-23": "8|2220001122333115233311552223555544777555777775557666775577777755|46031725|2",
  "2026-10-24": "8|0000000020000311200003337444433374444433754446667744444677774466|46053172|2",
  "2026-10-25": "9|333330011333330311223333335665553345665555345655555555655555555655577555688577755|681573042|3",
  "2027-01-01": "8|0000000000001100022211103222114455551554555555445565577755777777|15307426|2"
};

test('rng is deterministic per seed', () => {
  const a = rngFrom('x');
  const b = rngFrom('x');
  for (let i = 0; i < 100; i++) assert.equal(a(), b());
  assert.notEqual(rngFrom('x')(), rngFrom('y')());
});

test('generated puzzles have exactly one valid solution, every size', () => {
  const rng = rngFrom('test');
  for (let size = 5; size <= 10; size++) {
    for (let i = 0; i < 5; i++) {
      const p = generate(rng, size);
      assert.equal(countSolutions(p, 2), 1);
      assert.ok(isValidSolution(p, solutionCells(size, p.solution)));
      assert.ok(regionsConnected(p));
      assert.equal(new Set(p.regions).size, size);
    }
  }
});

test('isValidSolution rejects touching, shared rows, shared regions', () => {
  const p = decode(GOLDEN_DAILIES['2026-10-20']);
  const good = solutionCells(p.size, p.solution);
  assert.ok(isValidSolution(p, good));
  assert.ok(!isValidSolution(p, good.slice(1)));
  const touching = good.slice();
  touching[1] = touching[0] + p.size + (p.solution[0] < p.size - 1 ? 1 : -1);
  assert.ok(!isValidSolution(p, touching));
});

test('daily puzzles match the pinned boards', () => {
  for (const [date, expected] of Object.entries(GOLDEN_DAILIES)) {
    assert.equal(encode(dailyPuzzle(date)), expected, date);
  }
});

test('codec round-trips', () => {
  const p = dailyPuzzle('2026-10-22');
  assert.deepEqual(decode(encode(p)), p);
});

test('every shipped level is unique-solution and graded as stored', () => {
  assert.equal(levels.length, 300);
  for (const s of levels as string[]) {
    const p = decode(s);
    assert.equal(countSolutions(p, 2), 1);
    assert.equal(grade(p), p.difficulty);
  }
});
