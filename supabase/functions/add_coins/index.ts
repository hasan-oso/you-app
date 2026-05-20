import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { amount, reason = 'manual' } = await req.json()
    
    // Validation
    if (typeof amount !== 'number' || amount <= 0 || amount > 100) {
      return new Response(
        JSON.stringify({ error: 'Invalid amount. Must be between 1 and 100.' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
    
    // Get user from auth header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    
    // Get current user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Update coins with atomic increment
    const { data, error } = await supabaseClient
      .from('profiles')
      .select('coins')
      .eq('id', user.id)
      .single()
    
    if (error) {
      throw error
    }
    
    const newCoins = (data?.coins || 0) + amount
    
    const { data: updated, error: updateError } = await supabaseClient
      .from('profiles')
      .update({
        coins: newCoins,
        updated_at: new Date().toISOString()
      })
      .eq('id', user.id)
      .select('coins, xp, updated_at')
      .single()
    
    if (updateError) {
      throw updateError
    }
    
    console.log(`✅ Added ${amount} coins to user ${user.id}. Reason: ${reason}`)
    
    return new Response(
      JSON.stringify({
        success: true,
        coins: updated.coins,
        xp: updated.xp,
        updated_at: updated.updated_at,
        amount_added: amount
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
