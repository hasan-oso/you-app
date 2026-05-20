-- Add age column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS age integer DEFAULT 25;

-- Update comment
COMMENT ON COLUMN profiles.age IS 'User age in years';
