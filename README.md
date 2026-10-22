# Napspot

A daily cat logic puzzle for iOS: one cat per row, column and colour, and no
two cats touching.

- `ios-native/`: the iOS app (SwiftUI, iOS 17+) and its Swift package. Start with `ios-native/README.md`.
- `engine/`: the reference puzzle engine in TypeScript and the shipped level pack. The Swift engine is tested against it.
- `scripts/gen-levels.ts`: regenerates the 300 levels (`npm run levels`).
- `replica/`: recon, architecture, design, build log and backend notes.

```bash
npm install && npm test        # TypeScript engine
cd ios-native/CatLogicKit && swift test
```
