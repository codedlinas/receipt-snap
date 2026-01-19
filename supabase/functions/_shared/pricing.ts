// Fireworks AI Pricing Configuration
// Source: https://fireworks.ai/pricing
// Last updated: 2026-01-19

// Pricing per million tokens (USD)
export interface ModelPricing {
  inputPerMillion: number;
  outputPerMillion: number;
}

// Model pricing map - update when Fireworks changes pricing
export const MODEL_PRICING: Record<string, ModelPricing> = {
  // Qwen3 VL 30B A3B Instruct - Vision model for receipt extraction
  'accounts/fireworks/models/qwen3-vl-30b-a3b-instruct': {
    inputPerMillion: 0.15,   // $0.15 per 1M input tokens
    outputPerMillion: 0.60,  // $0.60 per 1M output tokens
  },
  // Add other models here as needed
};

// Default pricing fallback (conservative estimate)
const DEFAULT_PRICING: ModelPricing = {
  inputPerMillion: 1.00,
  outputPerMillion: 1.00,
};

export interface CostCalculation {
  inputCost: number;
  outputCost: number;
  totalCost: number;
  inputPricePerMillion: number;
  outputPricePerMillion: number;
}

/**
 * Calculate the cost of an LLM API call based on token usage
 * @param modelName - Full model identifier
 * @param inputTokens - Number of input/prompt tokens
 * @param outputTokens - Number of output/completion tokens
 * @returns Cost breakdown with individual and total costs
 */
export function calculateCost(
  modelName: string,
  inputTokens: number,
  outputTokens: number
): CostCalculation {
  const pricing = MODEL_PRICING[modelName] || DEFAULT_PRICING;
  
  const inputCost = (inputTokens / 1_000_000) * pricing.inputPerMillion;
  const outputCost = (outputTokens / 1_000_000) * pricing.outputPerMillion;
  
  return {
    inputCost,
    outputCost,
    totalCost: inputCost + outputCost,
    inputPricePerMillion: pricing.inputPerMillion,
    outputPricePerMillion: pricing.outputPerMillion,
  };
}
