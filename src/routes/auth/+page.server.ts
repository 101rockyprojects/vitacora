
import { type Action } from '@sveltejs/kit';
import { createRepository } from '$lib/services/repository';

export const actions = {
  login: (async ({ locals, request }) => {
    const data = await request.formData();
    const email = data.get('email') as string;
    const password = data.get('password') as string;
    try {
      const repo = createRepository(undefined, locals.supabase);
      const { error } = await repo.auth.signInWithPassword(email, password);
      if (error) {
        return { success: false, error: error.message };
      }
      return { success: true, action: 'login' };
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : 'Error de conexión. Intenta más tarde.';
      return { success: false, error: errMsg };
    }
  }) satisfies Action,
  signup: (async ({ url, locals, request }) => {
    const data = await request.formData();
    const email = data.get('email') as string;
    const password = data.get('password') as string;
    if (password.length < 6) {
      return { success: false, error: 'La contraseña debe tener al menos 6 caracteres.' };
    }
    try {
      const repo = createRepository(undefined, locals.supabase);
      const { error, data: signupData } = await repo.auth.signUp(email, password, {
        emailRedirectTo: `${url.origin}/auth/callback`
      });
      if (error) {
        return { success: false, error: error.message };
      }
      if (signupData?.user?.identities?.length === 0) {
        return { success: false, error: 'Este email ya está registrado. Intenta iniciar sesión.' };
      }
      return { success: true, action: 'signup' };
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : 'Error de conexión. Intenta más tarde.';
      return { success: false, error: errMsg };
    }
  }) satisfies Action
};
