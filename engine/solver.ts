import type { Puzzle, Solution } from './types';

// Backtracking, one row at a time. Cats in different rows only touch when
// they are in consecutive rows and their columns differ by at most one.
// Stops after `limit` solutions: the generator only needs to know 0, 1 or "more".
export function findSolutions(puzzle: Puzzle, limit = 2): Solution[] {
  const { size, regions } = puzzle;
  const found: Solution[] = [];
  const cols = new Array<boolean>(size).fill(false);
  const regs = new Array<boolean>(size).fill(false);
  const pick: number[] = [];

  const step = (r: number): void => {
    if (found.length >= limit) return;
    if (r === size) {
      found.push(pick.slice());
      return;
    }
    for (let c = 0; c < size; c++) {
      if (cols[c]) continue;
      if (r > 0 && Math.abs(pick[r - 1] - c) <= 1) continue;
      const g = regions[r * size + c];
      if (regs[g]) continue;
      cols[c] = regs[g] = true;
      pick.push(c);
      step(r + 1);
      pick.pop();
      cols[c] = regs[g] = false;
      if (found.length >= limit) return;
    }
  };
  step(0);
  return found;
}

export function countSolutions(puzzle: Puzzle, limit = 2): number {
  return findSolutions(puzzle, limit).length;
}
