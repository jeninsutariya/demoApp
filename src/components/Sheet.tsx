import type { ReactNode } from 'react';
import { Modal, StyleSheet, View } from 'react-native';
import { tokens } from '../theme/tokens';
import { cardStyle } from './Card';

// Modal used for win, fail, hint and confirm.
export function Sheet({ visible, onClose, children, label }: { visible: boolean; onClose?: () => void; children: ReactNode; label: string }) {
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.scrim}>
        <View accessibilityViewIsModal accessibilityLabel={label} style={[cardStyle, styles.sheet]}>
          {children}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: {
    flex: 1,
    backgroundColor: tokens.color.text + '66',
    alignItems: 'center',
    justifyContent: 'center',
    padding: tokens.layout.gutter,
  },
  sheet: { width: '100%', maxWidth: 400, padding: tokens.space[5], gap: tokens.space[2] },
});
