/// <reference types="node" />
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { dailyPuzzle } from '../../engine';
import { CAT, MARK, EMPTY, newGame, reduce } from './game';

const p = dailyPuzzle('2026-10-20');
const right = (r: number) => r * p.size + p.solution[r];
const wrong = (r: number) => r * p.size + ((p.solution[r] + 2) % p.size);

test('tap cycles empty, mark, cat, empty', () => {
  let g = newGame(p);
  g = reduce(g, { type: 'tap', cell: right(0) });
  assert.equal(g.cells[right(0)], MARK);
  g = reduce(g, { type: 'tap', cell: right(0) });
  assert.equal(g.cells[right(0)], CAT);
  g = reduce(g, { type: 'tap', cell: right(0) });
  assert.equal(g.cells[right(0)], EMPTY);
});

test('a wrong cat costs a life and leaves a mark', () => {
  let g = reduce(newGame(p), { type: 'place', cell: wrong(0) });
  assert.equal(g.lives, 2);
  assert.equal(g.cells[wrong(0)], MARK);
  assert.equal(g.lastMistake, wrong(0));
});

test('three mistakes fail the puzzle and freeze it', () => {
  let g = newGame(p);
  for (let r = 0; r < 3; r++) g = reduce(g, { type: 'place', cell: wrong(r) });
  assert.equal(g.status, 'failed');
  assert.equal(reduce(g, { type: 'place', cell: right(0) }), g);
  assert.equal(reduce(g, { type: 'restart' }).lives, 3);
});

test('placing every answer cat solves it', () => {
  let g = newGame(p);
  for (let r = 0; r < p.size; r++) g = reduce(g, { type: 'place', cell: right(r) });
  assert.equal(g.status, 'solved');
});

test('undo reverts moves but not lives', () => {
  let g = reduce(newGame(p), { type: 'place', cell: wrong(0) });
  g = reduce(g, { type: 'tap', cell: right(1) });
  g = reduce(g, { type: 'undo' });
  assert.equal(g.cells[right(1)], EMPTY);
  assert.equal(g.lives, 2);
});

test('hint points at an answer cell that is not placed yet', () => {
  let g = reduce(newGame(p), { type: 'place', cell: right(0) });
  g = reduce(g, { type: 'hint' });
  assert.ok(g.hinted !== null && g.hinted !== right(0));
  const r = Math.floor(g.hinted! / p.size);
  assert.equal(g.hinted, right(r));
});
