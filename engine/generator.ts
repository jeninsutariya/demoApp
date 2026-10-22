import { randInt, rngFrom, shuffle, type Rng } from './rng';
import { cellOf, orthogonal, regionsConnected } from './rules';
import { findSolutions } from './solver';
import { grade } from './grader';
import { MAX_SIZE, MIN_SIZE, type Difficulty, type Puzzle, type Solution, type SolvedPuzzle } from './types';

// Changing anything in this file changes every daily puzzle. Bump this and the
// seed prefix in daily.ts together, never one without the other.
export const GENERATOR_VERSION = 1;

// A random column per row with no two cats touching.
function randomSolution(rng: Rng, size: number): Solution {
  const used = new Array<boolean>(size).fill(false);
  const pick: number[] = [];
  const step = (r: number): boolean => {
    if (r === size) return true;
    for (const c of shuffle(rng, [...Array(size).keys()])) {
      if (used[c] || (r > 0 && Math.abs(pick[r - 1] - c) <= 1)) continue;
      used[c] = true;
      pick.push(c);
      if (step(r + 1)) return true;
      pick.pop();
      used[c] = false;
    }
    return false;
  };
  step(0);
  return pick;
}

// Grow one region from each cat until the board is covered.
function growRegions(rng: Rng, size: number, solution: Solution): number[] {
  const regions = new Array<number>(size * size).fill(-1);
  const frontier: number[] = [];
  solution.forEach((c, r) => {
    const cell = cellOf(size, r, c);
    regions[cell] = r;
    frontier.push(cell);
  });
  let left = size * size - size;
  while (left > 0) {
    const i = randInt(rng, frontier.length);
    const from = frontier[i];
    const open = orthogonal(size, from).filter((n) => regions[n] === -1);
    if (open.length === 0) {
      frontier.splice(i, 1);
      continue;
    }
    const to = open[randInt(rng, open.length)];
    regions[to] = regions[from];
    frontier.push(to);
    left--;
  }
  return regions;
}

// Kill a second solution by moving one of its cats into a neighbouring region.
// The real answer's cats never move, so it stays valid.
function breakAlternative(rng: Rng, puzzle: Puzzle, real: Solution, alt: Solution): boolean {
  const { size, regions } = puzzle;
  const realCells = new Set(real.map((c, r) => cellOf(size, r, c)));
  const altCells = shuffle(
    rng,
    alt.map((c, r) => cellOf(size, r, c)).filter((cell) => !realCells.has(cell)),
  );
  for (const cell of altCells) {
    const from = regions[cell];
    for (const n of shuffle(rng, orthogonal(size, cell))) {
      const to = regions[n];
      if (to === from) continue;
      regions[cell] = to;
      if (regionsConnected(puzzle)) return true;
      regions[cell] = from;
    }
  }
  return false;
}

export function generate(rng: Rng, size: number, maxAttempts = 200): SolvedPuzzle {
  if (size < MIN_SIZE || size > MAX_SIZE) throw new Error(`size ${size} out of range`);
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const solution = randomSolution(rng, size);
    const puzzle: Puzzle = { size, regions: growRegions(rng, size, solution) };
    for (let fix = 0; fix < size * size; fix++) {
      const found = findSolutions(puzzle, 2);
      if (found.length === 1) {
        return { ...puzzle, solution, difficulty: grade(puzzle) };
      }
      const alt = found.find((s) => s.some((c, r) => c !== solution[r]));
      if (!alt || !breakAlternative(rng, puzzle, solution, alt)) break;
    }
  }
  throw new Error(`no unique ${size}x${size} puzzle after ${maxAttempts} attempts`);
}

// Keep generating from one seed until the difficulty is in range.
export function generateWithDifficulty(
  seed: string,
  size: number,
  min: Difficulty,
  max: Difficulty,
  maxTries = 60,
): SolvedPuzzle {
  const rng = rngFrom(seed);
  let last: SolvedPuzzle | null = null;
  for (let i = 0; i < maxTries; i++) {
    last = generate(rng, size);
    if (last.difficulty >= min && last.difficulty <= max) return last;
  }
  return last!;
}
