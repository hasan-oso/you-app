import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Daily Cleanup Edge Function
 * 
 * Purpose: Automatically delete old data based on retention policies
 * Schedule: Runs daily at 3 AM via Cron Job
 * 
 * Retention Policies:
 * - health_reports: 30 days
 * - meal_logs: 90 days
 * - workout_logs: 180 days
 * - steps_daily: 7 days
 * - monthly_stats: 12 months
 */

interface CleanupResult {
    success: boolean
    timestamp: string
    deleted: {
        health_reports: number
        meal_logs: number
        workout_logs: number
        steps_daily: number
        monthly_stats: number
    }
    error?: string
}

serve(async (req: Request) => {
    try {
        // Verify this is an authorized request (optional: add API key check)
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { 'Content-Type': 'application/json' }
            })
        }

        // Initialize Supabase client with service role (full access)
        const supabaseUrl = Deno.env.get('SUPABASE_URL')
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

        if (!supabaseUrl || !supabaseServiceKey) {
            throw new Error('Missing Supabase environment variables')
        }

        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        console.log('🧹 Starting daily cleanup...')

        // Call the master cleanup function in database
        const { data, error } = await supabase
            .rpc('run_daily_cleanup')

        if (error) {
            console.error('❌ Cleanup failed:', error)
            throw error
        }

        console.log('✅ Cleanup completed:', data)

        const result: CleanupResult = {
            success: true,
            timestamp: new Date().toISOString(),
            deleted: data.deleted
        }

        return new Response(JSON.stringify(result), {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache'
            }
        })

    } catch (error) {
        console.error('💥 Error in cleanup function:', error)

        const errorResult: CleanupResult = {
            success: false,
            timestamp: new Date().toISOString(),
            deleted: {
                health_reports: 0,
                meal_logs: 0,
                workout_logs: 0,
                steps_daily: 0,
                monthly_stats: 0
            },
            error: error.message
        }

        return new Response(JSON.stringify(errorResult), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        })
    }
})
