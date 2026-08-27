# Legacy Column Cleanup Plan

## Current state (verified)

| Table | Total rows | Encrypted | Legacy still present? |
|-------|-----------|-----------|----------------------|
| `user_settings` | 3 | 3 ✅ | Yes — plaintext columns still exist |
| `time_logs` | 227 | 227 ✅ | Yes — plaintext columns still exist |
| `travel_presets` | 7 | 7 ✅ | Yes — plaintext columns still exist |

All users have completed migration. No data is read from legacy columns anymore — they are ignored by the app. Time to drop them.

---

## Phase 1 — SQL to drop legacy columns

### 1a. Backup first (we already have one)

The backup `chronowarden_backup_2026-08-26.tar` is in the project directory.

### 1b. Drop legacy columns from `time_logs`

```sql
alter table time_logs
  drop column if exists start_time,
  drop column if exists end_time,
  drop column if exists expected_minutes,
  drop column if exists lunch_minutes,
  drop column if exists flex_minutes,
  drop column if exists morning_overhead_minutes,
  drop column if exists morning_productive_commute_minutes,
  drop column if exists evening_overhead_minutes,
  drop column if exists evening_productive_commute_minutes,
  drop column if exists overhead_minutes,
  drop column if exists productive_commute_minutes,
  drop column if exists overtime_minutes,
  drop column if exists note;
```

### 1c. Drop legacy columns from `travel_presets`

```sql
alter table travel_presets
  drop column if exists default_overhead_minutes,
  drop column if exists productive_commute_minutes,
  drop column if exists morning_overhead_minutes,
  drop column if exists morning_productive_commute_minutes,
  drop column if exists evening_overhead_minutes,
  drop column if exists evening_productive_commute_minutes;
```

### 1d. Drop legacy columns from `user_settings`

```sql
alter table user_settings
  drop column if exists default_flex_minutes,
  drop column if exists default_expected_minutes,
  drop column if exists reduced_expected_minutes,
  drop column if exists reduced_start_week,
  drop column if exists reduced_end_week;
```

---

## Phase 2 — Remove fallback code from Dart services

After dropping columns, the plaintext fallback in data services would crash (it tries to read columns that don't exist). We must remove it.

### 2a. `TimeLogService._decryptTimeLog`

Remove the pre-migration fallback branch. The method should ONLY decrypt from `encrypted_data`. If `encrypted_data` is empty, return null.

```dart
// Before (current):
if (encrypted == null || encrypted.isEmpty) {
  return TimeLog.fromJson(row);  // <-- reads legacy columns
}

// After (cleanup):
if (encrypted == null || encrypted.isEmpty) {
  return null;
}
```

### 2b. `TravelPresetService._decryptPreset`

Same change — remove the `TimeLog.fromJson(row)` fallback.

### 2c. `WorkConfigService.get()`

Remove the `WorkConfig.fromJson(row)` fallback. Return null if no encrypted_data.

### 2d. `UserSettingsService._readSettings()`

Remove the plaintext column copying fallback. Return empty map if no encrypted_data.

### 2e. `TimeLogService.insert()` and `update()`

Remove the pre-migration branches that write to plaintext columns.

### 2f. `TravelPresetService.insert()` and `update()`

Same — remove pre-migration branches.

### 2g. `WorkConfigService.save()` and `UserSettingsService.setDefaultFlexMinutes()`

Remove pre-migration branches.

---

## Phase 3 — Clean up `AuthService`

### 3a. Remove `needsMigration` — no longer needed since all users are migrated.

### 3b. Keep `needsPassphrase` — still needed for users on new devices.

---

## Phase 4 — Clean up `MigrationScreen` and `MigrationService`

These become dead code since no user will ever need to migrate. They can be removed.

---

## Phase 5 — Remove `signInWithoutEncryption` from `AuthService`

All users now have encryption. The password-only login path is no longer needed.

---

## Execution order

```
1. Run SQL to drop columns
2. Update Dart code to remove fallbacks
3. Deploy
4. Verify app works with encrypted data only
5. Remove dead code (migration screen, migration service, signInWithoutEncryption)
6. Deploy again
```

## Rollback plan

If something goes wrong after dropping columns:
1. Restore from `chronowarden_backup_2026-08-26.tar`
2. The encrypted data is still in `encrypted_data` columns — no data loss
3. But the plaintext columns are gone — can't fall back
4. Solution: deploy the cleaned Dart code (without fallbacks) immediately

This means **Phase 2 and Phase 1 must be done together** — deploy the cleaned Dart code at the same time as the SQL migration. Don't drop columns before the app stops reading them.
