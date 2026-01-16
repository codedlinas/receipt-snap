// Shared types for Receipt Snap Edge Functions

export interface ProcessReceiptRequest {
  image_base64: string;
  filename?: string;
  mime_type?: string;
}

export interface ExtractionResult {
  subscription_name: string;
  billing_entity: string | null;
  amount: number;
  currency: string;
  billing_cycle: 'weekly' | 'monthly' | 'quarterly' | 'semi_annual' | 'annual' | 'one_time' | 'unknown';
  start_date: string | null;
  next_charge_date: string | null;
  payment_method: string | null;
  renewal_terms: string | null;
  cancellation_policy: string | null;
  cancellation_deadline: string | null;
  confidence_score: number;
  raw_text: string;
}

export interface UpdateFcmTokenRequest {
  fcm_token: string;
  device_platform: 'android' | 'ios';
  device_name?: string;
}

export interface Subscription {
  id: string;
  user_id: string;
  receipt_id: string | null;
  subscription_name: string;
  billing_entity: string | null;
  amount: number;
  currency: string;
  billing_cycle: string;
  start_date: string | null;
  next_charge_date: string | null;
  last_charge_date: string | null;
  cancellation_deadline: string | null;
  payment_method: string | null;
  renewal_terms: string | null;
  cancellation_policy: string | null;
  is_active: boolean;
  is_deleted: boolean;
  confidence_score: number | null;
  user_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface Receipt {
  id: string;
  user_id: string;
  storage_path: string;
  original_filename: string | null;
  file_size_bytes: number | null;
  mime_type: string | null;
  processing_status: 'pending' | 'processing' | 'completed' | 'failed';
  raw_llm_response: ExtractionResult | null;
  error_message: string | null;
  created_at: string;
  processed_at: string | null;
}

export interface User {
  id: string;
  email: string;
  display_name: string | null;
  timezone: string;
  notification_preferences: {
    renewal_3d: boolean;
    renewal_1d: boolean;
    weekly_summary: boolean;
  };
  created_at: string;
  updated_at: string;
}

export interface UserDevice {
  id: string;
  user_id: string;
  fcm_token: string;
  device_platform: 'android' | 'ios';
  device_name: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface FcmPayload {
  to: string;
  notification: {
    title: string;
    body: string;
  };
  data: Record<string, string>;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

export const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-client-info, apikey',
};
