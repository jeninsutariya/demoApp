import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';
import { tokens } from '../theme/tokens';
import { Text } from './Text';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';

const look: Record<Variant, { bg: string; fg: 'on-accent' | 'text' | 'accent'; border?: string }> = {
  primary: { bg: tokens.color.accent, fg: 'on-accent' },
  secondary: { bg: tokens.color.surface, fg: 'text', border: tokens.color['border-input'] },
  ghost: { bg: 'transparent', fg: 'accent' },
  danger: { bg: tokens.color.danger, fg: 'on-accent' },
};

export function Button({
  label,
  onPress,
  variant = 'primary',
  size = 'lg',
  disabled,
  loading,
  accessibilityHint,
}: {
  label: string;
  onPress: () => void;
  variant?: Variant;
  size?: 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  accessibilityHint?: string;
}) {
  const l = look[variant];
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled: !!disabled, busy: !!loading }}
      disabled={disabled || loading}
      onPress={onPress}
      style={({ pressed, focused }: { pressed: boolean; focused?: boolean }) => [
        styles.base,
        {
          height: size === 'lg' ? 52 : tokens.layout['cell-min-touch'],
          backgroundColor: l.bg,
          borderColor: l.border ?? 'transparent',
          opacity: disabled ? 0.4 : 1,
          transform: [{ scale: pressed ? 0.97 : 1 }],
        },
        focused && styles.focus,
      ]}
    >
      <View style={styles.row}>
        {loading ? <ActivityIndicator color={tokens.color[l.fg]} /> : null}
        <Text variant="base" color={l.fg} style={styles.label}>
          {label}
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: tokens.radius.pill,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: tokens.space[5],
    marginTop: tokens.space[2],
  },
  focus: { borderColor: tokens.color.accent, borderWidth: tokens.borderWidth.focus },
  row: { flexDirection: 'row', alignItems: 'center', gap: tokens.space[2] },
  label: { fontFamily: tokens.font.bold },
});
