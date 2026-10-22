import type { ComponentType } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { tokens } from '../theme/tokens';
import { Text } from './Text';

type Icon = ComponentType<{ size?: number; color?: string }>;

export function ToolButton({
  icon: Icon,
  label,
  onPress,
  disabled,
  badge,
}: {
  icon: Icon;
  label: string;
  onPress: () => void;
  disabled?: boolean;
  badge?: number;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={badge != null ? `${label}, ${badge} left` : label}
      accessibilityState={{ disabled: !!disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed, focused }: { pressed: boolean; focused?: boolean }) => [
        styles.tool,
        { opacity: disabled ? 0.4 : 1, transform: [{ scale: pressed ? 0.96 : 1 }] },
        focused && styles.focus,
      ]}
    >
      <Icon size={24} color={tokens.color.text} />
      {badge != null ? (
        <View style={styles.badge}>
          <Text variant="xs" color="on-accent">
            {badge}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  tool: {
    width: 48,
    height: 48,
    borderRadius: tokens.radius.md,
    backgroundColor: tokens.color.surface,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: tokens.color.text,
    shadowOpacity: 0.08,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  focus: { outlineColor: tokens.color.accent, outlineWidth: tokens.borderWidth.focus, outlineStyle: 'solid' },
  badge: {
    position: 'absolute',
    top: -tokens.space[1],
    right: -tokens.space[1],
    minWidth: 20,
    paddingHorizontal: tokens.space[1],
    borderRadius: tokens.radius.pill,
    backgroundColor: tokens.color.accent,
    alignItems: 'center',
  },
});
