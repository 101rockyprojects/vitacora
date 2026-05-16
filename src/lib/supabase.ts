import { createBrowserClient } from '@supabase/ssr';
import { env } from '$env/dynamic/public';

let supabaseInstance: ReturnType<typeof createBrowserClient> | null = null;

export function getSupabaseClient() {
  if (!supabaseInstance) {
    supabaseInstance = createBrowserClient(
      env.PUBLIC_SUPABASE_URL || '',
      env.PUBLIC_SUPABASE_ANON_KEY || '',
      { db: { schema: 'vitacora' } }
    );
  }
  return supabaseInstance;
}

// For backward compatibility
export const supabase = {
  get auth() {
    return getSupabaseClient().auth;
  },
  get realtime() {
    return getSupabaseClient().realtime;
  },
  from(table: string) {
    return getSupabaseClient().from(table);
  },
  rpc(fn: string, args?: any) {
    return getSupabaseClient().rpc(fn, args);
  }
} as any;
