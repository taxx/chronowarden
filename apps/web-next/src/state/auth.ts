import { create } from 'zustand';

import { authApi } from '../api/auth';
import { ApiError } from '../api/client';
import { settingsApi } from '../api/settings';
import type { User } from '../api/types';
import {
  KEK_ITERATIONS,
  base64ToBytes,
  bytesToBase64,
  decryptString,
  dekToMnemonic,
  deriveMasterKey,
  generateDek,
  generateSalt,
  hashRecoveryPhrase,
  mnemonicToDek,
  unwrapDek,
  wrapDek,
  wrapDekWithPassphrase,
} from '../lib/crypto';

const DEK_STORAGE_KEY = 'cw_dek';

function cacheDek(dek: Uint8Array): void {
  localStorage.setItem(DEK_STORAGE_KEY, bytesToBase64(dek));
}

function loadCachedDek(): Uint8Array | null {
  const value = localStorage.getItem(DEK_STORAGE_KEY);
  return value ? base64ToBytes(value) : null;
}

function clearCachedDek(): void {
  localStorage.removeItem(DEK_STORAGE_KEY);
}

export type AuthStatus = 'loading' | 'unauthenticated' | 'needs-passphrase' | 'ready';

interface AuthState {
  status: AuthStatus;
  user: User | null;
  dek: Uint8Array | null;
  /** Whether the backend has any users (drives first-run setup). */
  hasUsers: boolean;
  /** Shown once after signup / restore. */
  pendingRecoveryPhrase: string | null;
  error: string | null;

  bootstrap: () => Promise<void>;
  setup: (input: {
    email: string;
    password: string;
    fullName: string;
    encryptionPassphrase: string;
  }) => Promise<void>;
  register: (input: {
    email: string;
    password: string;
    fullName: string;
    inviteToken: string;
    encryptionPassphrase: string;
  }) => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  unlock: (passphrase: string) => Promise<void>;
  recoverWithPhrase: (phrase: string) => Promise<void>;
  recoverAndSetPassphrase: (phrase: string, newPassphrase: string) => Promise<void>;
  logout: () => Promise<void>;
  /** The recovery phrase for the current DEK (also refreshes the stored hash). */
  showRecoveryPhrase: () => Promise<string>;
  /** After a backup restore: drop the cached DEK and require the backup's passphrase. */
  onBackupRestored: () => void;
  clearError: () => void;
  clearPendingRecoveryPhrase: () => void;
}

function messageOf(error: unknown): string {
  if (error instanceof ApiError) return error.message;
  if (error instanceof Error) return error.message;
  return String(error);
}

/** Detect whether an envelope exists and, failing a cached DEK, require unlock. */
async function detectEnvelope(): Promise<Pick<AuthState, 'status' | 'dek'>> {
  const cached = loadCachedDek();
  if (cached) return { status: 'ready', dek: cached };

  const settings = await settingsApi.get();
  if (settings?.encrypted_dek) return { status: 'needs-passphrase', dek: null };
  // No envelope yet — treat as unlocked with no data (legacy migration is retired).
  return { status: 'ready', dek: null };
}

async function createEnvelope(passphrase: string): Promise<{ dek: Uint8Array; phrase: string }> {
  const salt = generateSalt();
  const kek = await deriveMasterKey(passphrase, salt);
  const dek = generateDek();
  const wrapped = await wrapDek(dek, kek);
  const phrase = dekToMnemonic(dek);
  const recoveryHash = await hashRecoveryPhrase(phrase);

  await settingsApi.patch({
    encrypted_dek: wrapped,
    kek_salt: bytesToBase64(salt),
    kek_iterations: KEK_ITERATIONS,
    recovery_hash: recoveryHash,
  });

  cacheDek(dek);
  return { dek, phrase };
}

/**
 * Verify a DEK by decrypting the user's settings payload — the real test of a
 * recovery phrase (robust across the old custom wordlist and the new BIP39).
 */
async function verifyDekByDecrypt(dek: Uint8Array): Promise<boolean> {
  const row = await settingsApi.get();
  const encrypted = row?.encrypted_data;
  if (!encrypted) return true; // nothing to check against yet
  try {
    await decryptString(encrypted, dek);
    return true;
  } catch {
    return false;
  }
}

/**
 * Store the recovery hash for the current (official BIP39) phrase. This is the
 * one-time migration for accounts whose hash was created with the old custom
 * wordlist.
 */
async function storeOfficialRecoveryHash(dek: Uint8Array): Promise<void> {
  const phrase = dekToMnemonic(dek);
  const hash = await hashRecoveryPhrase(phrase);
  const row = await settingsApi.get();
  if (row && row.recovery_hash !== hash) {
    await settingsApi.patch({ recovery_hash: hash });
  }
}

/** Convenience selector for the unwrapped DEK. */
export const useDek = (): Uint8Array | null => useAuthStore((state) => state.dek);

export const useAuthStore = create<AuthState>((set, get) => ({
  status: 'loading',
  user: null,
  dek: null,
  hasUsers: true,
  pendingRecoveryPhrase: null,
  error: null,

  bootstrap: async () => {
    try {
      const user = await authApi.me();
      set({ user });
      const { status, dek } = await detectEnvelope();
      set({ status, dek });
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        let hasUsers = true;
        try {
          hasUsers = (await authApi.state()).has_users;
        } catch {
          // leave the default
        }
        set({ status: 'unauthenticated', user: null, dek: null, hasUsers });
      } else {
        set({ status: 'unauthenticated', error: messageOf(error) });
      }
    }
  },

  setup: async ({ email, password, fullName, encryptionPassphrase }) => {
    set({ error: null });
    try {
      const { user } = await authApi.setup({ email, password, fullName });
      const { dek, phrase } = await createEnvelope(encryptionPassphrase);
      set({ user, dek, status: 'ready', pendingRecoveryPhrase: phrase });
    } catch (error) {
      set({ error: messageOf(error) });
      throw error;
    }
  },

  register: async ({ email, password, fullName, inviteToken, encryptionPassphrase }) => {
    set({ error: null });
    try {
      const { user } = await authApi.register({ email, password, fullName, inviteToken });
      const { dek, phrase } = await createEnvelope(encryptionPassphrase);
      set({ user, dek, status: 'ready', pendingRecoveryPhrase: phrase });
    } catch (error) {
      set({ error: messageOf(error) });
      throw error;
    }
  },

  login: async (email, password) => {
    set({ error: null });
    try {
      const { user } = await authApi.login({ email, password });
      set({ user });
      const { status, dek } = await detectEnvelope();
      set({ status, dek });
    } catch (error) {
      set({ error: messageOf(error) });
      throw error;
    }
  },

  unlock: async (passphrase) => {
    set({ error: null });
    try {
      const settings = await settingsApi.get();
      if (!settings?.encrypted_dek || !settings.kek_salt) {
        throw new Error('No encryption envelope found');
      }
      const kek = await deriveMasterKey(passphrase, base64ToBytes(settings.kek_salt));
      const dek = await unwrapDek(settings.encrypted_dek, kek);
      cacheDek(dek);
      // Migrate the stored recovery hash to the official BIP39 phrase.
      await storeOfficialRecoveryHash(dek).catch(() => {});
      set({ status: 'ready', dek });
    } catch (error) {
      set({ error: messageOf(error) });
      throw error;
    }
  },

  recoverWithPhrase: async (phrase) => {
    set({ error: null });
    try {
      const dek = mnemonicToDek(phrase);
      if (!(await verifyDekByDecrypt(dek))) {
        throw new Error('Recovery phrase is incorrect');
      }
      cacheDek(dek);
      await storeOfficialRecoveryHash(dek).catch(() => {});
      set({ status: 'ready', dek });
    } catch (error) {
      set({ error: messageOf(error) });
      throw error;
    }
  },

  recoverAndSetPassphrase: async (phrase, newPassphrase) => {
    set({ error: null });
    try {
      const dek = mnemonicToDek(phrase);
      if (!(await verifyDekByDecrypt(dek))) {
        throw new Error('Recovery phrase is incorrect');
      }
      const wrap = await wrapDekWithPassphrase(dek, newPassphrase);
      // Re-wrap under the new passphrase and record the official BIP39 hash.
      await settingsApi.patch({
        encrypted_dek: wrap.wrapped_b64,
        kek_salt: wrap.salt_b64,
        kek_iterations: wrap.iterations,
        recovery_hash: await hashRecoveryPhrase(dekToMnemonic(dek)),
      });
      cacheDek(dek);
      set({ status: 'ready', dek });
    } catch (error) {
      set({ error: messageOf(error) });
      throw error;
    }
  },

  showRecoveryPhrase: async () => {
    const dek = get().dek;
    if (!dek) throw new Error('Encryption key is not loaded');
    await storeOfficialRecoveryHash(dek).catch(() => {});
    return dekToMnemonic(dek);
  },

  logout: async () => {
    try {
      await authApi.logout();
    } catch {
      // best effort — clear locally regardless
    }
    clearCachedDek();
    set({
      status: 'unauthenticated',
      user: null,
      dek: null,
      pendingRecoveryPhrase: null,
      error: null,
    });
  },

  onBackupRestored: () => {
    // The restored envelope carries a different DEK, so forget the current one
    // and ask for the passphrase that belongs to the backup.
    clearCachedDek();
    set({ status: 'needs-passphrase', dek: null, error: null });
  },

  clearError: () => set({ error: null }),
  clearPendingRecoveryPhrase: () => set({ pendingRecoveryPhrase: null }),
}));
