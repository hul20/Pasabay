-- Add proof_image_url column to service_requests
ALTER TABLE public.service_requests 
ADD COLUMN IF NOT EXISTS proof_image_url TEXT;

-- Update status check constraint to include 'Order Sent'
ALTER TABLE public.service_requests 
DROP CONSTRAINT IF EXISTS service_requests_status_check;

ALTER TABLE public.service_requests 
ADD CONSTRAINT service_requests_status_check 
CHECK (status IN ('Pending', 'Accepted', 'Rejected', 'Completed', 'Cancelled', 'Order Sent'));

-- Create storage bucket for proof images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('proof-images', 'proof-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload proof images
CREATE POLICY "Authenticated users can upload proof images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'proof-images');

-- Allow authenticated users to view proof images
CREATE POLICY "Authenticated users can view proof images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'proof-images');
