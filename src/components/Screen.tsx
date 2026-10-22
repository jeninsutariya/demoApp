import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { tokens } from '../theme/tokens';

// Page frame: safe area, background, centred column at content-max width.
export function Screen({ children, scroll = true }: { children: ReactNode; scroll?: boolean }) {
  const body = <View style={styles.column}>{children}</View>;
  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom', 'left', 'right']}>
      {scroll ? <ScrollView contentContainerStyle={styles.scroll}>{body}</ScrollView> : <View style={styles.scroll}>{body}</View>}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: tokens.color.bg },
  scroll: { flexGrow: 1, alignItems: 'center', paddingHorizontal: tokens.layout.gutter, paddingBottom: tokens.space[6] },
  column: { width: '100%', maxWidth: tokens.layout['content-max'], flexGrow: 1 },
});
