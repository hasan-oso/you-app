-- ================================================================
-- SUPABASE MIGRATION: Cloud-Only Architecture
-- Phase 1: Create New Tables with Data Retention
-- ================================================================

-- ================================================================
-- 1. health_reports Table
--    Purpose: Store AI-generated health reports
--    Retention: 30 days (auto-cleanup)
-- ================================================================

CREATE TABLE IF NOT EXISTS health_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  report_text TEXT NOT NULL,
  report_type VARCHAR(20) DEFAULT 'daily' CHECK (report_type IN ('daily', 'holistic')),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_report_text CHECK (length(report_text) > 0)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_health_reports_user_date 
  ON health_reports(user_id, created_at DESC);

-- Simple index for cleanup query (without WHERE predicate)
CREATE INDEX IF NOT EXISTS idx_health_reports_created_at
  ON health_reports(created_at);

-- Row Level Security
ALTER TABLE health_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own reports" ON health_reports;
CREATE POLICY "Users can view own reports"
  ON health_reports FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own reports" ON health_reports;
CREATE POLICY "Users can insert own reports"
  ON health_reports FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own reports" ON health_reports;
CREATE POLICY "Users can delete own reports"
  ON health_reports FOR DELETE
  USING (auth.uid() = user_id);

-- Cleanup function for old reports
CREATE OR REPLACE FUNCTION cleanup_old_health_reports()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM health_reports
  WHERE created_at < NOW() - INTERVAL '30 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % old health reports', deleted_count;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- 2. monthly_stats Table
--    Purpose: Aggregated statistics for historical analysis
--    Retention: 12 months
-- ================================================================

CREATE TABLE IF NOT EXISTS monthly_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  month_year VARCHAR(7) NOT NULL, -- Format: 'YYYY-MM'
  
  -- Aggregated metrics
  total_meals INTEGER DEFAULT 0,
  total_workouts INTEGER DEFAULT 0,
  total_risks_detected INTEGER DEFAULT 0,
  total_calories_consumed INTEGER DEFAULT 0,
  total_steps INTEGER DEFAULT 0,
  average_weight DECIMAL(5,2),
  min_weight DECIMAL(5,2),
  max_weight DECIMAL(5,2),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one record per user per month
  UNIQUE(user_id, month_year),
  
  -- Validate month format
  CONSTRAINT valid_month_format CHECK (month_year ~ '^\d{4}-\d{2}$')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_monthly_stats_user_month
  ON monthly_stats(user_id, month_year DESC);

-- RLS
ALTER TABLE monthly_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own stats" ON monthly_stats;
CREATE POLICY "Users can manage own stats"
  ON monthly_stats FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_monthly_stats_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_monthly_stats_timestamp ON monthly_stats;
CREATE TRIGGER set_monthly_stats_timestamp
  BEFORE UPDATE ON monthly_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_monthly_stats_timestamp();

-- Cleanup function (keep last 12 months only)
CREATE OR REPLACE FUNCTION cleanup_old_monthly_stats()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
  cutoff_month VARCHAR(7);
BEGIN
  -- Calculate cutoff date (12 months ago)
  cutoff_month := TO_CHAR(NOW() - INTERVAL '12 months', 'YYYY-MM');
  
  DELETE FROM monthly_stats
  WHERE month_year < cutoff_month;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % old monthly stats (before %)', deleted_count, cutoff_month;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- 3. steps_daily Table
--    Purpose: Daily step counts from pedometer
--    Retention: 7 days (recent history only)
-- ================================================================

CREATE TABLE IF NOT EXISTS steps_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  steps INTEGER DEFAULT 0 CHECK (steps >= 0),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- One record per user per day
  UNIQUE(user_id, date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_steps_daily_user_date
  ON steps_daily(user_id, date DESC);

-- Simple index for cleanup (without WHERE predicate)
CREATE INDEX IF NOT EXISTS idx_steps_daily_date
  ON steps_daily(date);

-- RLS
ALTER TABLE steps_daily ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own steps" ON steps_daily;
CREATE POLICY "Users can manage own steps"
  ON steps_daily FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_steps_daily_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_steps_daily_timestamp ON steps_daily;
CREATE TRIGGER set_steps_daily_timestamp
  BEFORE UPDATE ON steps_daily
  FOR EACH ROW
  EXECUTE FUNCTION update_steps_daily_timestamp();

-- Cleanup function (keep last 7 days only)
CREATE OR REPLACE FUNCTION cleanup_old_steps()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM steps_daily
  WHERE date < CURRENT_DATE - INTERVAL '7 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % old step records', deleted_count;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- 4. Update existing tables with retention policies
-- ================================================================

-- Add cleanup function for meal_logs (90 days)
CREATE OR REPLACE FUNCTION cleanup_old_meal_logs()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM meal_logs
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % old meal logs', deleted_count;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add cleanup function for workout_logs (180 days)
CREATE OR REPLACE FUNCTION cleanup_old_workout_logs()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM workout_logs
  WHERE created_at < NOW() - INTERVAL '180 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % old workout logs', deleted_count;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- 5. Master cleanup function (calls all others)
-- ================================================================

CREATE OR REPLACE FUNCTION run_daily_cleanup()
RETURNS JSON AS $$
DECLARE
  result JSON;
  reports_deleted INTEGER;
  meals_deleted INTEGER;
  workouts_deleted INTEGER;
  steps_deleted INTEGER;
  stats_deleted INTEGER;
BEGIN
  -- Run all cleanup functions
  reports_deleted := cleanup_old_health_reports();
  meals_deleted := cleanup_old_meal_logs();
  workouts_deleted := cleanup_old_workout_logs();
  steps_deleted := cleanup_old_steps();
  stats_deleted := cleanup_old_monthly_stats();
  
  -- Build result JSON
  result := json_build_object(
    'success', true,
    'timestamp', NOW(),
    'deleted', json_build_object(
      'health_reports', reports_deleted,
      'meal_logs', meals_deleted,
      'workout_logs', workouts_deleted,
      'steps_daily', steps_deleted,
      'monthly_stats', stats_deleted
    )
  );
  
  RAISE NOTICE 'Daily cleanup completed: %', result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- 6. Verification queries (for testing)
-- ================================================================

-- Check table creation
DO $$
BEGIN
  RAISE NOTICE 'Verifying table creation...';
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'health_reports') THEN
    RAISE NOTICE '✅ health_reports table created';
  ELSE
    RAISE WARNING '❌ health_reports table NOT created';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'monthly_stats') THEN
    RAISE NOTICE '✅ monthly_stats table created';
  ELSE
    RAISE WARNING '❌ monthly_stats table NOT created';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'steps_daily') THEN
    RAISE NOTICE '✅ steps_daily table created';
  ELSE
    RAISE WARNING '❌ steps_daily table NOT created';
  END IF;
END $$;

-- ================================================================
-- MANUAL TEST COMMANDS (Run after migration)
-- ================================================================

/*
-- Test inserting a health report
INSERT INTO health_reports (user_id, report_text, report_type)
VALUES (auth.uid(), 'Test report content', 'daily');

-- Test inserting monthly stats
INSERT INTO monthly_stats (user_id, month_year, total_meals, total_workouts)
VALUES (auth.uid(), '2026-02', 50, 10)
ON CONFLICT (user_id, month_year) 
DO UPDATE SET 
  total_meals = monthly_stats.total_meals + EXCLUDED.total_meals,
  total_workouts = monthly_stats.total_workouts + EXCLUDED.total_workouts;

-- Test inserting daily steps
INSERT INTO steps_daily (user_id, date, steps)
VALUES (auth.uid(), CURRENT_DATE, 5000)
ON CONFLICT (user_id, date)
DO UPDATE SET steps = EXCLUDED.steps;

-- Test cleanup (manually)
SELECT run_daily_cleanup();

-- View cleanup results
SELECT * FROM health_reports WHERE created_at > NOW() - INTERVAL '30 days';
SELECT * FROM meal_logs WHERE created_at > NOW() - INTERVAL '90 days';
SELECT * FROM workout_logs WHERE created_at > NOW() - INTERVAL '180 days';
SELECT * FROM steps_daily WHERE date >= CURRENT_DATE - INTERVAL '7 days';
*/
