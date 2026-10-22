import type { Puzzle, Solution } from './types';

export const cellOf = (size: number, r: number, c: number) => r * size + c;
export const rowOf = (size: number, cell: number) => Math.floor(cell / size);
export const colOf = (size: number, cell: number) => cell % size;

// The 8 cells around a cell
export function neighbours(size: number, cell: number): number[] {
  const r = rowOf(size, cell);
  const c = colOf(size, cell);
  const out: number[] = [];
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      if (dr === 0 && dc === 0) continue;
      const rr = r + dr;
      const cc = c + dc;
      if (rr >= 0 && rr < size && cc >= 0 && cc < size) out.push(cellOf(size, rr, cc));
    }
  }
  return out;
}

export function solutionCells(size: number, solution: Solution): number[] {
  return solution.map((c, r) => cellOf(size, r, c));
}

export function isSolutionCell(size: number, solution: Solution, cell: number): boolean {
  return solution[rowOf(size, cell)] === colOf(size, cell);
}

// Do these cats satisfy every rule? (Used by the server and the win check.)
export function isValidSolution(puzzle: Puzzle, cats: number[]): boolean {
  const { size, regions } = puzzle;
  if (cats.length !== size) return false;
  const rows = new Set<number>();
  const cols = new Set<number>();
  const regs = new Set<number>();
  for (const cell of cats) {
    if (cell < 0 || cell >= size * size) return false;
    rows.add(rowOf(size, cell));
    cols.add(colOf(size, cell));
    regs.add(regions[cell]);
  }
  if (rows.size !== size || cols.size !== size || regs.size !== size) return false;
  const set = new Set(cats);
  return cats.every((cell) => neighbours(size, cell).every((n) => !set.has(n)));
}

// Every region must be one connected piece (4-neighbour).
export function regionsConnected(puzzle: Puzzle): boolean {
  const { size, regions } = puzzle;
  for (let g = 0; g < size; g++) {
    const cells = regions.map((v, i) => (v === g ? i : -1)).filter((i) => i >= 0);
    if (cells.length === 0) return false;
    const seen = new Set([cells[0]]);
    const stack = [cells[0]];
    while (stack.length) {
      const cell = stack.pop()!;
      for (const n of orthogonal(size, cell)) {
        if (regions[n] === g && !seen.has(n)) {
          seen.add(n);
          stack.push(n);
        }
      }
    }
    if (seen.size !== cells.length) return false;
  }
  return true;
}

export function orthogonal(size: number, cell: number): number[] {
  const r = rowOf(size, cell);
  const c = colOf(size, cell);
  const out: number[] = [];
  if (r > 0) out.push(cell - size);
  if (r < size - 1) out.push(cell + size);
  if (c > 0) out.push(cell - 1);
  if (c < size - 1) out.push(cell + 1);
  return out;
}
