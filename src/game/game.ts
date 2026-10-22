import { isSolutionCell, rowOf, colOf, type SolvedPuzzle } from '../../engine';

export const EMPTY = 0;
export const MARK = 1;
export const CAT = 2;
export type CellState = typeof EMPTY | typeof MARK | typeof CAT;

export const START_LIVES = 3;

export type Move = { cell: number; from: CellState; to: CellState };

export type Game = {
  puzzle: SolvedPuzzle;
  cells: CellState[];
  lives: number;
  mistakes: number;
  history: Move[];
  status: 'playing' | 'solved' | 'failed';
  lastMistake: number | null; // cell, for the shake
  hinted: number | null;
};

export type Action =
  | { type: 'tap'; cell: number } // empty -> mark -> cat -> empty
  | { type: 'place'; cell: number } // double-tap
  | { type: 'clear'; cell: number } // long-press
  | { type: 'undo' }
  | { type: 'restart' }
  | { type: 'hint' };

export function newGame(puzzle: SolvedPuzzle): Game {
  return {
    puzzle,
    cells: new Array(puzzle.size * puzzle.size).fill(EMPTY),
    lives: START_LIVES,
    mistakes: 0,
    history: [],
    status: 'playing',
    lastMistake: null,
    hinted: null,
  };
}

function set(g: Game, cell: number, to: CellState): Game {
  const from = g.cells[cell];
  if (from === to) return g;
  const cells = g.cells.slice();
  cells[cell] = to;
  return { ...g, cells, history: [...g.history, { cell, from, to }], lastMistake: null, hinted: g.hinted === cell ? null : g.hinted };
}

// A cat on a cell that is not in the (unique) answer costs a life. The cat
// does not stay: the cell is marked instead, since it can never hold one.
function placeCat(g: Game, cell: number): Game {
  const { size, solution } = g.puzzle;
  if (!isSolutionCell(size, solution, cell)) {
    const lives = g.lives - 1;
    const cells = g.cells.slice();
    cells[cell] = MARK;
    return {
      ...g,
      cells,
      lives,
      mistakes: g.mistakes + 1,
      lastMistake: cell,
      status: lives <= 0 ? 'failed' : 'playing',
    };
  }
  const next = set(g, cell, CAT);
  const cats = next.cells.filter((c) => c === CAT).length;
  return cats === size ? { ...next, status: 'solved', hinted: null } : next;
}

export function reduce(g: Game, a: Action): Game {
  if (a.type === 'restart') return newGame(g.puzzle);
  if (g.status !== 'playing') return g;
  switch (a.type) {
    case 'tap': {
      const now = g.cells[a.cell];
      if (now === EMPTY) return set(g, a.cell, MARK);
      if (now === MARK) return placeCat(g, a.cell);
      return set(g, a.cell, EMPTY);
    }
    case 'place':
      return g.cells[a.cell] === CAT ? g : placeCat(g, a.cell);
    case 'clear':
      return set(g, a.cell, EMPTY);
    case 'undo': {
      const last = g.history[g.history.length - 1];
      if (!last) return g;
      const cells = g.cells.slice();
      cells[last.cell] = last.from;
      return { ...g, cells, history: g.history.slice(0, -1), lastMistake: null };
    }
    case 'hint':
      return { ...g, hinted: nextHint(g) };
  }
}

// Points at the answer cell in the most squeezed row, column or region: the
// one a player is closest to working out. (A full "why" explanation is a
// should-have; see build-log.)
export function nextHint(g: Game): number | null {
  const { size, regions, solution } = g.puzzle;
  let best: number | null = null;
  let bestOpen = Infinity;
  solution.forEach((c, r) => {
    const cell = r * size + c;
    if (g.cells[cell] === CAT) return;
    const open = (pred: (i: number) => boolean) =>
      g.cells.reduce<number>((n, v, i) => (pred(i) && v === EMPTY ? n + 1 : n), 0);
    const tightest = Math.min(
      open((i) => rowOf(size, i) === r),
      open((i) => colOf(size, i) === c),
      open((i) => regions[i] === regions[cell]),
    );
    if (tightest < bestOpen) {
      bestOpen = tightest;
      best = cell;
    }
  });
  return best;
}

export function catCount(g: Game): number {
  return g.cells.filter((c) => c === CAT).length;
}
