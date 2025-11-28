-- ============================================
-- UPDATE TRIPS TABLE TO ADD SERVICE PRICING
-- ============================================
-- Add columns for traveler to set their own prices for Pasabay and Pabakal services

-- Add pasabay_price column (price traveler charges for package delivery)
ALTER TABLE public.trips 
ADD COLUMN IF NOT EXISTS pasabay_price decimal(10,2) DEFAULT 50.00;

-- Add pabakal_price column (price traveler charges for shopping service)
ALTER TABLE public.trips 
ADD COLUMN IF NOT EXISTS pabakal_price decimal(10,2) DEFAULT 100.00;

-- Add check constraints to ensure prices are positive (drop first if exists)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'trips_pasabay_price_positive'
  ) THEN
    ALTER TABLE public.trips 
    ADD CONSTRAINT trips_pasabay_price_positive CHECK (pasabay_price >= 0);
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'trips_pabakal_price_positive'
  ) THEN
    ALTER TABLE public.trips 
    ADD CONSTRAINT trips_pabakal_price_positive CHECK (pabakal_price >= 0);
  END IF;
END $$;

-- Add comments
COMMENT ON COLUMN public.trips.pasabay_price IS 'Price (in PHP) that traveler charges for Pasabay (package delivery) service per request';
COMMENT ON COLUMN public.trips.pabakal_price IS 'Price (in PHP) that traveler charges for Pabakal (shopping) service per request';

-- Optional: Update existing trips with default pricing
-- UPDATE public.trips 
-- SET pasabay_price = 50.00, pabakal_price = 100.00
-- WHERE pasabay_price IS NULL OR pabakal_price IS NULL;

-- Verification queries
-- SELECT column_name, data_type, column_default FROM information_schema.columns 
-- WHERE table_name = 'trips' AND column_name IN ('pasabay_price', 'pabakal_price');
