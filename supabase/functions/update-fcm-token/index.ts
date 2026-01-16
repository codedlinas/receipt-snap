// Edge Function: update-fcm-token
// Registers or updates FCM token for push notifications

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { getServiceClient, getAuthenticatedUser } from '../_shared/supabase-client.ts';
import { UpdateFcmTokenRequest, CORS_HEADERS } from '../_shared/types.ts';

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  const supabase = getServiceClient();

  try {
    // Authenticate user
    const { user, error: authError } = await getAuthenticatedUser(req, supabase);
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: authError || 'Unauthorized' }),
        { status: 401, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: UpdateFcmTokenRequest = await req.json();
    const { fcm_token, device_platform, device_name } = body;

    if (!fcm_token) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing fcm_token' }),
        { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }

    if (!device_platform || !['android', 'ios'].includes(device_platform)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid device_platform (must be android or ios)' }),
        { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }

    // Check if token already exists for this user
    const { data: existingDevice } = await supabase
      .from('user_devices')
      .select('id')
      .eq('user_id', user.id)
      .eq('fcm_token', fcm_token)
      .maybeSingle();

    let device;

    if (existingDevice) {
      // Update existing device
      const { data: updatedDevice, error: updateError } = await supabase
        .from('user_devices')
        .update({
          device_platform,
          device_name: device_name || null,
          is_active: true,
          updated_at: new Date().toISOString(),
        })
        .eq('id', existingDevice.id)
        .select()
        .single();

      if (updateError) {
        throw new Error(`Failed to update device: ${updateError.message}`);
      }

      device = updatedDevice;
    } else {
      // Deactivate old tokens for this user on same platform (optional - keeps only latest)
      await supabase
        .from('user_devices')
        .update({ is_active: false })
        .eq('user_id', user.id)
        .eq('device_platform', device_platform)
        .neq('fcm_token', fcm_token);

      // Create new device record
      const { data: newDevice, error: insertError } = await supabase
        .from('user_devices')
        .insert({
          user_id: user.id,
          fcm_token,
          device_platform,
          device_name: device_name || null,
          is_active: true,
        })
        .select()
        .single();

      if (insertError) {
        throw new Error(`Failed to create device: ${insertError.message}`);
      }

      device = newDevice;
    }

    return new Response(
      JSON.stringify({
        success: true,
        device_id: device.id,
        message: existingDevice ? 'FCM token updated' : 'FCM token registered',
      }),
      { status: 200, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('update-fcm-token error:', error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    );
  }
});
