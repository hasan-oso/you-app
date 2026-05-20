-- Update Achievement Rewards
UPDATE achievements SET coin_reward = 0 WHERE id = 'first_scan';
UPDATE achievements SET coin_reward = 5 WHERE id = '10k_steps';
UPDATE achievements SET coin_reward = 100 WHERE id = 'month_streak';
UPDATE achievements SET coin_reward = 10 WHERE id = 'workout_warrior';
UPDATE achievements SET coin_reward = 30 WHERE id = 'scan_master';
UPDATE achievements SET coin_reward = 0 WHERE id = 'calorie_conscious';

-- Verify updates
SELECT id, name_en, xp_reward, coin_reward FROM achievements ORDER BY coin_reward DESC;
