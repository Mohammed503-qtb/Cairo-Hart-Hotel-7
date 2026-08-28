import { createClient } from '@supabase/supabase-js'

const url = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

// Server-side Supabase client using service role key (bypasses RLS)
export const supabaseAdmin = url && serviceKey
  ? createClient(url, serviceKey, { auth: { persistSession: false } })
  : null

// Public client (anon key) — used sparingly on server
export const supabasePublic = url
  ? createClient(url, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { auth: { persistSession: false } })
  : null
