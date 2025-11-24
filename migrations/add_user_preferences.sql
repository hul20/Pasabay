-- Add preferences column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{"time_format": "12h", "currency": "PHP"}'::jsonb;
