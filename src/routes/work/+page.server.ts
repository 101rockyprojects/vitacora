import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { safeGetSession }, url }) => {
  const { session } = await safeGetSession();
  if (!session) throw redirect(303, '/auth');

  const selectedTags = url.searchParams
    .getAll('tag')
    .map((t) => t.trim())
    .filter(Boolean);

  return { selectedTags };
};
