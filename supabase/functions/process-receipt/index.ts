// Edge Function: process-receipt
// Handles receipt upload, LLM extraction, and subscription creation

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { getServiceClient, getAuthenticatedUser } from '../_shared/supabase-client.ts';
import { extractSubscriptionData } from '../_shared/fireworks-client.ts';
import { ProcessReceiptRequest, CORS_HEADERS } from '../_shared/types.ts';

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
    const body: ProcessReceiptRequest = await req.json();
    const { image_base64, filename, mime_type } = body;

    if (!image_base64) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing image_base64' }),
        { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Create receipt record (processing status)
    const { data: receipt, error: receiptError } = await supabase
      .from('receipts')
      .insert({
        user_id: user.id,
        original_filename: filename || 'receipt.jpg',
        mime_type: mime_type || 'image/jpeg',
        processing_status: 'processing',
        storage_path: '', // Will update after upload
      })
      .select()
      .single();

    if (receiptError) {
      console.error('Receipt creation error:', receiptError);
      throw new Error(`Failed to create receipt record: ${receiptError.message}`);
    }

    // 2. Upload image to Supabase Storage
    const storagePath = `${user.id}/${receipt.id}.jpg`;
    const imageBuffer = Uint8Array.from(atob(image_base64), (c) => c.charCodeAt(0));

    const { error: uploadError } = await supabase.storage
      .from('receipts')
      .upload(storagePath, imageBuffer, {
        contentType: mime_type || 'image/jpeg',
        upsert: true,
      });

    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      // Update receipt with error
      await supabase
        .from('receipts')
        .update({
          processing_status: 'failed',
          error_message: `Storage upload failed: ${uploadError.message}`,
        })
        .eq('id', receipt.id);
      throw new Error(`Failed to upload image: ${uploadError.message}`);
    }

    // Update storage path and file size
    await supabase
      .from('receipts')
      .update({
        storage_path: storagePath,
        file_size_bytes: imageBuffer.length,
      })
      .eq('id', receipt.id);

    // 3. Call Fireworks.ai Vision LLM for extraction
    const { extraction, error: extractionError } = await extractSubscriptionData(
      image_base64,
      mime_type || 'image/jpeg'
    );

    if (extractionError || !extraction) {
      console.error('Extraction error:', extractionError);
      await supabase
        .from('receipts')
        .update({
          processing_status: 'failed',
          error_message: extractionError || 'Extraction failed',
          processed_at: new Date().toISOString(),
        })
        .eq('id', receipt.id);

      return new Response(
        JSON.stringify({
          success: false,
          error: extractionError || 'Failed to extract subscription data',
          receipt_id: receipt.id,
        }),
        { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }

    // 4. Update receipt with extraction result
    await supabase
      .from('receipts')
      .update({
        processing_status: 'completed',
        raw_llm_response: extraction,
        processed_at: new Date().toISOString(),
      })
      .eq('id', receipt.id);

    // 5. Create subscription record
    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .insert({
        user_id: user.id,
        receipt_id: receipt.id,
        subscription_name: extraction.subscription_name || 'Unknown Subscription',
        billing_entity: extraction.billing_entity,
        amount: extraction.amount || 0,
        currency: extraction.currency || 'USD',
        billing_cycle: extraction.billing_cycle || 'unknown',
        start_date: extraction.start_date,
        next_charge_date: extraction.next_charge_date,
        payment_method: extraction.payment_method,
        renewal_terms: extraction.renewal_terms,
        cancellation_policy: extraction.cancellation_policy,
        cancellation_deadline: extraction.cancellation_deadline,
        confidence_score: extraction.confidence_score,
        user_verified: false,
      })
      .select()
      .single();

    if (subError) {
      console.error('Subscription creation error:', subError);
      throw new Error(`Failed to create subscription: ${subError.message}`);
    }

    // 6. Create audit log
    await supabase.from('audit_logs').insert({
      user_id: user.id,
      entity_type: 'subscription',
      entity_id: subscription.id,
      action: 'create',
      new_values: subscription,
    });

    // 7. Return success response
    return new Response(
      JSON.stringify({
        success: true,
        receipt_id: receipt.id,
        subscription: subscription,
        extracted: extraction,
        requires_review: extraction.confidence_score < 0.8,
      }),
      { status: 200, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('process-receipt error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'An unexpected error occurred',
      }),
      { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    );
  }
});
