<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { orderedTabs, readSettings } from '$lib/settings';
  import Connection from './Connection.svelte';
  import MovieRoulette from './MovieRoulette.svelte';
  import PartnerIdeas from './PartnerIdeas.svelte';
  import UsefulLinks from './UsefulLinks.svelte';


  const userId = $derived(page.data.user?.id ?? page.data.session?.user?.id ?? '');
  const settings = $derived(readSettings(page.data.user));
  const tabs = $derived(orderedTabs('partner', settings));

  let url = new URL(page.url.href);
  if (browser) {
    url = new URL(window.location.href);
  }
  const current = url.searchParams.get('tab');
  const initialTabs = orderedTabs('partner', readSettings(page.data.user));
  const defaultTab = initialTabs.some((tab) => tab.id === current) ? (current as string) : (initialTabs[0]?.id ?? 'connection');
  let activeTab = $state(defaultTab);


  $effect(() => {
    if (typeof window === 'undefined') return;
    const url = new URL(window.location.href);
    const current = url.searchParams.get('tab');
    if (current === activeTab) return;
    url.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', url);
  });

  function switchTab(tabId: string) {
    activeTab = tabId;
    const next = new URL(window.location.href);
    next.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', next);
  }
</script>

<div class="partner-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">♥ Partner</h2>
      <div class="section-subtitle">Tu espacio compartido</div>
    </div>
  </div>

  <div class="tabs-bar">
    {#each tabs as tab}
      <button class="tab-btn" class:active={activeTab === tab.id} onclick={() => switchTab(tab.id)}>
        <span>{tab.icon}</span> {tab.label}
      </button>
    {/each}
  </div>

  {#if activeTab === 'connection'}
    <Connection userId={userId} />
  {:else if activeTab === 'movies'}
    <MovieRoulette />
  {:else if activeTab === 'ideas'}
    <PartnerIdeas userId={userId} />
  {:else if activeTab === 'links'}
    <UsefulLinks userId={userId} />
  {/if}
</div>

<style>
  .partner-page { max-width: 1100px; }

  .tabs-bar {
    display: flex;
    gap: 4px;
    flex-wrap: wrap;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 6px;
    margin-bottom: 24px;
  }

  .tab-btn {
    padding: 8px 14px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    color: var(--text3);
    transition: all var(--transition);
    display: flex;
    align-items: center;
    gap: 6px;
    background: transparent;
    border: none;
    cursor: pointer;
  }

  .tab-btn.active {
    background: var(--surface2);
    color: var(--text);
  }

  .tab-btn:hover:not(.active) { background: var(--surface); color: var(--text2); }
</style>
