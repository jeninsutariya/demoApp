import { useEffect, useRef, useState } from 'react';
import { Animated, Pressable, StyleSheet, Text as RNText, View, useWindowDimensions } from 'react-native';
import type { Puzzle } from '../../engine';
import { CAT, MARK, type CellState } from '../game/game';
import { tokens, type RegionColor } from '../theme/tokens';
import { CatIcon } from './CatIcon';

const REGION_NAMES = ['pink', 'peach', 'yellow', 'lime', 'mint', 'sky', 'periwinkle', 'lavender', 'tan', 'grey'];
// One shape per region for players who can't tell the colours apart
const PATTERNS = ['•', '◦', '▪', '▫', '▴', '▵', '◆', '◇', '+', '–'];
const DOUBLE_TAP_MS = 300;

const regionColor = (g: number) => tokens.color[`region-${g + 1}` as RegionColor];
const stateWord = (s: CellState) => (s === CAT ? 'cat' : s === MARK ? 'marked' : 'empty');

export function Board({
  puzzle,
  cells,
  lastMistake = null,
  hinted = null,
  patterns = false,
  locked = false,
  maxWidth,
  onTap,
  onPlace,
  onClear,
}: {
  puzzle: Puzzle;
  cells: CellState[];
  lastMistake?: number | null;
  hinted?: number | null;
  patterns?: boolean;
  locked?: boolean;
  maxWidth?: number;
  onTap?: (cell: number) => void;
  onPlace?: (cell: number) => void;
  onClear?: (cell: number) => void;
}) {
  const { size, regions } = puzzle;
  const window = useWindowDimensions();
  const edge = tokens.borderWidth.region;
  const width = Math.min(window.width - 2 * tokens.layout.gutter, maxWidth ?? tokens.layout['board-max']);
  const cell = Math.floor((width - 2 * edge) / size);

  const [shake] = useState(() => new Animated.Value(0));
  useEffect(() => {
    if (lastMistake == null) return;
    shake.setValue(0);
    Animated.sequence(
      [6, -6, 4, -4, 0].map((x) =>
        Animated.timing(shake, { toValue: x, duration: tokens.motion.shake / 5, useNativeDriver: true }),
      ),
    ).start();
  }, [lastMistake, shake]);

  const lastTap = useRef<{ cell: number; at: number } | null>(null);
  const press = (i: number) => {
    if (locked) return;
    const now = Date.now();
    const prev = lastTap.current;
    lastTap.current = { cell: i, at: now };
    if (prev && prev.cell === i && now - prev.at < DOUBLE_TAP_MS) {
      lastTap.current = null;
      onPlace?.(i);
    } else {
      onTap?.(i);
    }
  };

  return (
    <View
      accessibilityRole="grid"
      accessibilityLabel={`${size} by ${size} puzzle`}
      style={[styles.board, { width: cell * size + 2 * edge, opacity: locked ? 0.95 : 1 }]}
    >
      {Array.from({ length: size }, (_, r) => (
        <View key={r} style={styles.row}>
          {Array.from({ length: size }, (_, c) => {
            const i = r * size + c;
            const g = regions[i];
            const state = cells[i];
            const thickRight = c < size - 1 && regions[i + 1] !== g;
            const thickBottom = r < size - 1 && regions[i + size] !== g;
            const isMistake = lastMistake === i;
            const content = (
              <>
                {patterns ? <RNText style={[styles.pattern, { fontSize: cell * 0.28 }]}>{PATTERNS[g]}</RNText> : null}
                {state === CAT ? <CatIcon size={cell * 0.72} /> : null}
                {state === MARK ? (
                  <RNText style={[styles.mark, { fontSize: cell * 0.42, color: isMistake ? tokens.color.danger : tokens.color.mark }]}>✕</RNText>
                ) : null}
              </>
            );
            return (
              <Pressable
                key={c}
                accessibilityRole="button"
                accessibilityLabel={`Row ${r + 1}, column ${c + 1}, ${REGION_NAMES[g]} region, ${stateWord(state)}`}
                accessibilityHint={locked ? undefined : 'Tap to mark, tap again for a cat, double tap places a cat'}
                disabled={locked}
                onPress={() => press(i)}
                onLongPress={() => !locked && onClear?.(i)}
                style={({ focused }: { pressed: boolean; focused?: boolean }) => [
                  styles.cell,
                  {
                    width: cell,
                    height: cell,
                    backgroundColor: regionColor(g),
                    borderRightWidth: c < size - 1 ? (thickRight ? edge : tokens.borderWidth.grid) : 0,
                    borderBottomWidth: r < size - 1 ? (thickBottom ? edge : tokens.borderWidth.grid) : 0,
                    borderRightColor: thickRight ? tokens.color['region-edge'] : tokens.color['grid-line'],
                    borderBottomColor: thickBottom ? tokens.color['region-edge'] : tokens.color['grid-line'],
                  },
                  (focused || hinted === i) && styles.ring,
                  isMistake && styles.mistake,
                ]}
              >
                {isMistake ? (
                  <Animated.View style={[styles.center, { transform: [{ translateX: shake }] }]}>{content}</Animated.View>
                ) : (
                  <View style={styles.center}>{content}</View>
                )}
              </Pressable>
            );
          })}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  board: {
    alignSelf: 'center',
    borderWidth: tokens.borderWidth.region,
    borderColor: tokens.color['region-edge'],
    borderRadius: tokens.radius.md,
    overflow: 'hidden',
    backgroundColor: tokens.color['region-edge'],
  },
  row: { flexDirection: 'row' },
  cell: { alignItems: 'center', justifyContent: 'center' },
  center: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center' },
  ring: { outlineColor: tokens.color.accent, outlineWidth: tokens.borderWidth.focus, outlineStyle: 'solid', outlineOffset: -4 },
  mistake: { outlineColor: tokens.color.danger, outlineWidth: 2, outlineStyle: 'solid', outlineOffset: -2 },
  mark: { fontFamily: tokens.font.black, includeFontPadding: false },
  pattern: { position: 'absolute', top: 1, left: 3, color: tokens.color.mark, opacity: 0.55 },
});
