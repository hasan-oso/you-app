# Daily Cleanup Edge Function

Automatically deletes old data based on retention policies.

## Retention Policies

| Data Type | Retention Period |
|-----------|-----------------|
| Health Reports | 30 days |
| Meal Logs | 90 days |
| Workout Logs | 180 days |
| Daily Steps | 7 days |
| Monthly Stats | 12 months |

## Deployment

```bash
# Deploy the function
supabase functions deploy daily-cleanup

# Test manually
supabase functions invoke daily-cleanup --method POST

# View logs
supabase functions logs daily-cleanup
```

## Cron Schedule

The function runs automatically every day at 3 AM UTC via Supabase Cron:

```sql
SELECT cron.schedule(
  'daily-cleanup-job',
  '0 3 * * *',
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_ID.supabase.co/functions/v1/daily-cleanup',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
  )
  $$
);
```

## Response Format

```json
{
  "success": true,
  "timestamp": "2026-02-03T03:00:00.000Z",
  "deleted": {
    "health_reports": 15,
    "meal_logs": 42,
    "workout_logs": 8,
    "steps_daily": 3,
    "monthly_stats": 0
  }
}
```
