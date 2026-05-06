<script lang="ts">
  import '../app.css';
  import { page } from '$app/state';
  import { onMount } from 'svelte';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import NotificationContainer from '$lib/components/NotificationContainer.svelte';
  
  let { data, children } = $props();
  
  $effect(() => {
    if (data.session) {
      // user logged in
    }
  });
  
  const isAuthPage = $derived(page.url.pathname.startsWith('/auth'));

  const routeMeta = $derived(getRouteMeta(page.url.pathname));
  let isTabHidden = $state(false);

  onMount(() => {
    const onVisibilityChange = () => {
      isTabHidden = document.visibilityState === 'hidden';
    };
    onVisibilityChange();
    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => document.removeEventListener('visibilitychange', onVisibilityChange);
  });

  const documentTitle = $derived(isTabHidden ? '¡PLUS ULTRA!' : routeMeta.title);

  function getRouteMeta(pathname: string): { title: string; description: string } {
    const base = 'VitaCora';
    const normalized = pathname.replace(/\/+$/, '') || '/';

    const known: Record<string, { label: string; description: string }> = {
      '/': { label: 'Home', description: 'Redirecting to your session.' },
      '/auth': { label: 'Auth', description: 'Sign in to VitaCora.' },
      '/dashboard': { label: 'Dashboard', description: 'Your overview and progress.' },
      '/goals': { label: 'Goals', description: 'Vision, habits, and growth.' },
      '/work': { label: 'Work', description: 'Kanban, projects, links, and skills.' },
      '/partner': { label: 'Partner', description: 'Shared ideas and plans.' },
      '/profile': { label: 'Profile', description: 'XP, badges, and your progress.' }
    };

    const entry = known[normalized] ?? {
      label: normalized.split('/').filter(Boolean)[0]?.replace(/[-_]/g, ' ') ?? 'Page',
      description: 'Vitacora.'
    };

    const pretty = entry.label.charAt(0).toUpperCase() + entry.label.slice(1);
    return { title: `${pretty} | ${base}`, description: entry.description };
  }
</script>

<svelte:head>
  <title>{documentTitle}</title>
  <meta name="description" content={routeMeta.description} />
  <meta property="og:title" content={documentTitle} />
  <meta property="og:description" content={routeMeta.description} />
  <meta property="og:url" content={page.url.href} />
  <meta name="twitter:title" content={documentTitle} />
  <meta name="twitter:description" content={routeMeta.description} />
</svelte:head>

<div class="app-layout">
  {#if data.session && !isAuthPage}
    <Sidebar user={data.user} />
  {/if}
  <main class="main-content" class:full-width={isAuthPage || !data.session}>
    {@render children()}
  </main>
  {#if data.session && !isAuthPage}
    <NotificationContainer />
  {/if}
</div>

<style>
  .full-width {
    margin-left: 0 !important;
    max-width: 100vw !important;
  }
</style>
