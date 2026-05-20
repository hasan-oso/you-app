-- Add columns for Weight Recalibration Cycle
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS last_weigh_in_date timestamp with time zone DEFAULT now(),
ADD COLUMN IF NOT EXISTS weight_history jsonb DEFAULT '[]'::jsonb;

-- Comment on columns
COMMENT ON COLUMN public.profiles.last_weigh_in_date IS 'Timestamp of the last official weigh-in';
COMMENT ON COLUMN public.profiles.weight_history IS 'JSON array of historical weight records: [{date: ISO8601, weight: double}]';
