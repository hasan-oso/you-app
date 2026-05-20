import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { amount, reason = 'purchase' } = await req.json()

        // Validation
        if (typeof amount !== 'number' || amount <= 0 || amount > 100) {
            return new Response(
                JSON.stringify({ error: 'Invalid amount' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            { global: { headers: { Authorization: authHeader } } }
        )

        const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
        if (userError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Check current balance
        const { data, error } = await supabaseClient
            .from('profiles')
            .select('coins')
            .eq('id', user.id)
            .single()

        if (error) throw error

        const currentCoins = data?.coins || 0

        if (currentCoins < amount) {
            return new Response(
                JSON.stringify({
                    error: 'Insufficient balance',
                    current: currentCoins,
                    required: amount
                }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const newCoins = currentCoins - amount

        const { data: updated, error: updateError } = await supabaseClient
            .from('profiles')
            .update({
                coins: newCoins,
                updated_at: new Date().toISOString()
            })
            .eq('id', user.id)
            .select('coins, xp, updated_at')
            .single()

        if (updateError) throw updateError

        console.log(`✅ Deducted ${amount} coins from user ${user.id}. Reason: ${reason}`)

        return new Response(
            JSON.stringify({
                success: true,
                coins: updated.coins,
                xp: updated.xp,
                updated_at: updated.updated_at,
                amount_deducted: amount
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
