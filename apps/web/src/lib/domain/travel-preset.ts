import { type TimeLog } from './time-log';

/**
 * A named commute/work scenario. Ported from
 * `apps/web/lib/models/travel_preset.dart`.
 *
 * Morning and evening values are stored separately so asymmetrical commutes
 * (train to work, car home) work. Day logs don't store a preset id, so an
 * active day is mapped back to its preset by matching the four values.
 */
export type CommuteMode = 'none' | 'transit' | 'car' | 'vespa';

export interface TravelPreset {
  id?: string | null;
  userId?: string | null;
  name: string;
  morningOverheadMinutes: number;
  morningProductiveCommuteMinutes: number;
  eveningOverheadMinutes: number;
  eveningProductiveCommuteMinutes: number;
  commuteMode: CommuteMode;
  createdAt?: string | null;
}

export function defaultOverheadMinutes(preset: TravelPreset): number {
  return preset.morningOverheadMinutes + preset.eveningOverheadMinutes;
}

export function productiveCommuteMinutes(preset: TravelPreset): number {
  return preset.morningProductiveCommuteMinutes + preset.eveningProductiveCommuteMinutes;
}

export function usesTransit(preset: TravelPreset): boolean {
  return preset.commuteMode === 'transit';
}

export function matchesLog(preset: TravelPreset, log: TimeLog): boolean {
  return (
    preset.morningOverheadMinutes === log.morningOverheadMinutes &&
    preset.morningProductiveCommuteMinutes === log.morningProductiveCommuteMinutes &&
    preset.eveningOverheadMinutes === log.eveningOverheadMinutes &&
    preset.eveningProductiveCommuteMinutes === log.eveningProductiveCommuteMinutes
  );
}

export function findPresetForLog(presets: TravelPreset[], log: TimeLog): TravelPreset | null {
  return presets.find((preset) => matchesLog(preset, log)) ?? null;
}

/**
 * Whether the applicable commute for the current day uses transit.
 *
 * - No active day (planning): show whenever *any* preset uses transit, so a
 *   stale work-from-home selection does not hide the card.
 * - Active day: trust the day's own commute profile (matched to a preset); fall
 *   back to the last-used preset, then to visible.
 * - A finished day is handled by the caller (the card is hidden).
 */
export function commuteUsesTransit(
  presets: TravelPreset[],
  log: TimeLog | null,
  lastPresetId: string | null,
): boolean {
  const active = log != null && log.endTime == null;
  if (!active) {
    if (presets.length === 0) return true; // presets still loading
    return presets.some(usesTransit);
  }
  const match = findPresetForLog(presets, log!);
  if (match) return usesTransit(match);
  const last = presets.find((preset) => preset.id === lastPresetId);
  return last ? usesTransit(last) : true;
}

function parseCommuteMode(value: unknown): CommuteMode {
  return value === 'transit' || value === 'car' || value === 'vespa' ? value : 'none';
}

export function travelPresetFromJson(json: Record<string, any>): TravelPreset {
  const morningOverhead = json['morning_overhead_minutes'] as number | undefined;
  const morningProductive = json['morning_productive_commute_minutes'] as number | undefined;
  const eveningOverhead = json['evening_overhead_minutes'] as number | undefined;
  const eveningProductive = json['evening_productive_commute_minutes'] as number | undefined;

  const base = {
    id: (json['id'] as string | null) ?? null,
    userId: (json['user_id'] as string | null) ?? null,
    name: json['name'] as string,
    commuteMode: parseCommuteMode(json['commute_mode']),
    createdAt: (json['created_at'] as string | null) ?? null,
  };

  if (morningOverhead != null && eveningOverhead != null) {
    return {
      ...base,
      morningOverheadMinutes: morningOverhead,
      morningProductiveCommuteMinutes: morningProductive ?? 0,
      eveningOverheadMinutes: eveningOverhead,
      eveningProductiveCommuteMinutes: eveningProductive ?? 0,
    };
  }

  // Legacy format — split totals 50/50, remainder to the evening.
  const totalOverhead = (json['default_overhead_minutes'] as number | null) ?? 0;
  const totalProductive = (json['productive_commute_minutes'] as number | null) ?? 0;
  const halfOverhead = Math.trunc(totalOverhead / 2);
  const halfProductive = Math.trunc(totalProductive / 2);
  return {
    ...base,
    morningOverheadMinutes: halfOverhead,
    morningProductiveCommuteMinutes: halfProductive,
    eveningOverheadMinutes: totalOverhead - halfOverhead,
    eveningProductiveCommuteMinutes: totalProductive - halfProductive,
  };
}

export function travelPresetToJson(preset: TravelPreset): Record<string, unknown> {
  return {
    id: preset.id ?? null,
    user_id: preset.userId ?? null,
    name: preset.name,
    morning_overhead_minutes: preset.morningOverheadMinutes,
    morning_productive_commute_minutes: preset.morningProductiveCommuteMinutes,
    evening_overhead_minutes: preset.eveningOverheadMinutes,
    evening_productive_commute_minutes: preset.eveningProductiveCommuteMinutes,
    commute_mode: preset.commuteMode,
    default_overhead_minutes: defaultOverheadMinutes(preset),
    productive_commute_minutes: productiveCommuteMinutes(preset),
    created_at: preset.createdAt ?? null,
  };
}
