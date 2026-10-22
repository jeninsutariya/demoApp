// A puzzle is an N x N board split into N regions. Cells are row-major
// indexes (r * size + c). The answer has exactly one cat per row, column and
// region, and no two cats touch, diagonals included.

export type Puzzle = {
  size: number;
  regions: number[]; // region id 0..size-1 for every cell
};

// solution[r] = column of the cat in row r
export type Solution = number[];

export type SolvedPuzzle = Puzzle & {
  solution: Solution;
  difficulty: Difficulty;
};

export type Difficulty = 1 | 2 | 3 | 4; // easy, medium, hard, expert

export const MIN_SIZE = 5;
export const MAX_SIZE = 10;
