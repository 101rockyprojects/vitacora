<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { orderedTabs, readSettings } from '$lib/settings';
  import { createRepository } from '$lib/services/repository';
  import Toast from '$lib/components/Toast.svelte';
  import Kanban from './Kanban.svelte';
  import Projects from './PersonalProjects.svelte';
  import UsefulLinks from './UsefulLinks.svelte';
  import Skills from './Skills.svelte';
  import type { Task, Project, UsefulLink, SkillsMd } from '$lib/types';


  const userId = $derived(page.data.user?.id ?? page.data.session?.user?.id ?? '');
  const tabs = $derived(orderedTabs('projects', readSettings(page.data.user)));
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let url = new URL(page.url.href);
  if (browser) {
    url = new URL(window.location.href);
  }
  const current = url.searchParams.get('tab');
  const initialTabs = orderedTabs('projects', readSettings(page.data.user));
  const defaultTab = initialTabs.some((tab) => tab.id === current) ? (current as string) : (initialTabs[0]?.id ?? 'kanban');
  let activeTab = $state(defaultTab);

  let tasks = $state<Task[]>([]);
  let projects = $state<Project[]>([]);
  let links = $state<UsefulLink[]>([]);
  let skills = $state<SkillsMd[]>([]);
  let copyToast = $state(false);
  let loading = $state(true);

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadAll();
    }
  });

  function switchTab(tabId: string) {
    activeTab = tabId;
    const next = new URL(window.location.href);
    next.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', next);
  }

  $effect(() => {
    if (typeof window === 'undefined') return;
    const url = new URL(window.location.href);
    const current = url.searchParams.get('tab');
    if (current === activeTab) return;
    url.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', url);
  });

  $effect(() => {
    if (typeof window === 'undefined') return;
    const current = page.url.searchParams.get('tab');
    if (current === activeTab) return;
    const next = new URL(window.location.href);
    next.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', next);
  });

  async function loadAll() {
    if (!userId) return;
    const [t, p, l, s] = await Promise.all([
      repo.tasks.list(),
      repo.projects.list(),
      repo.links.list(),
      repo.skillsMd.list()
    ]);
    tasks = t.data || [];
    projects = p.data || [];
    links = l.data || [];
    skills = s.data || [];
    loading = false;
  }

  $effect(() => {
    if (typeof window === 'undefined') return;
    const urlTags = page.url.searchParams.getAll('tag').map((t) => t.trim()).filter(Boolean);
    const unique = [...new Set(urlTags)];
  });

</script>

<div class="work-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Proyectos</h2>
      <div class="section-subtitle">Mejora tu productividad</div>
    </div>
  </div>
  
  <div class="tabs-bar">
    {#each tabs as tab}
    <button class="tab-btn" class:active={activeTab === tab.id} onclick={() => switchTab(tab.id)}>
      <span>{tab.icon}</span> {tab.label}
    </button>
    {/each}
  </div>
  
  {#if activeTab === 'kanban'}
  <Kanban {userId} bind:tasks {loading} />
  {:else if activeTab === 'projects'}
  <Projects userId={userId} bind:projects />
  {:else if activeTab === 'links'}
  <UsefulLinks userId={userId} bind:links />
  {:else if activeTab === 'skills'}
  <Skills userId={userId} bind:skills />
  {/if}
</div>

<Toast visible={copyToast} message="Copiado al portapapeles" />

<style>
  .work-page { width: 100%; }
  
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
  }

  .tab-btn.active { background: var(--surface2); color: var(--text); }
  .tab-btn:hover:not(.active) { background: var(--surface); color: var(--text2); }
</style>