// src/hooks.server.ts
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import type { Handle } from '@sveltejs/kit';
import type { Session, User } from '@supabase/supabase-js';

export const handle: Handle = async ({ event, resolve }) => {
  event.locals.supabase = createServerClient(
    PUBLIC_SUPABASE_URL,
    PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return event.cookies.getAll();
        },
        setAll(cookiesToSet: { name: string; value: string; options: CookieOptions }[]) {
          cookiesToSet.forEach(({ name, value, options }) => {
            event.cookies.set(name, value, { ...options, path: '/' });
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

  return resolve(event, {
    filterSerializedResponseHeaders(name) {
      return name === 'content-range' || name === 'x-supabase-api-version';
    },
  });
};