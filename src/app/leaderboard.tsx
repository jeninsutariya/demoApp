import { router, useFocusEffect } from 'expo-router';
import { useCallback, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { localDateKey } from '../../engine';
import { Button } from '../components/Button';
import { formatDate, formatTime } from '../components/format';
import { Header } from '../components/Header';
import { Screen } from '../components/Screen';
import { Text } from '../components/Text';
import { leaderboard } from '../data/leaderboard';
import { repo } from '../data/repo';
import type { DailyRecord, LeaderboardResult } from '../data/types';
import { tokens } from '../theme/tokens';

const TOP = 50;

export default function Leaderboard() {
  const today = localDateKey();
  const [mine, setMine] = useState<DailyRecord | null>(null);
  const [board, setBoard] = useState<LeaderboardResult | null>(null);

  const load = useCallback(() => {
    let live = true;
    setBoard(null);
    (async () => {
      const rec = await repo.getDaily(today);
      const res = await leaderboard
        .getDaily(today, rec?.status === 'solved' ? rec.timeMs : null)
        .catch((e: unknown) => ({ state: 'error' as const, message: String(e) }));
      if (live) {
        setMine(rec);
        setBoard(res);
      }
    })();
    return () => {
      live = false;
    };
  }, [today]);
  useFocusEffect(load);

  return (
    <Screen>
      <Header title="Today's fastest" />
      <Text variant="sm" color="text-muted" style={styles.sub}>Daily puzzle · {formatDate(today)}</Text>

      {board?.state === 'ok' && board.sample ? (
        <View style={styles.banner}>
          <Text variant="sm">Sample leaderboard: the other names are placeholders until online play is switched on.</Text>
        </View>
      ) : null}

      {mine?.status !== 'solved' ? (
        <View style={styles.banner}>
          <Text variant="sm">Solve today’s puzzle to get on the board.</Text>
          <Button size="md" label="Play the daily" onPress={() => router.push(`/play/daily/${today}`)} />
        </View>
      ) : null}

      {board === null ? (
        Array.from({ length: 8 }, (_, i) => <View key={i} style={styles.skeleton} />)
      ) : board.state === 'offline' ? (
        <Text color="text-muted" center style={styles.note}>
          You’re offline. Your time is saved and will be sent when you’re back online.
        </Text>
      ) : board.state === 'error' ? (
        <View style={styles.note}>
          <Text color="danger" center>The leaderboard didn’t load.</Text>
          <Button label="Try again" variant="secondary" onPress={load} />
        </View>
      ) : board.rows.length === 0 ? (
        <Text color="text-muted" center style={styles.note}>No times yet today. Be the first.</Text>
      ) : (
        <View accessibilityRole="list">
          {board.rows
            .filter((r) => r.rank <= TOP || r.isMe)
            .map((r) => (
              <View
                key={`${r.rank}-${r.name}`}
                accessible
                accessibilityLabel={`${r.isMe ? 'You, ' : ''}rank ${r.rank}, ${r.name}, ${formatTime(r.timeMs)}`}
                style={[styles.row, r.isMe && styles.me]}
              >
                <Text variant="sm" tabular style={styles.rank} color={r.rank <= 3 ? 'warning' : 'text-muted'}>#{r.rank}</Text>
                <Text variant="sm" numberOfLines={1} style={styles.name}>{r.name}</Text>
                <Text variant="sm" tabular>{formatTime(r.timeMs)}</Text>
              </View>
            ))}
        </View>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  sub: { marginBottom: tokens.space[3] },
  banner: { backgroundColor: tokens.color.surface, borderRadius: tokens.radius.md, padding: tokens.space[3], marginBottom: tokens.space[3], gap: tokens.space[1] },
  row: { flexDirection: 'row', alignItems: 'center', gap: tokens.space[3], paddingVertical: tokens.space[3], paddingHorizontal: tokens.space[2], borderBottomWidth: 1, borderBottomColor: tokens.color.border },
  me: { backgroundColor: tokens.color['region-7'], borderRadius: tokens.radius.sm },
  rank: { width: 40 },
  name: { flex: 1 },
  skeleton: { height: 44, borderRadius: tokens.radius.sm, backgroundColor: tokens.color.border, marginBottom: tokens.space[2] },
  note: { marginTop: tokens.space[6], gap: tokens.space[2] },
});
