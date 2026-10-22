import { Heart } from 'lucide-react-native';
import { View } from 'react-native';
import { START_LIVES } from '../game/game';
import { tokens } from '../theme/tokens';

export function LivesBar({ lives }: { lives: number }) {
  return (
    <View
      accessible
      accessibilityRole="text"
      accessibilityLabel={`${lives} of ${START_LIVES} lives left`}
      accessibilityLiveRegion="polite"
      style={{ flexDirection: 'row', gap: tokens.space[1] }}
    >
      {Array.from({ length: START_LIVES }, (_, i) => {
        const live = i < lives;
        return (
          <Heart
            key={i}
            size={22}
            color={live ? tokens.color.danger : tokens.color.border}
            fill={live ? tokens.color.danger : tokens.color.border}
          />
        );
      })}
    </View>
  );
}
