/**
 * Per-user transit integration preferences, stored encrypted in
 * `user_settings.encrypted_data` under `transit_config`.
 *
 * Ported from `apps/web/lib/models/transit_config.dart`. Stop IDs are Journey
 * Planner global IDs (e.g. `9091001001009638`).
 */
export interface TransitConfig {
  enabled: boolean;
  workStopId: string;
  workStopName: string;
  homeStopId: string;
  homeStopName: string;
  /** Legacy SL site IDs (optional). */
  workSiteId: number;
  homeSiteId: number;
  walkHomeMinutes: number;
  walkWorkMinutes: number;
}

export const defaultTransitConfig: TransitConfig = {
  enabled: false,
  workStopId: '',
  workStopName: '',
  homeStopId: '',
  homeStopName: '',
  workSiteId: 0,
  homeSiteId: 0,
  walkHomeMinutes: 5,
  walkWorkMinutes: 5,
};

export function hasWork(config: TransitConfig): boolean {
  return config.workStopId !== '' && config.workStopName !== '';
}

export function hasHome(config: TransitConfig): boolean {
  return config.homeStopId !== '' && config.homeStopName !== '';
}

export function totalWalkMinutes(config: TransitConfig): number {
  return config.walkHomeMinutes + config.walkWorkMinutes;
}

/** Morning = home → work; otherwise work → home. */
export function originStopId(config: TransitConfig, morning: boolean): string {
  return morning ? config.homeStopId : config.workStopId;
}

export function destStopId(config: TransitConfig, morning: boolean): string {
  return morning ? config.workStopId : config.homeStopId;
}

export function walkMinutes(config: TransitConfig, morning: boolean): number {
  return morning ? config.walkHomeMinutes : config.walkWorkMinutes;
}

export function directionLabel(config: TransitConfig, morning: boolean): string {
  return morning
    ? `${config.homeStopName} → ${config.workStopName}`
    : `${config.workStopName} → ${config.homeStopName}`;
}

export function transitConfigFromJson(json: Record<string, unknown>): TransitConfig {
  return {
    enabled: (json['enabled'] as boolean | null) ?? false,
    workStopId: (json['work_stop_id'] as string | null) ?? '',
    workStopName: (json['work_stop_name'] as string | null) ?? '',
    homeStopId: (json['home_stop_id'] as string | null) ?? '',
    homeStopName: (json['home_stop_name'] as string | null) ?? '',
    workSiteId: (json['work_site_id'] as number | null) ?? 0,
    homeSiteId: (json['home_site_id'] as number | null) ?? 0,
    walkHomeMinutes: (json['walk_home_minutes'] as number | null) ?? 5,
    walkWorkMinutes: (json['walk_work_minutes'] as number | null) ?? 5,
  };
}

export function transitConfigToJson(config: TransitConfig): Record<string, unknown> {
  return {
    enabled: config.enabled,
    work_stop_id: config.workStopId,
    work_stop_name: config.workStopName,
    home_stop_id: config.homeStopId,
    home_stop_name: config.homeStopName,
    work_site_id: config.workSiteId,
    home_site_id: config.homeSiteId,
    walk_home_minutes: config.walkHomeMinutes,
    walk_work_minutes: config.walkWorkMinutes,
  };
}
