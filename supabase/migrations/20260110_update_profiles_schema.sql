-- Update profiles table with health metrics
alter table public.profiles 
add column if not exists height float,
add column if not exists weight float,
add column if not exists activity_level text check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'very_active')),
add column if not exists goal_type text check (goal_type in ('lose_weight', 'maintain', 'gain_muscle'));

-- Add validation for height and weight to be positive
alter table public.profiles
add constraint height_positive check (height > 0),
add constraint weight_positive check (weight > 0);
