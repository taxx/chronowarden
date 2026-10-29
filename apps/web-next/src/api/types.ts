/** API DTOs (mirrors the Hono API's response shapes). */

export type Role = 'admin' | 'user';
export type Status = 'pending' | 'approved' | 'rejected';

export interface User {
  id: string;
  email: string;
  role: Role;
  status: Status;
  full_name: string | null;
  created_at: string;
}

export interface SessionResponse {
  token: string;
  user: User;
}

export interface SettingsRow {
  id: string;
  user_id: string;
  encrypted_dek: string;
  kek_salt: string;
  kek_iterations: number;
  recovery_hash: string | null;
  encrypted_data: string;
  created_at: string;
  updated_at: string | null;
}

export interface Invite {
  id: string;
  email: string;
  role: Role;
  used_at: string | null;
  expires_at: string;
  created_at: string;
  /** Only present on creation. */
  token?: string;
}

export interface TimeLogRow {
  id: string;
  user_id: string;
  date: string;
  encrypted_data: string;
  created_at: string;
}

export interface TravelPresetRow {
  id: string;
  user_id: string;
  name: string;
  encrypted_data: string;
  created_at: string;
}

export interface StateResponse {
  has_users: boolean;
}

export interface ApiErrorBody {
  error: { code: string; message: string };
}
