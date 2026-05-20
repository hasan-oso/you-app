-- Create table for tracking completed workouts
CREATE TABLE IF NOT EXISTS public.workout_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_ids INT[] NOT NULL,
    total_xp_earned INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to insert their own logs
CREATE POLICY "Users can insert their own workout logs"
ON public.workout_logs
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to view their own logs
CREATE POLICY "Users can view their own workout logs"
ON public.workout_logs
FOR SELECT
USING (auth.uid() = user_id);
