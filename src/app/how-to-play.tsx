import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { colOf, neighbours, rowOf } from '../../engine';
import { Board } from '../components/Board';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { Header } from '../components/Header';
import { LivesBar } from '../components/LivesBar';
import { Screen } from '../components/Screen';
import { Text } from '../components/Text';
import { repo } from '../data/repo';
import { CAT, EMPTY, MARK, type CellState } from '../game/game';
import { LEVELS } from '../game/puzzles';
import { tokens } from '../theme/tokens';

const demo = LEVELS[0];
const N = demo.size;
const answer = demo.solution.map((c, r) => r * N + c);

function boardWith(cats: number[], marks: number[]): CellState[] {
  const cells: CellState[] = new Array(N * N).fill(EMPTY);
  marks.forEach((i) => (cells[i] = MARK));
  cats.forEach((i) => (cells[i] = CAT));
  return cells;
}

export default function HowToPlay() {
  const [page, setPage] = useState(0);

  const rules = useMemo(() => {
    const first = answer[0];
    const middle = answer[Math.floor(N / 2)];
    const region = demo.regions[middle];
    const all = [...Array(N * N).keys()];
    return [
      {
        title: 'One cat per row and column',
        body: 'Every row and every column holds exactly one cat.',
        cells: boardWith([first], all.filter((i) => i !== first && (rowOf(N, i) === 0 || colOf(N, i) === colOf(N, first)))),
      },
      {
        title: 'One cat per colour',
        body: 'Each coloured region holds exactly one cat too.',
        cells: boardWith([middle], all.filter((i) => i !== middle && demo.regions[i] === region)),
      },
      {
        title: 'Cats need their space',
        body: 'No two cats touch, not even corner to corner.',
        cells: boardWith([middle], neighbours(N, middle)),
      },
      {
        title: 'Three lives, no guessing',
        body: 'A cat in the wrong place costs a life. Every board has one answer you can reach by logic. Tap to mark cells a cat can’t be in, tap again for a cat.',
        cells: boardWith(answer.slice(0, 2), []),
        lives: 2,
      },
    ];
  }, []);

  const rule = rules[page];
  const last = page === rules.length - 1;
  const finish = async () => {
    await repo.setFlag('seenTutorial', true);
    if (router.canGoBack()) router.back();
    else router.replace('/');
  };

  return (
    <Screen>
      <Header title="How to play" />
      <Card>
        <View style={styles.card} accessible accessibilityLabel={`Rule ${page + 1} of ${rules.length}. ${rule.title}. ${rule.body}`}>
          <Board puzzle={demo} cells={rule.cells} locked maxWidth={240} />
          {rule.lives != null ? <LivesBar lives={rule.lives} /> : null}
          <Text variant="lg" center>{rule.title}</Text>
          <Text color="text-muted" center>{rule.body}</Text>
        </View>
      </Card>

      <View style={styles.dots} accessibilityLabel={`Page ${page + 1} of ${rules.length}`}>
        {rules.map((_, i) => (
          <View key={i} style={[styles.dot, i === page && styles.dotOn]} />
        ))}
      </View>

      <Button label={last ? 'Start playing' : 'Next'} onPress={() => (last ? finish() : setPage(page + 1))} />
      {page > 0 ? <Button label="Back" variant="ghost" onPress={() => setPage(page - 1)} /> : <Button label="Skip" variant="ghost" onPress={finish} />}
    </Screen>
  );
}

const styles = StyleSheet.create({
  card: { alignItems: 'center', gap: tokens.space[3], paddingVertical: tokens.space[2] },
  dots: { flexDirection: 'row', justifyContent: 'center', gap: tokens.space[2], marginVertical: tokens.space[4] },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: tokens.color.border },
  dotOn: { backgroundColor: tokens.color.accent, width: 20 },
});
