-- ==============================================
-- YOU App: Database Schema Updates
-- ==============================================

-- 1. Add timestamp columns to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create trigger for auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at 
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Add login streak columns
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS login_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_login_date DATE;

-- 3. Create daily_steps table
CREATE TABLE IF NOT EXISTS daily_steps (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  steps INTEGER NOT NULL CHECK (steps >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_steps_user_date ON daily_steps(user_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_steps_date ON daily_steps(date);

-- Enable RLS
ALTER TABLE daily_steps ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own steps"
  ON daily_steps FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own steps"
  ON daily_steps FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own steps"
  ON daily_steps FOR UPDATE
  USING (auth.uid() = user_id);

-- 4. Create achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  description_en TEXT,
  description_ar TEXT,
  icon TEXT,
  xp_reward INTEGER DEFAULT 0 CHECK (xp_reward >= 0),
  coin_reward INTEGER DEFAULT 0 CHECK (coin_reward >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create user_achievements table
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  achievement_id TEXT REFERENCES achievements(id) NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement ON user_achievements(achievement_id);

-- Enable RLS
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own achievements"
  ON user_achievements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can unlock achievements"
  ON user_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 6. Seed initial achievements
INSERT INTO achievements (id, name_en, name_ar, description_en, description_ar, icon, xp_reward, coin_reward) VALUES
('first_scan', 'First Scan', 'أول مسح', 'Scan your first food item', 'امسح أول وجبة', 'qr_code_scanner', 10, 5),
('10k_steps', '10K Steps', '10 آلاف خطوة', 'Walk 10,000 steps in a single day', 'امشِ 10,000 خطوة في يوم واحد', 'directions_walk', 50, 20),
('week_streak', 'Week Streak', 'أسبوع متواصل', 'Log in for 7 consecutive days', 'سجل دخول لمدة 7 أيام متتالية', 'local_fire_department', 100, 50),
('month_streak', 'Month Streak', 'شهر متواصل', 'Log in for 30 consecutive days', 'سجل دخول لمدة 30 يوم متتالي', 'whatshot', 300, 150),
('elite_rank', 'Elite Rank', 'رتبة النخبة', 'Reach Elite rank (15,000 XP)', 'وصول لرتبة النخبة (15,000 XP)', 'military_tech', 200, 100),
('workout_warrior', 'Workout Warrior', 'محارب التمارين', 'Complete 10 workouts', 'أكمل 10 تمارين', 'fitness_center', 75, 40),
('scan_master', 'Scan Master', 'خبير المسح', 'Complete 100 scans', 'أكمل 100 مسح', 'verified', 150, 75),
('healthy_habits', 'Healthy Habits', 'عادات صحية', 'Complete daily quest 30 times', 'أكمل المهمة اليومية 30 مرة', 'favorite', 120, 60),
('first_workout', 'First Workout', 'أول تمرين', 'Complete your first workout', 'أكمل أول تمرين', 'emoji_events', 20, 10),
('calorie_conscious', 'Calorie Conscious', 'واعي بالسعرات', 'Track 1000 total calories', 'تتبع 1000 سعرة حرارية', 'calculate', 80, 40)
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- Verification Queries
-- ==============================================

-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('daily_steps', 'achievements', 'user_achievements');

-- Check columns added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('updated_at', 'login_streak', 'last_login_date');

-- Check achievements seeded
SELECT id, name_en, xp_reward, coin_reward FROM achievements;
