-- Messages Table Migration
-- This table stores LLM conversation logs for debugging inputs/outputs
-- Created for tracking user uploads and assistant (LLM) responses

-- ============================================
-- MESSAGES TABLE (debug logging)
-- ============================================
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    receipt_id UUID REFERENCES public.receipts(id) ON DELETE SET NULL,
    
    -- Core fields
    sender TEXT NOT NULL CHECK (sender IN ('user', 'assistant')),
    message_type TEXT NOT NULL CHECK (message_type IN (
        'image_upload',           -- User uploaded an image
        'extraction_request',     -- Request sent to LLM
        'extraction_response',    -- Successful LLM response
        'error'                   -- Error during processing
    )),
    
    -- Content - stores the actual message data
    -- For user: {filename, mime_type, file_size_bytes, prompt}
    -- For assistant: {raw_response, parsed_extraction, error}
    content JSONB NOT NULL,
    
    -- Metadata for debugging
    model_used TEXT,              -- e.g., 'qwen3-vl-30b-a3b-instruct'
    tokens_used INTEGER,          -- For cost tracking
    latency_ms INTEGER,           -- Response time in milliseconds
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES for efficient debugging queries
-- ============================================
-- Query messages by receipt (see full conversation for a receipt)
CREATE INDEX idx_messages_receipt_id ON public.messages(receipt_id);

-- Query messages by user and sender (filter user vs assistant messages)
CREATE INDEX idx_messages_user_sender ON public.messages(user_id, sender);

-- Query messages by time (recent debugging)
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);

-- Query by message type (find all errors, all uploads, etc.)
CREATE INDEX idx_messages_type ON public.messages(message_type);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Users can view their own messages (for potential future in-app debugging)
CREATE POLICY "Users can view own messages" 
    ON public.messages FOR SELECT 
    USING (auth.uid() = user_id);

-- Only service role (edge functions) can insert messages
-- This is enforced by not having an INSERT policy for regular users
-- Edge functions use the service role key which bypasses RLS

-- ============================================
-- COMMENTS for documentation
-- ============================================
COMMENT ON TABLE public.messages IS 'Debug logging table for LLM conversation tracking - stores user inputs and assistant outputs';
COMMENT ON COLUMN public.messages.sender IS 'Either "user" for user uploads or "assistant" for LLM responses';
COMMENT ON COLUMN public.messages.message_type IS 'Type of message: image_upload, extraction_request, extraction_response, or error';
COMMENT ON COLUMN public.messages.content IS 'JSONB content of the message - structure varies by message_type';
COMMENT ON COLUMN public.messages.model_used IS 'LLM model identifier used for the request';
COMMENT ON COLUMN public.messages.tokens_used IS 'Total tokens consumed by the LLM call';
COMMENT ON COLUMN public.messages.latency_ms IS 'Time taken for LLM response in milliseconds';
