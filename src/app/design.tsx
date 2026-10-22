import { Lightbulb, RotateCcw, Undo2 } from 'lucide-react-native';
import { StyleSheet, View } from 'react-native';
import { Board } from '../components/Board';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { CatIcon } from '../components/CatIcon';
import { Header } from '../components/Header';
import { LivesBar } from '../components/LivesBar';
import { Screen } from '../components/Screen';
import { Text } from '../components/Text';
import { ToolButton } from '../components/ToolButton';
import { CAT, EMPTY, MARK, type CellState } from '../game/game';
import { LEVELS } from '../game/puzzles';
import { tokens } from '../theme/tokens';

// Every primitive in isolation, in its states. Not linked from the app; open /design.
const p = LEVELS[45];
const cells: CellState[] = p.regions.map((_, i) => (i === p.solution[0] ? CAT : i % 7 === 3 ? MARK : EMPTY));

export default function Design() {
  return (
    <Screen>
      <Header title="Design system" />
      <Section title="Type">
        {(Object.keys(tokens.type) as (keyof typeof tokens.type)[]).map((k) => (
          <Text key={k} variant={k}>{k} · The cat sat in row three</Text>
        ))}
      </Section>
      <Section title="Colour roles">
        <View style={styles.swatches}>
          {Object.entries(tokens.color).map(([k, v]) => (
            <View key={k} style={styles.swatchBox}>
              <View style={[styles.swatch, { backgroundColor: v }]} />
              <Text variant="xs" color="text-muted">{k}</Text>
            </View>
          ))}
        </View>
      </Section>
      <Section title="Buttons">
        <Button label="Primary" onPress={() => {}} />
        <Button label="Secondary" variant="secondary" onPress={() => {}} />
        <Button label="Ghost" variant="ghost" onPress={() => {}} />
        <Button label="Danger" variant="danger" onPress={() => {}} />
        <Button label="Disabled" disabled onPress={() => {}} />
        <Button label="Loading" loading onPress={() => {}} />
      </Section>
      <Section title="Tools, lives, cat">
        <View style={styles.inline}>
          <ToolButton icon={Undo2} label="Undo" onPress={() => {}} />
          <ToolButton icon={RotateCcw} label="Restart" disabled onPress={() => {}} />
          <ToolButton icon={Lightbulb} label="Hint" badge={2} onPress={() => {}} />
          <LivesBar lives={3} />
          <LivesBar lives={1} />
          <CatIcon size={32} />
          <CatIcon size={32} color={tokens.color.danger} />
        </View>
      </Section>
      <Section title="Board: marks, cat, mistake, hint">
        <Board puzzle={p} cells={cells} lastMistake={3} hinted={p.size + p.solution[1]} />
      </Section>
      <Section title="Board: region shapes on">
        <Board puzzle={p} cells={cells} patterns locked />
      </Section>
      <Section title="Card">
        <Card><Text>Card content</Text></Card>
      </Section>
    </Screen>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View style={styles.section}>
      <Text variant="sm" color="text-muted" style={styles.label}>{title}</Text>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  section: { marginBottom: tokens.space[6], gap: tokens.space[2] },
  label: { fontFamily: tokens.font.bold },
  swatches: { flexDirection: 'row', flexWrap: 'wrap', gap: tokens.space[2] },
  swatchBox: { width: 76, gap: tokens.space[1] },
  swatch: { height: 36, borderRadius: tokens.radius.sm, borderWidth: 1, borderColor: tokens.color.border },
  inline: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: tokens.space[3] },
});
