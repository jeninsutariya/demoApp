import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

// Haptics where the device has them; silently nothing on web.
export const feedback = {
  place(on: boolean) {
    if (on && Platform.OS !== 'web') Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
  },
  mistake(on: boolean) {
    if (on && Platform.OS !== 'web') Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning).catch(() => {});
  },
  solved(on: boolean) {
    if (on && Platform.OS !== 'web') Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
  },
};
