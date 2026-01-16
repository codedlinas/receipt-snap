// Edge Function: notify-renewals
// Scheduled cron job that sends push notifications for upcoming subscription renewals

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { getServiceClient } from '../_shared/supabase-client.ts';
import { sendPushNotification, buildRenewalNotification } from '../_shared/fcm-client.ts';
import { CORS_HEADERS } from '../_shared/types.ts';

interface SubscriptionWithUser {
  id: string;
  subscription_name: string;
  amount: number;
  currency: string;
  next_charge_date: string;
  user_id: string;
  users: {
    id: string;
    notification_preferences: {
      renewal_3d: boolean;
      renewal_1d: boolean;
      weekly_summary: boolean;
    };
  };
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  const supabase = getServiceClient();
  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];

  // Calculate target dates
  const in1Day = new Date(today);
  in1Day.setDate(in1Day.getDate() + 1);
  const in1DayStr = in1Day.toISOString().split('T')[0];

  const in3Days = new Date(today);
  in3Days.setDate(in3Days.getDate() + 3);
  const in3DaysStr = in3Days.toISOString().split('T')[0];

  console.log(`Checking renewals for ${in1DayStr} and ${in3DaysStr}`);

  try {
    // Query subscriptions due in 1 or 3 days with user preferences
    const { data: upcomingSubscriptions, error } = await supabase
      .from('subscriptions')
      .select(`
        id,
        subscription_name,
        amount,
        currency,
        next_charge_date,
        user_id,
        users!inner (
          id,
          notification_preferences
        )
      `)
      .eq('is_active', true)
      .eq('is_deleted', false)
      .or(`next_charge_date.eq.${in1DayStr},next_charge_date.eq.${in3DaysStr}`);

    if (error) {
      console.error('Error fetching subscriptions:', error);
      return new Response(
        JSON.stringify({ success: false, error: error.message }),
        { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Found ${upcomingSubscriptions?.length || 0} subscriptions to notify`);

    const notificationResults: Array<{
      subscription_id: string;
      user_id: string;
      status: 'sent' | 'failed' | 'skipped';
      reason?: string;
    }> = [];

    for (const sub of (upcomingSubscriptions as SubscriptionWithUser[]) || []) {
      const daysUntil = Math.ceil(
        (new Date(sub.next_charge_date).getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
      );
      const notificationType = daysUntil === 1 ? 'renewal_1d' : 'renewal_3d';

      // Check user notification preferences
      const prefs = sub.users?.notification_preferences || {};
      if (!prefs[notificationType as keyof typeof prefs]) {
        notificationResults.push({
          subscription_id: sub.id,
          user_id: sub.user_id,
          status: 'skipped',
          reason: 'User disabled this notification type',
        });
        continue;
      }

      // Check if already notified today for this type
      const { data: existingNotif } = await supabase
        .from('notification_logs')
        .select('id')
        .eq('subscription_id', sub.id)
        .eq('notification_type', notificationType)
        .gte('created_at', todayStr)
        .maybeSingle();

      if (existingNotif) {
        notificationResults.push({
          subscription_id: sub.id,
          user_id: sub.user_id,
          status: 'skipped',
          reason: 'Already notified today',
        });
        continue;
      }

      // Get user's active FCM tokens
      const { data: devices } = await supabase
        .from('user_devices')
        .select('fcm_token')
        .eq('user_id', sub.user_id)
        .eq('is_active', true);

      if (!devices || devices.length === 0) {
        notificationResults.push({
          subscription_id: sub.id,
          user_id: sub.user_id,
          status: 'skipped',
          reason: 'No active devices',
        });
        continue;
      }

      // Build notification payload
      const basePayload = buildRenewalNotification(
        sub.subscription_name,
        sub.amount,
        sub.currency,
        daysUntil,
        sub.id,
        notificationType
      );

      // Send to all devices
      let sentCount = 0;
      let failCount = 0;

      for (const device of devices) {
        const result = await sendPushNotification(
          device.fcm_token,
          basePayload.title,
          basePayload.body,
          basePayload.data
        );

        if (result.error) {
          failCount++;
          console.error(`FCM error for ${sub.id}:`, result.error);
        } else {
          sentCount++;
        }

        // Log the notification
        await supabase.from('notification_logs').insert({
          user_id: sub.user_id,
          subscription_id: sub.id,
          notification_type: notificationType,
          fcm_message_id: result.name || null,
          status: result.error ? 'failed' : 'sent',
          error_message: result.error?.message || null,
        });
      }

      notificationResults.push({
        subscription_id: sub.id,
        user_id: sub.user_id,
        status: sentCount > 0 ? 'sent' : 'failed',
        reason: `Sent: ${sentCount}, Failed: ${failCount}`,
      });
    }

    const summary = {
      total: notificationResults.length,
      sent: notificationResults.filter((r) => r.status === 'sent').length,
      failed: notificationResults.filter((r) => r.status === 'failed').length,
      skipped: notificationResults.filter((r) => r.status === 'skipped').length,
    };

    console.log('Notification summary:', summary);

    return new Response(
      JSON.stringify({
        success: true,
        summary,
        results: notificationResults,
      }),
      { status: 200, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('notify-renewals error:', error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    );
  }
});
