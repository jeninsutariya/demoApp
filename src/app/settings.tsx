import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, Switch, View } from 'react-native';
import { Button } from '../components/Button';
import { Header } from '../components/Header';
import { Screen } from '../components/Screen';
import { Sheet } from '../components/Sheet';
import { Text } from '../components/Text';
import { leaderboard } from '../data/leaderboard';
import type { Settings as S } from '../data/types';
import { useSettings } from '../data/useSettings';
import { tokens } from '../theme/tokens';

const TOGGLES: { key: keyof S; label: string; note?: string }[] = [
  { key: 'haptics', label: 'Vibration' },
  { key: 'sound', label: 'Sound', note: 'Sounds are not in the game yet.' },
  { key: 'hideTimer', label: 'Hide the timer' },
  { key: 'regionPatterns', label: 'Region shapes', note: 'Adds a small shape to each colour, for telling regions apart without colour.' },
];

export default function Settings() {
  const [settings, update] = useSettings();
  const [confirm, setConfirm] = useState(false);
  const [deleted, setDeleted] = useState(false);

  return (
    <Screen>
      <Header title="Settings" />
      <View style={styles.group}>
        {TOGGLES.map((t) => (
          <View key={t.key} style={styles.row}>
            <View style={styles.flex}>
              <Text>{t.label}</Text>
              {t.note ? <Text variant="xs" color="text-muted">{t.note}</Text> : null}
            </View>
            <Switch
              accessibilityLabel={t.label}
              value={settings[t.key]}
              onValueChange={(v) => update({ [t.key]: v })}
              trackColor={{ true: tokens.color.accent, false: tokens.color['border-input'] }}
            />
          </View>
        ))}
      </View>

      <View style={styles.group}>
        <LinkRow label="How to play" onPress={() => router.push('/how-to-play')} />
        <LinkRow label="Restore purchase" note="Purchases are not set up yet." disabled />
        <LinkRow label="Privacy" note="Your progress stays on this device." disabled />
        <LinkRow label={deleted ? 'Leaderboard data deleted' : 'Delete my leaderboard data'} danger disabled={deleted} onPress={() => setConfirm(true)} />
      </View>

      <Sheet visible={confirm} onClose={() => setConfirm(false)} label="Delete leaderboard data">
        <Text variant="lg">Delete your leaderboard data?</Text>
        <Text color="text-muted">Your name and daily times are removed from the leaderboard. Progress on this device stays.</Text>
        <Button
          label="Delete"
          variant="danger"
          onPress={async () => {
            await leaderboard.deleteMe();
            setDeleted(true);
            setConfirm(false);
          }}
        />
        <Button label="Cancel" variant="secondary" onPress={() => setConfirm(false)} />
      </Sheet>
    </Screen>
  );
}

function LinkRow({ label, note, onPress, disabled, danger }: { label: string; note?: string; onPress?: () => void; disabled?: boolean; danger?: boolean }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !!disabled }}
      disabled={disabled}
      onPress={onPress}
      style={[styles.row, { opacity: disabled && !note ? 0.5 : 1 }]}
    >
      <View style={styles.flex}>
        <Text color={danger ? 'danger' : disabled ? 'text-muted' : 'text'}>{label}</Text>
        {note ? <Text variant="xs" color="text-muted">{note}</Text> : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  group: { backgroundColor: tokens.color.surface, borderRadius: tokens.radius.lg, marginBottom: tokens.space[5], overflow: 'hidden' },
  row: { minHeight: 56, flexDirection: 'row', alignItems: 'center', paddingHorizontal: tokens.space[4], paddingVertical: tokens.space[2], borderBottomWidth: 1, borderBottomColor: tokens.color.border, gap: tokens.space[3] },
  flex: { flex: 1 },
});
