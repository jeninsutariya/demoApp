import { colOf, neighbours, rowOf } from './rules';
import type { Difficulty, Puzzle } from './types';

// Solves the way a person would, with no guessing, and returns the hardest
// technique it needed:
// 1 easy    a row, column or region has one place left
// 2 medium  a cell would empty some row, column or region (one-step lookahead)
// 3 hard    k regions squeezed into k rows or columns (and the reverse), k <= 4
// 4 expert  none of the above finish it; the solution is still unique

type State = { cand: boolean[]; cats: Set<number> };

function units(p: Puzzle): number[][] {
  const { size, regions } = p;
  const rows: number[][] = [];
  const cols: number[][] = [];
  const regs: number[][] = [];
  for (let i = 0; i < size; i++) {
    rows.push([]);
    cols.push([]);
    regs.push([]);
  }
  for (let cell = 0; cell < size * size; cell++) {
    rows[rowOf(size, cell)].push(cell);
    cols[colOf(size, cell)].push(cell);
    regs[regions[cell]].push(cell);
  }
  return [...rows, ...cols, ...regs];
}

function place(p: Puzzle, s: State, cell: number): void {
  const { size, regions } = p;
  s.cats.add(cell);
  const r = rowOf(size, cell);
  const c = colOf(size, cell);
  for (let i = 0; i < size * size; i++) {
    if (i !== cell && (rowOf(size, i) === r || colOf(size, i) === c || regions[i] === regions[cell])) {
      s.cand[i] = false;
    }
  }
  for (const n of neighbours(size, cell)) s.cand[n] = false;
}

// Cells a cat at `cell` would rule out
function blocked(p: Puzzle, cell: number): Set<number> {
  const { size, regions } = p;
  const out = new Set<number>(neighbours(size, cell));
  for (let i = 0; i < size * size; i++) {
    if (i !== cell && (rowOf(size, i) === rowOf(size, cell) || colOf(size, i) === colOf(size, cell) || regions[i] === regions[cell])) {
      out.add(i);
    }
  }
  return out;
}

function singles(p: Puzzle, s: State, all: number[][]): boolean {
  for (const u of all) {
    if (u.some((cell) => s.cats.has(cell))) continue;
    const open = u.filter((cell) => s.cand[cell]);
    if (open.length === 1) {
      place(p, s, open[0]);
      return true;
    }
  }
  return false;
}

function lookahead(p: Puzzle, s: State, all: number[][]): boolean {
  const open = all.filter((u) => !u.some((cell) => s.cats.has(cell)));
  for (let cell = 0; cell < p.size * p.size; cell++) {
    if (!s.cand[cell] || s.cats.has(cell)) continue;
    const gone = blocked(p, cell);
    const empties = open.some((u) => !u.includes(cell) && u.every((x) => !s.cand[x] || gone.has(x)));
    if (empties) {
      s.cand[cell] = false;
      return true;
    }
  }
  return false;
}

function combos(n: number, k: number): number[][] {
  const out: number[][] = [];
  const pick: number[] = [];
  const go = (start: number) => {
    if (pick.length === k) {
      out.push(pick.slice());
      return;
    }
    for (let i = start; i < n; i++) {
      pick.push(i);
      go(i + 1);
      pick.pop();
    }
  };
  go(0);
  return out;
}

// k groups whose open cells all fall inside k lines: those lines belong to
// them, so every other open cell in those lines goes. Run both ways round:
// regions into rows/columns and rows/columns into regions.
function subsets(p: Puzzle, s: State): boolean {
  const { size, regions } = p;
  const key = {
    row: (cell: number) => rowOf(size, cell),
    col: (cell: number) => colOf(size, cell),
    reg: (cell: number) => regions[cell],
  };
  const pairs: [keyof typeof key, keyof typeof key][] = [
    ['reg', 'row'], ['reg', 'col'], ['row', 'reg'], ['col', 'reg'],
  ];
  const openCells = [...Array(size * size).keys()].filter((c) => s.cand[c] && !s.cats.has(c));
  for (const [groupBy, lineBy] of pairs) {
    const groups = new Map<number, number[]>();
    for (const cell of openCells) {
      const g = key[groupBy](cell);
      if (!groups.has(g)) groups.set(g, []);
      groups.get(g)!.push(cell);
    }
    const ids = [...groups.keys()];
    for (let k = 1; k <= Math.min(4, ids.length - 1); k++) {
      for (const pick of combos(ids.length, k)) {
        const chosen = new Set(pick.map((i) => ids[i]));
        const lines = new Set<number>();
        for (const g of chosen) for (const cell of groups.get(g)!) lines.add(key[lineBy](cell));
        if (lines.size !== k) continue;
        let changed = false;
        for (const cell of openCells) {
          if (lines.has(key[lineBy](cell)) && !chosen.has(key[groupBy](cell)) && s.cand[cell]) {
            s.cand[cell] = false;
            changed = true;
          }
        }
        if (changed) return true;
      }
    }
  }
  return false;
}

export function grade(p: Puzzle): Difficulty {
  const s: State = { cand: new Array(p.size * p.size).fill(true), cats: new Set() };
  const all = units(p);
  let hardest: Difficulty = 1;
  while (s.cats.size < p.size) {
    if (singles(p, s, all)) continue;
    if (lookahead(p, s, all)) {
      hardest = Math.max(hardest, 2) as Difficulty;
      continue;
    }
    if (subsets(p, s)) {
      hardest = Math.max(hardest, 3) as Difficulty;
      continue;
    }
    return 4;
  }
  return hardest;
}
