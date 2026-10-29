import { settingsApi } from '../api/settings';
import { decryptString, encryptString } from '../lib/crypto';
import {
  workConfigFromJson,
  workConfigToJson,
  type WorkConfig,
} from '../lib/domain/work-config';
import {
  defaultTransitConfig,
  transitConfigFromJson,
  transitConfigToJson,
  type TransitConfig,
} from '../lib/domain/transit-config';

export type SettingsMap = Record<string, unknown>;

/** Read and decrypt the settings payload ({} when there is none). */
export async function readSettings(dek: Uint8Array | null): Promise<SettingsMap> {
  if (!dek) return {};
  const row = await settingsApi.get();
  if (!row?.encrypted_data) return {};
  try {
    return JSON.parse(await decryptString(row.encrypted_data, dek)) as SettingsMap;
  } catch {
    return {};
  }
}

/** Encrypt and persist the whole settings payload. */
export async function writeSettings(settings: SettingsMap, dek: Uint8Array): Promise<void> {
  await settingsApi.patch({ encrypted_data: await encryptString(JSON.stringify(settings), dek) });
}

export async function getWorkConfig(dek: Uint8Array | null): Promise<WorkConfig | null> {
  const settings = await readSettings(dek);
  if (!('default_expected_minutes' in settings)) return null;
  return workConfigFromJson(settings);
}

export async function saveWorkConfig(config: WorkConfig, dek: Uint8Array): Promise<void> {
  const settings = await readSettings(dek);
  Object.assign(settings, workConfigToJson(config));
  await writeSettings(settings, dek);
}

export async function getTransitConfig(dek: Uint8Array | null): Promise<TransitConfig> {
  const settings = await readSettings(dek);
  const raw = settings['transit_config'];
  if (raw && typeof raw === 'object') {
    return transitConfigFromJson(raw as Record<string, unknown>);
  }
  return defaultTransitConfig;
}

export async function saveTransitConfig(config: TransitConfig, dek: Uint8Array): Promise<void> {
  const settings = await readSettings(dek);
  settings['transit_config'] = transitConfigToJson(config);
  await writeSettings(settings, dek);
}
