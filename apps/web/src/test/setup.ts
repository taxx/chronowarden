// jsdom in this setup does not expose Web Storage, so provide a minimal
// in-memory implementation for tests that touch `localStorage`.
function createStorage(): Storage {
  const store = new Map<string, string>();
  return {
    get length() {
      return store.size;
    },
    clear: () => store.clear(),
    getItem: (key: string) => (store.has(key) ? store.get(key)! : null),
    key: (index: number) => [...store.keys()][index] ?? null,
    removeItem: (key: string) => {
      store.delete(key);
    },
    setItem: (key: string, value: string) => {
      store.set(key, String(value));
    },
  };
}

if (typeof globalThis.localStorage === 'undefined') {
  Object.defineProperty(globalThis, 'localStorage', {
    value: createStorage(),
    configurable: true,
    writable: true,
  });
}

if (typeof globalThis.sessionStorage === 'undefined') {
  Object.defineProperty(globalThis, 'sessionStorage', {
    value: createStorage(),
    configurable: true,
    writable: true,
  });
}
