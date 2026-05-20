-- Run this in Supabase SQL Editor to fix the missing column error

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS bmr numeric default 0,
ADD COLUMN IF NOT EXISTS daily_calories int default 2000,
ADD COLUMN IF NOT EXISTS onboarding_completed boolean default false;
