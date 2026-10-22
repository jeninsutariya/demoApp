import Svg, { Circle, Path } from 'react-native-svg';
import { tokens } from '../theme/tokens';

// Placeholder cat drawn for this project. Replace with commissioned art
// (idle / placed / wrong / celebrating); never the original game's cats.
export function CatIcon({ size, color = tokens.color.cat }: { size: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" accessibilityElementsHidden importantForAccessibility="no">
      <Path fill={color} d="M5 3l3.5 4.2h7L19 3l1 8.2a8 8 0 1 1-16 0z" />
      <Circle cx={9.5} cy={12.5} r={1.2} fill={tokens.color.surface} />
      <Circle cx={14.5} cy={12.5} r={1.2} fill={tokens.color.surface} />
    </Svg>
  );
}
