-- AI Log Table Migration
-- This table tracks LLM API usage for cost monitoring and planning
-- This is an ADDITIVE migration - does not modify any existing tables

-- ============================================
-- AI_LOG TABLE (cost & usage tracking)
-- ============================================
CREATE TABLE public.ai_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    receipt_id UUID REFERENCES public.receipts(id) ON DELETE SET NULL,
    
    -- Model identification
    model_name TEXT NOT NULL,
    
    -- Token usage (from API response)
    input_tokens INTEGER NOT NULL,
    output_tokens INTEGER NOT NULL,
    total_tokens INTEGER NOT NULL,
    
    -- Cost tracking in USD (10 decimal places for micro-cent precision)
    input_cost DECIMAL(12, 10) NOT NULL,
    output_cost DECIMAL(12, 10) NOT NULL,
    total_cost DECIMAL(12, 10) NOT NULL,
    
    -- Pricing snapshot (rates used at time of call for historical accuracy)
    input_price_per_million DECIMAL(10, 4),
    output_price_per_million DECIMAL(10, 4),
    
    -- Performance metrics
    latency_ms INTEGER,
    
    -- Context
    function_name TEXT,           -- e.g., 'process-receipt', 'notify-renewals'
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES for efficient monitoring queries
-- ============================================
-- Query by user (track individual user costs)
CREATE INDEX idx_ai_log_user_id ON public.ai_log(user_id);

-- Query by time (daily/weekly/monthly reports)
CREATE INDEX idx_ai_log_created_at ON public.ai_log(created_at DESC);

-- Query by model (compare model costs)
CREATE INDEX idx_ai_log_model ON public.ai_log(model_name);

-- Query by function (see which features cost most)
CREATE INDEX idx_ai_log_function ON public.ai_log(function_name);

-- Query by success status (monitor error rates)
CREATE INDEX idx_ai_log_success ON public.ai_log(success) WHERE success = false;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE public.ai_log ENABLE ROW LEVEL SECURITY;

-- Users can view their own AI usage logs (optional - for transparency)
CREATE POLICY "Users can view own ai logs" 
    ON public.ai_log FOR SELECT 
    USING (auth.uid() = user_id);

-- Only service role (edge functions) can insert logs
-- Edge functions use the service role key which bypasses RLS

-- ============================================
-- COMMENTS for documentation
-- ============================================
COMMENT ON TABLE public.ai_log IS 'Tracks LLM API usage for cost monitoring, planning, and analytics';
COMMENT ON COLUMN public.ai_log.model_name IS 'Full model identifier (e.g., accounts/fireworks/models/qwen3-vl-30b-a3b-instruct)';
COMMENT ON COLUMN public.ai_log.input_tokens IS 'Number of prompt/input tokens (from API usage.prompt_tokens)';
COMMENT ON COLUMN public.ai_log.output_tokens IS 'Number of completion/output tokens (from API usage.completion_tokens)';
COMMENT ON COLUMN public.ai_log.input_cost IS 'Cost in USD for input tokens at time of call';
COMMENT ON COLUMN public.ai_log.output_cost IS 'Cost in USD for output tokens at time of call';
COMMENT ON COLUMN public.ai_log.total_cost IS 'Total cost in USD (input_cost + output_cost)';
COMMENT ON COLUMN public.ai_log.input_price_per_million IS 'Price per million input tokens used for calculation (for historical reference)';
COMMENT ON COLUMN public.ai_log.output_price_per_million IS 'Price per million output tokens used for calculation (for historical reference)';
COMMENT ON COLUMN public.ai_log.function_name IS 'Which edge function made the LLM call';
COMMENT ON COLUMN public.ai_log.success IS 'Whether the LLM call succeeded';
