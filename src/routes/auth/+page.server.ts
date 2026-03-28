
import { redirect, type Action } from '@sveltejs/kit';


export const actions = {
  login: (async ({ locals, request }) => {
    const data = await request.formData();
    const email = data.get('email') as string;
    const password = data.get('password') as string;
    const { error } = await locals.supabase.auth.signInWithPassword({ email, password });
    if (error) {
      return { success: false, error: error.message };
    }
    throw redirect(303, '/dashboard');
  }) satisfies Action,
  signup: (async ({ locals, request }) => {
    const data = await request.formData();
    const email = data.get('email') as string;
    const password = data.get('password') as string;
    const { error } = await locals.supabase.auth.signUp({ email, password });
    if (error) {
      return { success: false, error: error.message };
    }
    throw redirect(303, '/dashboard');
  }) satisfies Action
};
