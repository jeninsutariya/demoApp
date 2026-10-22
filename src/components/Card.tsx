import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { tokens } from '../theme/tokens';

export const cardStyle = {
  backgroundColor: tokens.color.surface,
  borderRadius: tokens.radius.lg,
  padding: tokens.space[4],
  shadowColor: tokens.color.text,
  shadowOpacity: 0.08,
  shadowRadius: 6,
  shadowOffset: { width: 0, height: 2 },
  elevation: 2,
} as const;

export function Card({ children, onPress, label }: { children: ReactNode; onPress?: () => void; label?: string }) {
  if (!onPress) return <View style={cardStyle}>{children}</View>;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ pressed, focused }: { pressed: boolean; focused?: boolean }) => [
        cardStyle,
        { transform: [{ scale: pressed ? 0.98 : 1 }] },
        focused && styles.focus,
      ]}
    >
      {children}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  focus: { outlineColor: tokens.color.accent, outlineWidth: tokens.borderWidth.focus, outlineStyle: 'solid' },
});
