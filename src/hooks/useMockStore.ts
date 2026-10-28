import { useSyncExternalStore } from 'react';
import { mockStore } from '@/mock-data/store';

export function useMockStore() {
  const subscribe = (cb: () => void) => mockStore.subscribe(cb);
  const getSnapshot = () => mockStore;
  return useSyncExternalStore(subscribe, getSnapshot, getSnapshot);
}
