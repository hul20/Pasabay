-- Add payment_status column to service_requests table
ALTER TABLE public.service_requests
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'held', 'completed', 'refunded'));

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_service_requests_payment_status ON public.service_requests(payment_status);

COMMENT ON COLUMN public.service_requests.payment_status IS 'Payment status: pending (no payment), held (payment deducted from requester), completed (payment sent to traveler), refunded (payment returned to requester)';
