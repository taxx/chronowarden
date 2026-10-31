import { travelPresetsApi } from '../api/travel-presets';
import type { TravelPresetRow } from '../api/types';
import { decryptString, encryptString } from '../lib/crypto';
import { travelPresetFromJson, travelPresetToJson, type TravelPreset } from '../lib/domain/travel-preset';

async function decryptPresetRow(row: TravelPresetRow, dek: Uint8Array | null): Promise<TravelPreset | null> {
  if (!dek || !row.encrypted_data) return null;
  try {
    const json = JSON.parse(await decryptString(row.encrypted_data, dek)) as Record<string, unknown>;
    json['id'] = row.id;
    json['user_id'] = row.user_id;
    json['name'] = row.name;
    json['created_at'] = row.created_at;
    return travelPresetFromJson(json);
  } catch {
    return null;
  }
}

function payloadFor(preset: TravelPreset): Record<string, unknown> {
  const json = travelPresetToJson(preset);
  delete json['id'];
  delete json['user_id'];
  delete json['created_at'];
  return json;
}

export async function listTravelPresets(dek: Uint8Array | null): Promise<TravelPreset[]> {
  const rows = await travelPresetsApi.list();
  const presets: TravelPreset[] = [];
  for (const row of rows) {
    const preset = await decryptPresetRow(row, dek);
    if (preset) presets.push(preset);
  }
  return presets;
}

export async function createTravelPreset(preset: TravelPreset, dek: Uint8Array): Promise<TravelPreset> {
  const ciphertext = await encryptString(JSON.stringify(payloadFor(preset)), dek);
  const row = await travelPresetsApi.create({ name: preset.name, encrypted_data: ciphertext });
  const decrypted = await decryptPresetRow(row, dek);
  if (!decrypted) throw new Error('Failed to decrypt the inserted preset');
  return decrypted;
}

/** Merge snake_case [fields] into an existing preset's encrypted payload. */
export async function updateTravelPreset(
  id: string,
  fields: Record<string, unknown>,
  dek: Uint8Array,
): Promise<void> {
  const row = await travelPresetsApi.get(id);
  if (!row.encrypted_data) return;

  const existing = JSON.parse(await decryptString(row.encrypted_data, dek)) as Record<string, unknown>;
  delete existing['id'];
  delete existing['user_id'];
  delete existing['created_at'];
  Object.assign(existing, fields);

  const name = typeof fields['name'] === 'string' ? (fields['name'] as string) : undefined;
  await travelPresetsApi.update(id, {
    ...(name ? { name } : {}),
    encrypted_data: await encryptString(JSON.stringify(existing), dek),
  });
}

export async function deleteTravelPreset(id: string): Promise<void> {
  await travelPresetsApi.remove(id);
}
