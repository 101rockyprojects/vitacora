import { createBrowserClient, type SupabaseClient } from '@supabase/ssr';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { browser } from '$app/environment';

let _supabase: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient {
  if (!_supabase && browser) {
    _supabase = createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
      db: { schema: 'vitacora' }
    });
  }
  return _supabase as SupabaseClient;
}

export const supabase = {
  get auth() {
    const client = getSupabase();
    if (!client) {
      throw new Error('Supabase client not available in SSR context');
    }
    return client.auth;
  },
  get from() {
    const client = getSupabase();
    if (!client) {
      throw new Error('Supabase client not available in SSR context');
    }
    return client.from;
  },
  get rpc() {
    const client = getSupabase();
    if (!client) {
      throw new Error('Supabase client not available in SSR context');
    }
    return client.rpc;
  }
};