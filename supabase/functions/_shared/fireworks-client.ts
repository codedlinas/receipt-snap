// Fireworks.ai client for visual LLM extraction
import { ExtractionResult } from './types.ts';

const FIREWORKS_API_KEY = Deno.env.get('FIREWORKS_API_KEY')!;
const FIREWORKS_API_URL = 'https://api.fireworks.ai/inference/v1/chat/completions';
// Qwen3 VL 30B A3B Instruct - Vision model for receipt/subscription extraction
export const PRIMARY_MODEL = 'accounts/fireworks/models/qwen3-vl-30b-a3b-instruct';

// Token usage breakdown from API response
export interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
}

const EXTRACTION_PROMPT = `You are a receipt and subscription extraction assistant. Extract subscription/payment data from images and return ONLY valid JSON matching this schema:
{
  "subscription_name": string,
  "billing_entity": string | null,
  "amount": number,
  "currency": string (3-letter code like USD, EUR),
  "billing_cycle": "weekly" | "monthly" | "quarterly" | "semi_annual" | "annual" | "one_time" | "unknown",
  "start_date": string | null (YYYY-MM-DD format),
  "next_charge_date": string | null (YYYY-MM-DD format),
  "payment_method": string | null (e.g., "Visa ****1234"),
  "renewal_terms": string | null,
  "cancellation_policy": string | null,
  "cancellation_deadline": string | null (YYYY-MM-DD format),
  "confidence_score": number (0.0 to 1.0),
  "raw_text": string (all readable text from image for OCR fallback)
}

Rules:
- Extract the subscription/service name accurately
- Parse monetary amounts as numbers without currency symbols
- Infer billing cycle from context (e.g., "per month" = monthly)
- Calculate next_charge_date if start_date and billing_cycle are known
- Set confidence_score based on how clearly the data was extracted
- Always include raw_text with all visible text for fallback
- If extraction fails, set confidence_score to 0 and populate raw_text`;

export async function extractSubscriptionData(
  imageBase64: string,
  mimeType: string = 'image/jpeg'
): Promise<{ 
  extraction: ExtractionResult | null; 
  rawResponse: string | null;
  tokensUsed: number | null;      // Kept for backward compatibility
  tokenUsage: TokenUsage | null;  // Full breakdown for cost calculation
  error: string | null;
}> {
  // Set timeout to 45 seconds (leaves buffer before Supabase's 60s Edge Function limit)
  const TIMEOUT_MS = 45000;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(FIREWORKS_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${FIREWORKS_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: PRIMARY_MODEL,
        messages: [
          {
            role: 'system',
            content: EXTRACTION_PROMPT,
          },
          {
            role: 'user',
            content: [
              { type: 'text', text: 'Extract subscription details from this receipt/screenshot:' },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`,
                },
              },
            ],
          },
        ],
        max_tokens: 1024,
        temperature: 0.1,
        response_format: { type: 'json_object' },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Fireworks API error:', response.status, errorText.substring(0, 200));
      return { 
        extraction: null, 
        rawResponse: errorText.substring(0, 500),
        tokensUsed: null,
        tokenUsage: null,
        error: `Fireworks API error: ${response.status}` 
      };
    }

    const result = await response.json();
    const content = result.choices?.[0]?.message?.content;
    
    // Extract full token breakdown from API response
    const tokensUsed = result.usage?.total_tokens || null;
    const tokenUsage: TokenUsage | null = result.usage ? {
      inputTokens: result.usage.prompt_tokens || 0,
      outputTokens: result.usage.completion_tokens || 0,
      totalTokens: result.usage.total_tokens || 0,
    } : null;

    if (!content) {
      return { 
        extraction: null, 
        rawResponse: null,
        tokensUsed,
        tokenUsage,
        error: 'No content in LLM response' 
      };
    }

    // Parse JSON from response
    let extraction: ExtractionResult;
    try {
      // Try to extract JSON from the response (in case there's extra text)
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      extraction = JSON.parse(jsonMatch ? jsonMatch[0] : content);
    } catch (parseError) {
      console.error('JSON parse error:', parseError);
      // Return a fallback with raw text
      extraction = {
        subscription_name: 'Unknown',
        billing_entity: null,
        amount: 0,
        currency: 'USD',
        billing_cycle: 'unknown',
        start_date: null,
        next_charge_date: null,
        payment_method: null,
        renewal_terms: null,
        cancellation_policy: null,
        cancellation_deadline: null,
        confidence_score: 0,
        raw_text: content,
      };
    }

    // Validate required fields
    if (!extraction.subscription_name || extraction.subscription_name === 'Unknown') {
      extraction.confidence_score = Math.min(extraction.confidence_score || 0, 0.3);
    }

    return { 
      extraction, 
      rawResponse: content,
      tokensUsed,
      tokenUsage,
      error: null 
    };
  } catch (error) {
    clearTimeout(timeoutId);
    console.error('extractSubscriptionData error:', error);
    
    // Check if error is due to timeout
    if (error.name === 'AbortError' || error.message?.includes('aborted')) {
      return {
        extraction: null,
        rawResponse: null,
        tokensUsed: null,
        tokenUsage: null,
        error: 'Request timeout: The AI extraction took too long. Please try again with a clearer image.'
      };
    }
    
    return { 
      extraction: null, 
      rawResponse: null,
      tokensUsed: null,
      tokenUsage: null,
      error: error.message || 'Failed to extract subscription data'
    };
  }
}
