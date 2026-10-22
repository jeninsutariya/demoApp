import { router } from 'expo-router';
import { View } from 'react-native';
import { Button } from '../components/Button';
import { Screen } from '../components/Screen';
import { Text } from '../components/Text';
import { tokens } from '../theme/tokens';

export default function NotFound() {
  return (
    <Screen>
      <View style={{ flex: 1, justifyContent: 'center', gap: tokens.space[3] }}>
        <Text variant="xl" center>Nothing here</Text>
        <Text color="text-muted" center>That page wandered off.</Text>
        <Button label="Go home" onPress={() => router.replace('/')} />
      </View>
    </Screen>
  );
}
