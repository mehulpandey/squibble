// Supabase Edge Function: delete-account
// Fully deletes a user account including auth.users entry
// Requires service_role key (automatically available in Edge Functions)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header (user's JWT)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create client with user's JWT to verify they're authenticated
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Verify the user with their JWT
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { data: { user }, error: userError } = await userClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = user.id

    // Create admin client with service role key
    const adminClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // 1. Get all doodles sent by user to delete their storage files
    const { data: sentDoodles } = await adminClient
      .from('doodles')
      .select('id')
      .eq('sender_id', userId)

    // 2. Delete doodle images from storage
    if (sentDoodles && sentDoodles.length > 0) {
      const imagePaths = sentDoodles.map(d => `${userId}/${d.id}.png`)
      await adminClient.storage.from('doodles').remove(imagePaths)
    }

    // 3. Delete doodle_recipients where user is recipient
    await adminClient
      .from('doodle_recipients')
      .delete()
      .eq('recipient_id', userId)

    // 4. Delete all doodles sent by user (cascade will delete related recipients)
    await adminClient
      .from('doodles')
      .delete()
      .eq('sender_id', userId)

    // 5. Delete all friendships involving user
    await adminClient
      .from('friendships')
      .delete()
      .or(`requester_id.eq.${userId},addressee_id.eq.${userId}`)

    // 6. Delete profile image from storage
    await adminClient.storage
      .from('profiles')
      .remove([`${userId}.jpg`])

    // 7. Delete user from public.users table
    await adminClient
      .from('users')
      .delete()
      .eq('id', userId)

    // 8. Delete user from auth.users (requires service role)
    const { error: deleteAuthError } = await adminClient.auth.admin.deleteUser(userId)

    if (deleteAuthError) {
      console.error('Error deleting auth user:', deleteAuthError)
      return new Response(
        JSON.stringify({ error: 'Failed to delete authentication record' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Account deleted successfully' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in delete-account function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
