-- Add weight_g column to meal_logs table
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS weight_g int;

-- Update comment
COMMENT ON COLUMN meal_logs.weight_g IS 'Weight of the food portion in grams';
