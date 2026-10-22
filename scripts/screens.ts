/// <reference types="node" />
// Serves the web export (dist/) and drives the real app with Playwright:
// plays the flows and saves a screenshot per screen to replica/clone-screens/
// for /replica-diff. Fails on any console error.
//   npx expo export --platform web && npx tsx scripts/screens.ts
import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join } from 'node:path';
import { chromium, type Page } from 'playwright';
import { dailyPuzzle, decode, localDateKey } from '../engine';
import levels from '../assets/levels.json';

const ROOT = join(__dirname, '..');
const DIST = join(ROOT, 'dist');
const OUT = join(ROOT, 'replica', 'clone-screens');
const TYPES: Record<string, string> = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.ttf': 'font/ttf', '.png': 'image/png', '.ico': 'image/x-icon' };

const server = createServer((req, res) => {
  const path = decodeURIComponent((req.url ?? '/').split('?')[0]);
  let file = join(DIST, path);
  if (!file.startsWith(DIST) || !existsSync(file) || statSync(file).isDirectory()) file = join(DIST, 'index.html');
  res.setHeader('content-type', TYPES[extname(file)] ?? 'application/octet-stream');
  createReadStream(file).pipe(res);
});

const errors: string[] = [];
const cell = (p: Page, r: number, c: number) => p.getByLabel(new RegExp(`^Row ${r + 1}, column ${c + 1},`)).first();

async function tap(p: Page, r: number, c: number, times = 1) {
  for (let i = 0; i < times; i++) {
    await cell(p, r, c).click();
    await p.waitForTimeout(350); // slower than a double tap
  }
}

async function main() {
  await new Promise<void>((ok) => server.listen(4123, ok));
  const base = 'http://localhost:4123';
  const browser = await chromium.launch();

  for (const [vw, vh, suffix] of [[390, 844, ''], [1440, 900, '-1440']] as const) {
    const ctx = await browser.newContext({ viewport: { width: vw, height: vh }, deviceScaleFactor: 2 });
    const p = await ctx.newPage();
    p.on('console', (m) => m.type() === 'error' && errors.push(`${suffix || '390'} ${p.url()}: ${m.text()}`));
    p.on('pageerror', (e) => errors.push(`${suffix || '390'} ${p.url()}: ${e.message}`));
    const shot = async (id: string, fullPage = true) => {
      await p.waitForTimeout(400);
      await p.screenshot({ path: join(OUT, `${id}${suffix}.png`), fullPage });
    };

    // S12: first launch goes to how to play
    await p.goto(base + '/');
    await p.getByText('One cat per row and column').waitFor();
    await shot('S12');
    for (let i = 0; i < 3; i++) await p.getByRole('button', { name: 'Next' }).click();
    await p.getByRole('button', { name: 'Start playing' }).click();

    // S01 home
    await p.getByText('Daily puzzle', { exact: true }).waitFor();
    await shot('S01');

    // S03 level 1: marks, one mistake (S04), hint (S09)
    const l1 = decode((levels as string[])[0]);
    await p.goto(base + '/play/level/1');
    await cell(p, 0, 0).waitFor();
    const wrongCol = (l1.solution[0] + 2) % l1.size;
    await tap(p, 0, wrongCol, 2); // mark, then cat: wrong
    await tap(p, 1, l1.solution[1], 2); // right cat
    await tap(p, 3, 0); // mark
    await shot('S04');
    await p.getByRole('button', { name: /^Hint/ }).click();
    await p.getByText('Use a hint?').waitFor();
    await shot('S09');
    await p.getByRole('button', { name: 'Show me' }).click();
    await shot('S03');

    // S05 fail: two more wrong cats
    for (const r of [2, 4]) await tap(p, r, (l1.solution[r] + 2) % l1.size, 2);
    await p.getByText('Out of lives').first().waitFor();
    await shot('S05');
    await p.getByRole('button', { name: 'Try again' }).click();

    // S06 win: place every answer cat
    for (let r = 0; r < l1.size; r++) await tap(p, r, l1.solution[r], 2);
    await p.getByText('Every cat has a home').waitFor();
    await shot('S06');

    // S02 levels
    await p.getByRole('button', { name: 'All levels' }).click();
    await p.getByLabel(/^Level 2, 5 by 5$/).waitFor();
    await shot('S02', false);

    // S07 daily: solve it, then S08 leaderboard
    const today = localDateKey();
    const d = dailyPuzzle(today);
    await p.goto(`${base}/play/daily/${today}`);
    await cell(p, 0, 0).waitFor();
    await tap(p, 0, d.solution[0], 2);
    await shot('S07');
    for (let r = 1; r < d.size; r++) await tap(p, r, d.solution[r], 2);
    await p.getByText('Every cat has a home').waitFor();
    await shot('S07-solved');
    await p.getByRole('button', { name: 'See the leaderboard' }).click();
    await p.getByText(/^#1$/).first().waitFor();
    await shot('S08');

    // S11 settings, with region shapes on
    await p.goto(base + '/settings');
    await p.getByLabel('Region shapes').click();
    await shot('S11');

    await p.goto(base + '/design');
    await p.getByText('Design system').waitFor();
    await shot('design');
    await ctx.close();
  }

  await browser.close();
  server.close();
  if (errors.length) {
    console.error(`${errors.length} console errors:\n` + errors.join('\n'));
    process.exit(1);
  }
  console.log('all flows passed, screenshots in replica/clone-screens/, no console errors');
}

main().catch((e) => {
  console.error(e);
  server.close();
  process.exit(1);
});
