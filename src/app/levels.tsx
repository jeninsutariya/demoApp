import { router, useFocusEffect } from 'expo-router';
import { Check, Lock } from 'lucide-react-native';
import { useCallback, useState } from 'react';
import { FlatList, Pressable, StyleSheet, useWindowDimensions, View } from 'react-native';
import { formatTime } from '../components/format';
import { Header } from '../components/Header';
import { Screen } from '../components/Screen';
import { Text } from '../components/Text';
import { repo } from '../data/repo';
import type { LevelRecord } from '../data/types';
import { LEVEL_COUNT, LEVELS } from '../game/puzzles';
import { tokens } from '../theme/tokens';

const NUMBERS = Array.from({ length: LEVEL_COUNT }, (_, i) => i + 1);

export default function Levels() {
  const { width } = useWindowDimensions();
  const columns = width >= 700 ? 6 : 4;
  const [records, setRecords] = useState<Record<number, LevelRecord> | null>(null);

  useFocusEffect(
    useCallback(() => {
      repo.getLevels().then(setRecords);
    }, []),
  );

  const solved = records ? Object.keys(records).map(Number) : [];
  const open = (solved.length ? Math.max(...solved) : 0) + 1;

  return (
    <Screen scroll={false}>
      <Header title="Levels" right={<Text variant="sm" color="text-muted">{solved.length}/{LEVEL_COUNT}</Text>} />
      {records === null ? (
        <View style={styles.grid}>
          {Array.from({ length: columns * 4 }, (_, i) => (
            <View key={i} style={[styles.tile, styles.skeleton]} />
          ))}
        </View>
      ) : (
        <FlatList
          key={columns}
          data={NUMBERS}
          numColumns={columns}
          keyExtractor={(n) => String(n)}
          initialScrollIndex={Math.max(0, Math.floor((open - 1) / columns) - 2) * columns}
          getItemLayout={(_, i) => ({ length: TILE_ROW, offset: TILE_ROW * Math.floor(i / columns), index: i })}
          columnWrapperStyle={{ gap: tokens.space[2] }}
          contentContainerStyle={{ gap: tokens.space[2], paddingBottom: tokens.space[6] }}
          renderItem={({ item: n }) => <LevelTile n={n} record={records[n]} locked={n > open} current={n === open} />}
        />
      )}
    </Screen>
  );
}

const TILE_ROW = 76 + tokens.space[2];

function LevelTile({ n, record, locked, current }: { n: number; record?: LevelRecord; locked: boolean; current: boolean }) {
  const size = LEVELS[n - 1].size;
  const label = locked
    ? `Level ${n}, locked`
    : `Level ${n}, ${size} by ${size}${record ? `, solved in ${formatTime(record.bestMs)}` : ''}`;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled: locked }}
      disabled={locked}
      onPress={() => router.push(`/play/level/${n}`)}
      style={({ focused }: { pressed: boolean; focused?: boolean }) => [
        styles.tile,
        current && styles.current,
        locked && styles.locked,
        focused && styles.current,
      ]}
    >
      {locked ? <Lock size={18} color={tokens.color['text-muted']} /> : <Text variant="lg">{n}</Text>}
      <Text variant="xs" color="text-muted">{size}×{size}</Text>
      {record ? (
        <View style={styles.solved}>
          <Check size={12} color={tokens.color.success} />
          <Text variant="xs" color="success" tabular>{formatTime(record.bestMs)}</Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: tokens.space[2] },
  tile: {
    flex: 1,
    minWidth: 64,
    height: 76,
    borderRadius: tokens.radius.md,
    backgroundColor: tokens.color.surface,
    borderWidth: 1,
    borderColor: tokens.color.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  skeleton: { flexBasis: '22%', flexGrow: 0, backgroundColor: tokens.color.border },
  current: { borderColor: tokens.color.accent, borderWidth: tokens.borderWidth.focus },
  locked: { backgroundColor: tokens.color.bg },
  solved: { flexDirection: 'row', alignItems: 'center', gap: 2 },
});
