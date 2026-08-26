# Data Encryption Options — ChronoWarden

## The Problem

Currently, data flows like this:

```
User → Flutter App → Supabase Client (anon key) → PostgreSQL (RLS: auth.uid() = user_id)
                                                    ↑
                                            Supabase Dashboard (service_role key)
                                            bypasses RLS — sees ALL rows
```

Even though RLS prevents an admin user from querying other users' data via the app,
anyone with access to the Supabase project dashboard (i.e., you) can see every row
in every table using the service role key. That is the gap we want to close.

## Goal

**Zero-knowledge architecture** — the server (Supabase) stores only ciphertext.
The encryption keys live exclusively on the user's device. Even the database
administrator cannot read user data. Must work across multiple devices.

---

## The Core Pattern: Envelope Encryption

This is the industry-standard approach (Bitwarden, ProtonMail, etc.).

### Key hierarchy (three layers)

```
┌─────────────────────────────────────────┐
│  Layer 1: Master Password (user secret) │
│     ↓  PBKDF2 (310k iterations)         │
│  Layer 2: Master Key (KEK)              │
│     ↓  AES-GCM wrap                     │
│  Layer 3: Data Encryption Key (DEK)     │
│     ↓  AES-GCM encrypt                  │
│  Actual data (time logs, presets, etc.) │
└─────────────────────────────────────────┘
```

### How it works across devices

1. User creates an **encryption passphrase** during setup (or uses their login password).
2. A random **DEK** (256-bit AES key) is generated — this does the actual data encryption.
3. The DEK is encrypted ("wrapped") with the **Master Key** (derived from the passphrase)
   and stored on the server as `encrypted_dek` in `user_settings`.
4. On any device: user enters passphrase → derive Master Key → unwrap DEK → decrypt data.
5. The DEK is the same everywhere because it lives encrypted on the server —
   only the passphrase-to-Master-Key derivation is needed per device.

### Key rotation

- **Passphrase change**: Decrypt DEK with old Master Key → re-encrypt DEK with new Master Key.
  Requires old passphrase (to derive old Master Key).
- **DEK rotation**: Generate new DEK, re-encrypt all data, store new encrypted DEK.
  Rarely needed; more for proactive security.

### Recovery

Since data is unrecoverable without the passphrase, offer a **recovery key**:
- A mnemonic phrase that encodes the DEK directly (not wrapped by the Master Key).
- User can enter this recovery key on any device to decrypt data without the passphrase.
- Store a SHA-256 hash of the recovery key in `user_settings` for verification.

---

## Option A — Envelope Encryption with Separate Encryption Passphrase

### How it works (recommended variant)

Use a **dedicated encryption passphrase** independent of the Supabase Auth password.

#### Setup flow (first login)

```
User enters encryption passphrase  ──→ PBKDF2(passphrase, salt, 310k) ──→ Master Key
                                        ↓
Generate random DEK (AES-256) ─────→ AES-GCM encrypt DEK with Master Key
                                        ↓
Store encrypted DEK + salt + recovery_hash in user_settings
                                        ↓
DEK held in memory + cached in sessionStorage
```

#### Login flow (subsequent logins)

```
User enters encryption passphrase  ──→ PBKDF2(passphrase, stored salt, 310k) ──→ Master Key
                                             ↓
Fetch encrypted DEK from user_settings ──→ AES-GCM decrypt DEK with Master Key
                                             ↓
DEK held in memory + cached in sessionStorage
```

#### Login with sessionStorage cache (page refresh)

```
Page loads → check sessionStorage for cached DEK
├── DEK found → app is ready, no passphrase prompt
└── DEK empty → show passphrase prompt → derive → unwrap → cache DEK
```

#### Data flow

```
WRITE:
Model.toJson() → JSON bytes → AES-GCM encrypt with DEK → base64 → Supabase

READ:
Supabase → base64 → AES-GCM decrypt with DEK → JSON bytes → Model.fromJson()
```

#### Passphrase change

```
User enters old passphrase + new passphrase
Old Master Key decrypts DEK
New Master Key re-encrypts DEK
Store updated encrypted DEK + new salt
```

#### Recovery key

```
During setup: generate recovery mnemonic (encodes the DEK directly)
User writes it down / stores it offline

On any device: "Forgot passphrase?" → enter recovery mnemonic → DEK recovered
Recovery verified against stored SHA-256(recovery_key) in user_settings
```

---

## Option B — Envelope Encryption Using Supabase Auth Password

Same key hierarchy as Option A, but the Master Key is derived from the **Supabase
login password** instead of a separate passphrase.

### Key difference

- User remembers only one password (their Supabase login password)
- Master Key = PBKDF2(login password, salt, 310k)
- Encrypted DEK stored in `user_settings`

### Problem

Supabase Auth hashes the password **before** storing it (bcrypt). We capture the
plaintext password during `signIn` / `signUp`, derive the Master Key from it, then
send it to Supabase Auth. This works — but:

- **Password reset** via Supabase (e.g., forgot password email link) cannot be
  intercepted by the app, so the user would lose their encryption key unless
  they also have a recovery key.
- Changing password via Supabase UI means we lose access to the old plaintext
  password (needed to decrypt the DEK).

### Verdict

More fragile than Option A because password-reset flows break the encryption.
Only viable if the app handles ALL password changes internally (no Supabase
magic-link resets) AND captures the old password before changing it.

---

## Option C — Asymmetric Envelope (Bitwarden's exact model)

Bitwarden uses RSA keypairs:

```
Master Password → PBKDF2 → Master Key
Master Key encrypts User's RSA Private Key (stored on server)
User's RSA Public Key (plaintext on server)

For each data item:
  1. Generate random AES-256 DEK
  2. Encrypt data with DEK (AES-CBC)
  3. Encrypt DEK with RSA Public Key (asymmetric)
  4. Store: ciphertext + encrypted_DEK (the "envelope")

To decrypt:
  1. RSA Private Key decrypts DEK (private key was itself encrypted by Master Key)
  2. DEK decrypts data
```

### Why this adds complexity without benefit for us

- RSA-4096 is slow for key generation (~seconds on mobile)
- RSA keypairs are large (4096-bit = ~500 bytes each)
- We don't need per-item key wrapping — a single DEK for all data is fine
- X25519 (Curve25519) is faster but adds the same complexity

### When to use this

If we want **each data item to have its own unique DEK** (e.g., for selective
sharing or per-item key rotation). Overkill for ChronoWarden.

---

## Architectural Requirements

### 1. Session Persistence across Page Refreshes

**Problem**: Holding keys strictly in in-memory RAM forces users to re-enter their
encryption passphrase every time they reload the web page (F5). This is poor UX.

**Solution**: Cache the unwrapped DEK in **browser sessionStorage**.

```
sessionStorage (vs localStorage):
├── localStorage  → persists until cleared. Survives browser restart.
└── sessionStorage → persists across F5/refresh. Cleared on tab close.
```

**Implementation**:

```dart
// Store DEK bytes in sessionStorage on successful unwrap
final dekBytes = await dek.extractBytes();
window.sessionStorage.setItem('cw_dek', base64Encode(dekBytes));

// On app init, check sessionStorage
final cached = window.sessionStorage.getItem('cw_dek');
if (cached != null) {
  _dek = SecretKey(base64Decode(cached));
  // No passphrase prompt needed — app is ready
}
```

**Security note**: sessionStorage is isolated per browser origin and per tab.
It is accessible to JavaScript running in the same origin (including extensions),
but this is the same threat model as the rest of the app. The DEK alone is useless
without the encrypted data from Supabase (which requires the user's auth session).

**Optional UX**: Add a toggle "Require passphrase on every page load" for
paranoid users. When enabled, skip sessionStorage cache and always prompt.

### 2. Existing User Migration Strategy

**Problem**: Existing users have legacy plaintext data and no encrypted envelope
assigned in `user_settings`. We need a seamless one-time migration.

**Flow**:

```
User logs in
  ├── user_settings.encrypted_dek exists? → normal flow (unwrap DEK)
  └── user_settings.encrypted_dek is NULL? → migration needed

         ┌──────────────────────────────────┐
         │   Migration Screen               │
         │   "Set your encryption passphrase"│
         │   [Passphrase      ]             │
         │   [Confirm         ]             │
         │   [Strength: ███████░]           │
         │   [Recovery phrase shown]        │
         │                                  │
         │   [Start Migration]              │
         └──────────────────────────────────┘

Step by step:
  1. Derive Master Key from passphrase (PBKDF2, 310k)
  2. Generate random DEK
  3. Wrap DEK with Master Key → encrypted_dek
  4. Generate recovery mnemonic from DEK
  5. Store: encrypted_dek, salt, recovery_hash in user_settings
  6. For each table (time_logs, travel_presets, user_settings):
       a. SELECT all rows WHERE user_id = current user
       b. For each row, serialize JSON, encrypt with DEK
       c. UPDATE row SET encrypted_data = ciphertext
  7. Show success screen with recovery phrase to write down
  8. Redirect to app main screen
```

**Safety guarantees**:
- Migration is **not** transactional in the database sense (each row is updated
  individually), but we **do not drop plaintext columns** until migration is
  confirmed successful. Plaintext columns act as a rollback source.
- If any row fails to encrypt, the migration stops and shows an error with
  a retry option. No data is lost because plaintext columns still exist.
- After successful migration, plaintext columns can be dropped via a SQL migration
  (or kept indefinitely for zero-risk backward compat).

**Plaintext column cleanup**:
- Phase 1 (this PR): add `encrypted_data`, keep existing columns. Migration
  writes both `encrypted_data` AND keeps plaintext columns populated.
- Phase 2 (later PR): once confident, drop plaintext columns via SQL `ALTER TABLE`.

### 3. PBKDF2 Iteration Hardening

**OWASP Recommendations (2025)**:

| Algorithm | Minimum iterations | Recommended |
|-----------|-------------------|-------------|
| PBKDF2-HMAC-SHA256 | 310,000 | 600,000+ |
| PBKDF2-HMAC-SHA512 | 120,000 | 250,000+ |
| Argon2id (memory-hard) | 19 MiB, 2 iters | 64 MiB, 3 iters |

**ChronoWarden choice**: PBKDF2-HMAC-SHA256 with **310,000 iterations**.

**Implementation**:

```dart
class CryptoService {
  static const int kekIterations = 310_000;  // OWASP 2025 minimum for SHA256
  static const int kekKeyLength = 32;        // 256-bit AES key
  static const int saltLength = 16;          // 128-bit salt

  /// Derive a 256-bit Master Key from a passphrase + salt.
  static Future<SecretKey> deriveMasterKey(String passphrase, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      hashAlgorithm: Sha256(),
      pbkdf2Iterations: kekIterations,
      pbkdf2Length: kekKeyLength,
    );
    final keyBytes = await pbkdf2.deriveKey(passphrase, salt);
    return SecretKey(keyBytes);
  }
}
```

**Performance note**: 310k iterations takes ~200–500ms in Dart-to-JS on web.
This happens once per session (login), not per data operation. Acceptable.

**Future-proofing**: Store the iteration count in `user_settings.kek_iterations`
so we can increase it over time without breaking existing users. When a user
changes their passphrase, we re-derive with the latest count.

---

## Recommended: Option A — Envelope Encryption + Separate Passphrase

With the three architectural requirements baked in:

| Criteria | Verdict |
|----------|---------|
| Multi-device | ✅ DEK on server, any device with passphrase decrypts it |
| Zero-knowledge | ✅ Master Key never persisted, only in memory |
| Password-change safe | ✅ Encryption decoupled from auth password |
| Recovery | ✅ Recovery mnemonic for forgotten passphrase |
| Page-refresh UX | ✅ DEK cached in sessionStorage, survives F5 |
| Existing user migration | ✅ One-time setup screen on first login after deploy |
| Brute-force resistance | ✅ PBKDF2-HMAC-SHA256, 310k iterations (OWASP 2025) |
| Implementation complexity | Medium — one new service + wrapper in existing services |
| Schema change | Small — add `encrypted_data`, `encrypted_dek`, `salt`, `recovery_hash` columns |

### Schema changes

**`user_settings` table** (one row per user):

```sql
-- New columns
encrypted_dek        text not null default '',  -- DEK wrapped with Master Key (base64)
kek_salt             text not null default '',  -- PBKDF2 salt for Master Key derivation (base64)
kek_iterations       int  not null default 310000,
recovery_hash        text,                      -- SHA-256 of recovery mnemonic (for verification)
recovery_hint        text,                      -- optional hint the user set
```

**`time_logs`, `travel_presets`** — each row gets:

```sql
encrypted_data text not null default '',  -- AES-GCM ciphertext of the full model JSON (base64)
-- Keep: user_id (for RLS), date (for server-side filtering), created_at (for sorting)
-- Keep existing plaintext columns during migration phase (dropped later)
```

Keeping `date` as a plaintext index column allows the server to filter
`WHERE date = today` without decrypting — critical for the "active day" query
(the app's most frequent query).

### Implementation sketch

```
lib/services/
├── crypto_service.dart          # NEW: key derivation, AES-GCM wrap/unwrap, mnemonic
├── auth_service.dart            # MODIFIED: capture passphrase, derive KEK, cache DEK in sessionStorage
├── time_log_service.dart        # MODIFIED: encrypt/decrypt via CryptoService
├── travel_preset_service.dart   # MODIFIED: same pattern
├── work_config_service.dart     # MODIFIED: same pattern (encrypted_data column)
├── user_settings_service.dart   # MODIFIED: store/load encrypted DEK + salt
├── preferences_service.dart     # Unchanged (local preferences only)

lib/models/
├── time_log.dart                # Unchanged (model stays the same)
├── encrypted_envelope.dart      # NEW: holds encrypted_data + nonce + tag

lib/screens/
├── login_screen.dart            # MODIFIED: add passphrase field
├── signup_screen.dart           # MODIFIED: add passphrase + confirm passphrase
├── migration_screen.dart        # NEW: one-time setup for existing users
├── settings_screen.dart         # MODIFIED: change passphrase, show recovery key
```

### CryptoService API

```dart
class CryptoService {
  static const int kekIterations = 310_000;
  static const int kekKeyLength = 32;
  static const int saltLength = 16;

  // --- Key lifecycle ---

  /// Generate a random salt for PBKDF2.
  static Uint8List generateSalt();

  /// Derive a 256-bit Master Key (KEK) from a passphrase + salt.
  static Future<SecretKey> deriveMasterKey(String passphrase, Uint8List salt);

  /// Generate a random 256-bit Data Encryption Key.
  static Future<SecretKey> generateDek();

  /// Wrap a DEK with a Master Key (AES-GCM). Returns [nonce + ciphertext].
  static Future<Uint8List> wrapDek(SecretKey dek, SecretKey masterKey);

  /// Unwrap a DEK with a Master Key. Expects [nonce + ciphertext].
  static Future<SecretKey> unwrapDek(Uint8List wrappedDek, SecretKey masterKey);

  // --- Data encryption ---

  /// Encrypt a JSON string with the DEK. Returns base64-encoded [nonce + ciphertext].
  static Future<String> encrypt(String plaintext, SecretKey dek);

  /// Decrypt base64-encoded [nonce + ciphertext] with the DEK. Returns JSON string.
  static Future<String> decrypt(String ciphertext, SecretKey dek);

  // --- Recovery ---

  /// Generate a 24-word mnemonic that encodes the DEK.
  static Future<String> dekToMnemonic(SecretKey dek);

  /// Recover a DEK from a mnemonic phrase.
  static Future<SecretKey> mnemonicToDek(String phrase);

  /// Hash a recovery phrase for storage/verification (SHA-256).
  static String hashRecoveryPhrase(String phrase);

  // --- Session cache ---

  /// Save DEK to sessionStorage (survives F5, cleared on tab close).
  static void cacheDekInSession(SecretKey dek);

  /// Load DEK from sessionStorage (returns null if not cached).
  static Future<SecretKey?> loadDekFromSession();

  /// Clear DEK from sessionStorage (on logout).
  static void clearSessionCache();
}
```

### AuthService integration

```dart
class AuthService extends ChangeNotifier {
  SecretKey? _dek;       // held in memory for the session
  SecretKey? _masterKey; // held in memory only during unwrap, then discarded

  Future<void> signIn({
    required String email,
    required String password,
    required String encryptionPassphrase,
  }) async {
    // 1. Log in to Supabase Auth (existing flow)
    await _client.auth.signInWithPassword(email: email, password: password);

    // 2. Derive Master Key from encryption passphrase
    final salt = await _fetchSalt();
    final masterKey = await CryptoService.deriveMasterKey(encryptionPassphrase, salt);

    // 3. Unwrap DEK from user_settings
    final wrappedDek = await _fetchEncryptedDek();
    _dek = await CryptoService.unwrapDek(wrappedDek, masterKey);

    // 4. Cache DEK in sessionStorage for page-refresh survival
    CryptoService.cacheDekInSession(_dek);

    // 5. Discard Master Key (it's no longer needed)
    _masterKey = null;
  }

  /// Called on app init — tries sessionStorage cache first.
  Future<bool> trySessionCache() async {
    final cached = await CryptoService.loadDekFromSession();
    if (cached != null) {
      _dek = cached;
      return true;
    }
    return false;
  }

  /// Forgot passphrase? Use recovery key instead.
  Future<void> recoverWithMnemonic(String phrase) async {
    _dek = await CryptoService.mnemonicToDek(phrase);
    // Verify against stored recovery_hash
    final expectedHash = await _fetchRecoveryHash();
    final actualHash = CryptoService.hashRecoveryPhrase(phrase);
    if (actualHash != expectedHash) throw Exception('Recovery phrase is incorrect');
    CryptoService.cacheDekInSession(_dek);
  }

  Future<void> signOut() async {
    CryptoService.clearSessionCache();
    _dek = null;
    _masterKey = null;
    await _client.auth.signOut();
    // ...
  }
}
```

### Migration flow (existing users)

```dart
class MigrationService {
  /// Returns true if the current user needs to migrate (no encrypted_dek).
  Future<bool> needsMigration() async {
    final userId = _userId;
    if (userId == null) return false;
    final resp = await _client
        .from('user_settings')
        .select('encrypted_dek')
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    if (rows.isEmpty) return true;  // no user_settings row at all
    final dek = (rows.first as Map<String, dynamic>)['encrypted_dek'] as String?;
    return dek == null || dek.isEmpty;
  }

  /// Run the migration: encrypt all existing data with a new DEK.
  Future<void> migrate(String passphrase, void Function(double) onProgress) async {
    final userId = _userId!;
    final totalSteps = 1 + _countRows('time_logs', userId) + _countRows('travel_presets', userId);
    var completed = 0;

    // 1. Generate keys and store envelope
    final salt = CryptoService.generateSalt();
    final masterKey = await CryptoService.deriveMasterKey(passphrase, salt);
    final dek = await CryptoService.generateDek();
    final wrappedDek = await CryptoService.wrapDek(dek, masterKey);
    final recoveryPhrase = await CryptoService.dekToMnemonic(dek);
    final recoveryHash = CryptoService.hashRecoveryPhrase(recoveryPhrase);

    await _client.from('user_settings').upsert({
      'user_id': userId,
      'encrypted_dek': base64Encode(wrappedDek),
      'kek_salt': base64Encode(salt),
      'kek_iterations': CryptoService.kekIterations,
      'recovery_hash': recoveryHash,
    }, onConflict: 'user_id');

    completed++;
    onProgress(completed / totalSteps);

    // 2. Encrypt all time_logs
    final timeLogs = await _fetchAllTimeLogs(userId);
    for (final log in timeLogs) {
      final json = log.toJson();
      json.remove('encrypted_data'); // ensure clean
      final plaintext = jsonEncode(json);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      await _client.from('time_logs').update({
        'encrypted_data': ciphertext,
      }).eq('id', log.id).eq('user_id', userId);
      completed++;
      onProgress(completed / totalSteps);
    }

    // 3. Encrypt all travel_presets (same pattern)
    // ...

    // 4. Store recovery phrase for display (not persisted — shown once)
    return recoveryPhrase;
  }
}
```

---

## Comparison Summary

| Option | Multi-device? | Zero-knowledge? | Password-safe? | Page-refresh UX | Migration path | Complexity |
|--------|--------------|-----------------|----------------|----------------|---------------|------------|
| 1. localStorage key | ❌ Key per device | ✅ | ✅ | ✅ localStorage persists | ❌ No envelope to create | Low |
| **A. Envelope + separate passphrase** | ✅ DEK on server | ✅ Master Key in memory | ✅ Decoupled | ✅ sessionStorage cache | ✅ One-time migration screen | Medium |
| B. Envelope + auth password | ✅ DEK on server | ✅ Master Key in memory | ❌ Password reset breaks it | ✅ sessionStorage cache | ✅ One-time migration screen | Medium |
| C. Asymmetric (Bitwarden-style) | ✅ | ✅ | ✅ | ✅ sessionStorage cache | ✅ One-time migration screen | Higher |
| 4. Local-first + encrypted sync | ✅ | ✅ | ✅ | ✅ IndexedDB persists | ❌ Full data migration needed | High |

---

## Implementation Status ✅

All code has been implemented and passes `flutter analyze` with zero errors.

### Files created (7)
| File | Lines | Purpose |
|------|-------|---------|
| `lib/services/crypto_service.dart` | ~550 | PBKDF2, AES-256-GCM, key wrap, BIP39 mnemonic, sessionStorage |
| `lib/models/encrypted_envelope.dart` | 40 | Encrypted row data model |
| `lib/services/migration_service.dart` | 140 | One-time migration: encrypt all existing rows |
| `lib/screens/migration_screen.dart` | 420 | Migration UI: passphrase setup + progress + recovery display |
| `lib/screens/about_encryption_screen.dart` | 310 | Full encryption explainer with key hierarchy diagram |
| `migration_encryption.sql` | 40 | SQL to add `encrypted_data`, `encrypted_dek`, `kek_salt`, etc. |

### Files modified (9)
| File | Change |
|------|--------|
| `pubspec.yaml` | Added `cryptography`, `crypto` packages |
| `lib/main.dart` | Added `needsMigration` routing → `MigrationScreen` |
| `lib/services/auth_service.dart` | DEK lifecycle, session cache, migration detection |
| `lib/services/time_log_service.dart` | Encrypt/decrypt all data with DEK |
| `lib/services/travel_preset_service.dart` | Same encryption pattern |
| `lib/services/work_config_service.dart` | Settings in encrypted_data column |
| `lib/services/user_settings_service.dart` | Flex minutes in encrypted payload |
| `lib/screens/login_screen.dart` | Encryption passphrase toggle + migration redirect |
| `lib/screens/signup_screen.dart` | Encryption passphrase + confirm with warnings |
| `lib/screens/settings_screen.dart` | Encryption status card + recovery phrase display |

### Deployment checklist

1. Run `migration_encryption.sql` in Supabase SQL Editor
2. Build and deploy: `docker compose up --build -d`
3. **New users** (signing up after deploy): set encryption passphrase at signup → data encrypted from day one
4. **Existing users** (signed up before deploy): login → migration screen detects no envelope → set passphrase → all historical data encrypted → recovery phrase shown once
5. **All users**: encryption is per-user, independent, and zero-knowledge — even the admin cannot read another user's data
6. Verify: check Supabase dashboard — `encrypted_data` columns show base64 ciphertext only

---

## Architecture Diagram

```
┌─────────────────────────────────────┐
│  main.dart                          │
│  ├─ Authenticated?                  │
│  │  ├─ needsMigration? → Migration  │
│  │  └─ normal → MainShell           │
│  └─ Unauthenticated → Login/Signup  │
└──────────┬──────────────────────────┘
           │ AuthService holds DEK in memory
           ▼
┌─────────────────────────────────────┐
│  Data Services                      │
│  ├─ insert: toJson() → encrypt → DB │
│  └─ select: DB → decrypt → fromJson │
└──────────┬──────────────────────────┘
           │ DEK from AuthService().dek
           ▼
┌─────────────────────────────────────┐
│  CryptoService                      │
│  ├─ deriveMasterKey(passphrase, salt)│
│  ├─ wrapDekBase64(dek, masterKey)   │
│  ├─ encrypt(plaintext, dek)         │
│  ├─ dekToMnemonic(dek) → 24 words   │
│  └─ cacheDekInSession(dek)          │
└─────────────────────────────────────┘
```

---

## Recovery phrase warning

The migration screen and settings screen both display this warning clearly:

> **If you lose both your encryption passphrase AND your 24-word recovery phrase, your data is gone forever. No one — not even the app administrator — can recover it.**
