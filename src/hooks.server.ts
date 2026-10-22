// src/hooks.server.ts
import { env } from '$env/dynamic/public';
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import type { Handle } from '@sveltejs/kit';
import type { Session, User } from '@supabase/supabase-js';
import { readSettings } from '$lib/settings';

export const handle: Handle = async ({ event, resolve }) => {
  const supabaseUrl = env.PUBLIC_SUPABASE_URL;
  const supabaseKey = env.PUBLIC_SUPABASE_ANON_KEY;
  let palette = 'default';

  if (supabaseUrl && supabaseKey) {
    event.locals.supabase = createServerClient(
      supabaseUrl,
      supabaseKey,
      {
        cookies: {
          getAll() {
            return event.cookies.getAll();
          },
          setAll(cookiesToSet: { name: string; value: string; options: CookieOptions }[]) {
            cookiesToSet.forEach(({ name, value, options }) => {
              event.cookies.set(name, value, { ...options, path: '/', maxAge: 604800 });
            });
          },
        },
      }
    );

    event.locals.safeGetSession = async () => {
      const {
        data: { user },
        error: userError,
      } = await event.locals.supabase.auth.getUser();
      
      if (userError) {
        return { session: null, user: null };
      }

      const {
        data: { session },
      } = await event.locals.supabase.auth.getSession();
      
      return { session, user };
    };

    // Obtener sesión y usuario
    const { session, user } = await event.locals.safeGetSession();
    palette = readSettings(user).palette;
    
    // Extender locals con las propiedades
    (event.locals as App.Locals & { session: Session | null; user: User | null }).session = session;
    (event.locals as App.Locals & { session: Session | null; user: User | null }).user = user;

    // Redirigir si no hay sesión en rutas protegidas
    if (!session && event.url.pathname.startsWith('/dashboard')) {
      return new Response('Redirect', {
        status: 303,
        headers: { Location: '/auth' }
      });
    }
  }

  return resolve(event, {
    transformPageChunk: ({ html }) =>
      html.replace('<html', `<html data-palette="${palette}"`),
    filterSerializedResponseHeaders(name) {
      return name === 'content-range' || name === 'x-supabase-api-version';
    },
  });
};