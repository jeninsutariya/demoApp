import { router } from 'expo-router';
import { ChevronLeft } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { tokens } from '../theme/tokens';
import { Text } from './Text';

export function Header({ title, right }: { title: string; right?: ReactNode }) {
  return (
    <View style={styles.bar}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Back"
        hitSlop={8}
        onPress={() => (router.canGoBack() ? router.back() : router.replace('/'))}
        style={styles.back}
      >
        <ChevronLeft size={26} color={tokens.color.text} />
      </Pressable>
      <Text variant="lg" accessibilityRole="header" numberOfLines={1} style={styles.title}>
        {title}
      </Text>
      <View style={styles.right}>{right}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: { height: tokens.layout.header, flexDirection: 'row', alignItems: 'center', gap: tokens.space[2] },
  back: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center', marginLeft: -tokens.space[2] },
  title: { flex: 1 },
  right: { flexDirection: 'row', alignItems: 'center', gap: tokens.space[3] },
});
