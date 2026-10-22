import type { Difficulty, SolvedPuzzle } from './types';

// Compact form for levels.json: regions as one digit per cell, solution as
// one digit per row. "6|001112...|135024|2"
export function encode(p: SolvedPuzzle): string {
  return `${p.size}|${p.regions.join('')}|${p.solution.join('')}|${p.difficulty}`;
}

export function decode(s: string): SolvedPuzzle {
  const [size, regions, solution, difficulty] = s.split('|');
  return {
    size: Number(size),
    regions: [...regions].map(Number),
    solution: [...solution].map(Number),
    difficulty: Number(difficulty) as Difficulty,
  };
}
