import { Text as RNText, type TextProps } from 'react-native';
import { tokens } from '../theme/tokens';

type Variant = keyof typeof tokens.type;
type Color = 'text' | 'text-muted' | 'accent' | 'on-accent' | 'danger' | 'success' | 'warning';

const fontFor = (weight: number) =>
  weight >= 800 ? tokens.font.black : weight >= 700 ? tokens.font.bold : tokens.font.regular;

export function Text({
  variant = 'base',
  color = 'text',
  center,
  tabular,
  style,
  ...rest
}: TextProps & { variant?: Variant; color?: Color; center?: boolean; tabular?: boolean }) {
  const t = tokens.type[variant];
  return (
    <RNText
      {...rest}
      style={[
        {
          fontSize: t.size,
          lineHeight: t.line,
          fontFamily: fontFor(t.weight),
          color: tokens.color[color],
          textAlign: center ? 'center' : undefined,
          fontVariant: tabular ? ['tabular-nums'] : undefined,
        },
        style,
      ]}
    />
  );
}
