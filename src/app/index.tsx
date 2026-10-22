import { router, useFocusEffect } from 'expo-router';
import { BookOpen, Calendar, Check, Grid3x3, Settings, Trophy } from 'lucide-react-native';
import { useCallback, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { localDateKey } from '../../engine';
import { Card } from '../components/Card';
import { formatDate, formatTime } from '../components/format';
import { Screen } from '../components/Screen';
import { Text } from '../components/Text';
import { repo } from '../data/repo';
import type { DailyRecord } from '../data/types';
import { cachedDaily, LEVEL_COUNT, levelPuzzle } from '../game/puzzles';
import { tokens } from '../theme/tokens';

type HomeData = { today: string; daily: DailyRecord | null; streak: number; solved: number; next: number };

export default function Home() {
  const [data, setData] = useState<HomeData | null>(null);

  useFocusEffect(
    useCallback(() => {
      let live = true;
      (async () => {
        if (!(await repo.getFlag('seenTutorial'))) {
          router.push('/how-to-play');
          return;
        }
        const today = localDateKey();
        const [daily, streak, levels] = await Promise.all([repo.getDaily(today), repo.dailyStreak(today), repo.getLevels()]);
        const solvedLevels = Object.keys(levels).map(Number);
        const next = Math.min(LEVEL_COUNT, (solvedLevels.length ? Math.max(...solvedLevels) : 0) + 1);
        if (live) setData({ today, daily, streak, solved: solvedLevels.length, next });
      })();
      return () => {
        live = false;
      };
    }, []),
  );

  const today = data?.today ?? localDateKey();
  const dailySize = cachedDaily(today).size;
  const nextSize = levelPuzzle(data?.next ?? 1)?.size ?? 5;

  return (
    <Screen>
      <View style={styles.top}>
        <Text variant="display" accessibilityRole="header">Cat Logic</Text>
        <Text color="text-muted">One cat per row, column and colour.</Text>
      </View>

      <View style={styles.cards}>
        <Card label="Daily puzzle" onPress={() => router.push(`/play/daily/${today}`)}>
          <View style={styles.cardHead}>
            <Calendar size={22} color={tokens.color.accent} />
            <Text variant="lg" style={styles.flex}>Daily puzzle</Text>
            {data && data.streak > 0 ? <Text variant="sm" color="warning">{data.streak} day streak</Text> : null}
          </View>
          <Text color="text-muted">{formatDate(today)} · {dailySize}×{dailySize}</Text>
          {data?.daily?.status === 'solved' ? (
            <View style={styles.done}>
              <Check size={18} color={tokens.color.success} />
              <Text variant="sm" color="success">Solved in {formatTime(data.daily.timeMs)}. New one tomorrow.</Text>
            </View>
          ) : (
            <Text variant="sm" color="accent" style={styles.cta}>Play today’s board</Text>
          )}
        </Card>

        <Card label="Levels" onPress={() => router.push(`/play/level/${data?.next ?? 1}`)}>
          <View style={styles.cardHead}>
            <Grid3x3 size={22} color={tokens.color.accent} />
            <Text variant="lg" style={styles.flex}>Levels</Text>
          </View>
          <Text color="text-muted">{data?.solved ?? 0} of {LEVEL_COUNT} solved</Text>
          <Text variant="sm" color="accent" style={styles.cta}>
            {data?.solved ? 'Continue' : 'Start'}: level {data?.next ?? 1} · {nextSize}×{nextSize}
          </Text>
        </Card>
      </View>

      <View style={styles.links}>
        <IconLink icon={Grid3x3} label="All levels" onPress={() => router.push('/levels')} />
        <IconLink icon={Trophy} label="Leaderboard" onPress={() => router.push('/leaderboard')} />
        <IconLink icon={BookOpen} label="How to play" onPress={() => router.push('/how-to-play')} />
        <IconLink icon={Settings} label="Settings" onPress={() => router.push('/settings')} />
      </View>
    </Screen>
  );
}

function IconLink({ icon: Icon, label, onPress }: { icon: typeof Trophy; label: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress} style={styles.link}>
      <Icon size={24} color={tokens.color.text} />
      <Text variant="xs" color="text-muted">{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  top: { paddingTop: tokens.space[7], paddingBottom: tokens.space[6], gap: tokens.space[1] },
  cards: { gap: tokens.space[4] },
  cardHead: { flexDirection: 'row', alignItems: 'center', gap: tokens.space[2], marginBottom: tokens.space[1] },
  flex: { flex: 1 },
  done: { flexDirection: 'row', alignItems: 'center', gap: tokens.space[1], marginTop: tokens.space[2] },
  cta: { marginTop: tokens.space[2], fontFamily: tokens.font.bold },
  links: { flexDirection: 'row', justifyContent: 'space-around', marginTop: tokens.space[6] },
  link: { alignItems: 'center', gap: tokens.space[1], minWidth: 72, minHeight: 56, justifyContent: 'center' },
});
