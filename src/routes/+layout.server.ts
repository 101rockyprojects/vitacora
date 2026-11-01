import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { firstEnabledHref, readSettings, sectionForPath } from '$lib/settings';

export const load: LayoutServerLoad = async ({ locals: { safeGetSession }, url }) => {
  const { session, user } = await safeGetSession();
  const settings = readSettings(user);

  const section = sectionForPath(url.pathname);
  if (user && section && !settings.sections[section]) {
    const target = firstEnabledHref(settings);
    if (target) redirect(302, target);
  }

  return {
    session,
    user
  };
};
