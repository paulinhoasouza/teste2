import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY

export const configured = Boolean(url && key && url.startsWith('https://'))
export const supabase = configured
  ? createClient(url, key, {auth: {autoRefreshToken:true, persistSession:true, detectSessionInUrl:true}})
  : null

export function assertConfigured() {
  if (!configured) throw new Error('Configure VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no ambiente.')
}
