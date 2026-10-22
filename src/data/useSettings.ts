import { useEffect, useState } from 'react';
import { repo } from './repo';
import { DEFAULT_SETTINGS, type Settings } from './types';

// Settings shared by every screen, loaded once.
let current: Settings = DEFAULT_SETTINGS;
let loaded = false;
const listeners = new Set<(s: Settings) => void>();

export function useSettings(): [Settings, (patch: Partial<Settings>) => void] {
  const [s, setS] = useState(current);
  useEffect(() => {
    listeners.add(setS);
    if (!loaded) {
      loaded = true;
      repo.getSettings().then((v) => {
        current = v;
        listeners.forEach((l) => l(v));
      });
    }
    return () => {
      listeners.delete(setS);
    };
  }, []);
  const update = (patch: Partial<Settings>) => {
    current = { ...current, ...patch };
    listeners.forEach((l) => l(current));
    repo.saveSettings(current);
  };
  return [s, update];
}
