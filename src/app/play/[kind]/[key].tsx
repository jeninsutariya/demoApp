import { router, useFocusEffect, useLocalSearchParams } from 'expo-router';
import { Lightbulb, RotateCcw, Undo2 } from 'lucide-react-native';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { AppState, StyleSheet, View } from 'react-native';
import { isDateKey, localDateKey, solutionCells, type SolvedPuzzle } from '../../../../engine';
import { Board } from '../../../components/Board';
import { Button } from '../../../components/Button';
import { formatDate, formatTime } from '../../../components/format';
import { Header } from '../../../components/Header';
import { LivesBar } from '../../../components/LivesBar';
import { Screen } from '../../../components/Screen';
import { Sheet } from '../../../components/Sheet';
import { Text } from '../../../components/Text';
import { ToolButton } from '../../../components/ToolButton';
import { leaderboard } from '../../../data/leaderboard';
import { repo } from '../../../data/repo';
import type { DailyRecord, PuzzleKind } from '../../../data/types';
import { useSettings } from '../../../data/useSettings';
import { feedback } from '../../../game/feedback';
import { newGame, reduce, type Action, type Game } from '../../../game/game';
import { cachedDaily, LEVEL_COUNT, levelPuzzle } from '../../../game/puzzles';
import { tokens } from '../../../theme/tokens';

type Route = { kind: PuzzleKind; puzzleKey: string; puzzle: SolvedPuzzle; title: string } | { error: string };

function resolve(kind?: string, key?: string): Route {
  if (kind === 'level') {
    const n = Number(key);
    const puzzle = levelPuzzle(n);
    if (!puzzle) return { error: `There is no level ${key}.` };
    return { kind, puzzleKey: String(n), puzzle, title: `Level ${n}` };
  }
  if (kind === 'daily' && key && isDateKey(key)) {
    if (key !== localDateKey()) return { error: 'That daily puzzle is from another day. Today’s is waiting on the home screen.' };
    return { kind, puzzleKey: key, puzzle: cachedDaily(key), title: `Daily · ${formatDate(key)}` };
  }
  return { error: 'This puzzle could not be found.' };
}

export default function Play() {
  const params = useLocalSearchParams<{ kind: string; key: string }>();
  const route = useMemo(() => resolve(params.kind, params.key), [params.kind, params.key]);
  if ('error' in route) {
    return (
      <Screen>
        <Header title="Puzzle" />
        <View style={styles.message}>
          <Text center color="text-muted">{route.error}</Text>
          <Button label="Go home" onPress={() => router.replace('/')} />
        </View>
      </Screen>
    );
  }
  return <Puzzle key={`${route.kind}:${route.puzzleKey}`} {...route} />;
}

function Puzzle({ kind, puzzleKey, puzzle, title }: { kind: PuzzleKind; puzzleKey: string; puzzle: SolvedPuzzle; title: string }) {
  const [settings] = useSettings();
  const [game, setGame] = useState<Game>(() => newGame(puzzle));
  const [loaded, setLoaded] = useState(false);
  const [doneBefore, setDoneBefore] = useState<DailyRecord | null>(null);
  const [hints, setHints] = useState(0);
  const [hintAsk, setHintAsk] = useState(false);
  const [result, setResult] = useState<{ best?: number; rank?: number; total?: number } | null>(null);

  // Timer: counts only while the puzzle is on screen, the app is active and no
  // sheet is open.
  const elapsed = useRef(0);
  const since = useRef<number | null>(null);
  const [, tick] = useState(0);
  const [focused, setFocused] = useState(true);
  const [active, setActive] = useState(AppState.currentState === 'active');
  const running = loaded && !doneBefore && game.status === 'playing' && focused && active && !hintAsk;
  const now = () => elapsed.current + (since.current ? Date.now() - since.current : 0);

  useFocusEffect(
    useCallback(() => {
      setFocused(true);
      return () => setFocused(false);
    }, []),
  );
  useEffect(() => {
    const sub = AppState.addEventListener('change', (s) => setActive(s === 'active'));
    return () => sub.remove();
  }, []);
  useEffect(() => {
    if (!running) {
      if (since.current) elapsed.current += Date.now() - since.current;
      since.current = null;
      return;
    }
    since.current = Date.now();
    const id = setInterval(() => tick((n) => n + 1), 1000);
    return () => {
      clearInterval(id);
      if (since.current) elapsed.current += Date.now() - since.current;
      since.current = null;
    };
  }, [running]);

  // Load a saved attempt, or today's finished daily
  useEffect(() => {
    let live = true;
    (async () => {
      const [saved, daily, h] = await Promise.all([
        repo.loadAttempt(kind, puzzleKey),
        kind === 'daily' ? repo.getDaily(puzzleKey) : Promise.resolve(null),
        repo.getHints(),
      ]);
      if (!live) return;
      setHints(h);
      if (daily?.status === 'solved') {
        setDoneBefore(daily);
        setGame({ ...newGame(puzzle), cells: puzzle.regions.map((_, i) => (solutionCells(puzzle.size, puzzle.solution).includes(i) ? 2 : 0)), status: 'solved' });
      } else if (saved && saved.cells.length === puzzle.size * puzzle.size) {
        elapsed.current = saved.elapsedMs;
        setGame({ ...newGame(puzzle), cells: saved.cells, history: saved.history, lives: saved.lives, mistakes: saved.mistakes });
      }
      setLoaded(true);
    })();
    return () => {
      live = false;
    };
  }, [kind, puzzleKey, puzzle]);

  // Save after every move; finish when solved
  useEffect(() => {
    if (!loaded || doneBefore) return;
    if (game.status === 'playing') {
      repo.saveAttempt({ kind, key: puzzleKey, cells: game.cells, history: game.history, lives: game.lives, mistakes: game.mistakes, elapsedMs: now() });
      return;
    }
    if (game.status === 'solved') {
      feedback.solved(settings.haptics);
      const ms = now();
      (async () => {
        await repo.clearAttempt(kind, puzzleKey);
        if (kind === 'level') {
          const rec = await repo.recordLevelSolve(Number(puzzleKey), ms);
          setResult({ best: rec.bestMs });
        } else {
          const cats = solutionCells(puzzle.size, puzzle.solution);
          const sent = await leaderboard.submitDaily({ date: puzzleKey, cats, timeMs: ms, mistakes: game.mistakes }).catch(() => null);
          await repo.recordDaily({ date: puzzleKey, status: 'solved', timeMs: ms, mistakes: game.mistakes, submitted: !!sent });
          setHints(await repo.addHints(1));
          setResult({ rank: sent?.rank, total: sent?.total });
        }
      })();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [game, loaded]);

  const act = (a: Action) => {
    setGame((g) => {
      const next = reduce(g, a);
      if (next.lives < g.lives) feedback.mistake(settings.haptics);
      else if (next.cells !== g.cells && next.status === 'playing') feedback.place(settings.haptics);
      return next;
    });
  };

  const restart = () => {
    // A level restarts the clock; the daily keeps counting so retries are fair.
    if (kind === 'level') {
      elapsed.current = 0;
      if (since.current) since.current = Date.now();
    }
    act({ type: 'restart' });
  };

  const spendHint = async () => {
    setHintAsk(false);
    if (hints <= 0) return;
    setHints(await repo.addHints(-1));
    act({ type: 'hint' });
  };

  const nextLevel = Number(puzzleKey) + 1;

  return (
    <Screen>
      <Header
        title={title}
        right={
          <>
            {settings.hideTimer ? null : (
              <Text variant="sm" color="text-muted" tabular accessibilityLabel={`Time ${formatTime(now())}`}>
                {formatTime(doneBefore ? doneBefore.timeMs : now())}
              </Text>
            )}
            <LivesBar lives={game.lives} />
          </>
        }
      />
      <Text variant="sm" color="text-muted" style={styles.sub}>
        {puzzle.size}×{puzzle.size} · {['', 'Easy', 'Medium', 'Hard', 'Expert'][puzzle.difficulty]}
      </Text>

      <Board
        puzzle={puzzle}
        cells={game.cells}
        lastMistake={game.lastMistake}
        hinted={game.hinted}
        patterns={settings.regionPatterns}
        locked={!loaded || game.status !== 'playing'}
        onTap={(cell) => act({ type: 'tap', cell })}
        onPlace={(cell) => act({ type: 'place', cell })}
        onClear={(cell) => act({ type: 'clear', cell })}
      />

      {doneBefore ? (
        <View style={styles.message}>
          <Text center>Solved today in {formatTime(doneBefore.timeMs)}. A new board arrives tomorrow.</Text>
          <Button label="See the leaderboard" onPress={() => router.push('/leaderboard')} />
          <Button label="Play levels" variant="secondary" onPress={() => router.replace('/levels')} />
        </View>
      ) : (
        <>
          <View style={styles.tools}>
            <ToolButton icon={Undo2} label="Undo" disabled={!game.history.length || game.status !== 'playing'} onPress={() => act({ type: 'undo' })} />
            <ToolButton icon={RotateCcw} label="Restart" disabled={game.status !== 'playing'} onPress={restart} />
            <ToolButton icon={Lightbulb} label="Hint" badge={hints} disabled={game.status !== 'playing'} onPress={() => setHintAsk(true)} />
          </View>
          <Text variant="xs" color="text-muted" center>
            Tap to mark a cell. Tap again (or double tap) for a cat. Hold to clear.
          </Text>
        </>
      )}

      <Sheet visible={hintAsk} onClose={() => setHintAsk(false)} label="Hint">
        <Text variant="lg">{hints > 0 ? 'Use a hint?' : 'No hints left'}</Text>
        <Text color="text-muted">
          {hints > 0
            ? `A hint rings the cell you're closest to working out. You have ${hints}.`
            : 'Solve the daily puzzle to earn another one.'}
        </Text>
        {hints > 0 ? <Button label="Show me" onPress={spendHint} /> : null}
        <Button label={hints > 0 ? 'Keep thinking' : 'OK'} variant="secondary" onPress={() => setHintAsk(false)} />
      </Sheet>

      <Sheet visible={!doneBefore && game.status === 'failed'} label="Out of lives">
        <Text variant="xl">Out of lives</Text>
        <Text color="text-muted">
          {kind === 'daily' ? 'The clock keeps running on a retry, so take your time.' : 'Every board has one answer you can reach with logic alone.'}
        </Text>
        <Button label="Try again" onPress={restart} />
        <Button label="Home" variant="secondary" onPress={() => router.replace('/')} />
      </Sheet>

      <Sheet visible={!doneBefore && game.status === 'solved' && result !== null} label="Solved">
        <Text variant="xl">Every cat has a home</Text>
        <Text tabular>
          Time {formatTime(now())} · {game.mistakes === 0 ? 'no mistakes' : `${game.mistakes} mistake${game.mistakes > 1 ? 's' : ''}`}
        </Text>
        {result?.best != null ? <Text color="text-muted" tabular>Best {formatTime(result.best)}</Text> : null}
        {result?.rank != null ? <Text color="text-muted">#{result.rank} of {result.total} today (sample leaderboard)</Text> : null}
        {kind === 'level' ? (
          <>
            {nextLevel <= LEVEL_COUNT ? <Button label={`Level ${nextLevel}`} onPress={() => router.replace(`/play/level/${nextLevel}`)} /> : null}
            <Button label="All levels" variant="secondary" onPress={() => router.replace('/levels')} />
          </>
        ) : (
          <>
            <Text variant="sm" color="success">You earned a hint.</Text>
            <Button label="See the leaderboard" onPress={() => router.replace('/leaderboard')} />
            <Button label="Home" variant="secondary" onPress={() => router.replace('/')} />
          </>
        )}
      </Sheet>
    </Screen>
  );
}

const styles = StyleSheet.create({
  sub: { marginBottom: tokens.space[3] },
  tools: { flexDirection: 'row', justifyContent: 'center', gap: tokens.space[3], marginTop: tokens.space[5], marginBottom: tokens.space[3] },
  message: { gap: tokens.space[2], marginTop: tokens.space[5] },
});
