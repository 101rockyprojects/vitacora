<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { createRepository } from '$lib/services/repository';
  import Toast from '$lib/components/Toast.svelte';
  import Kanban from './Kanban.svelte';
  import Projects from './PersonalProjects.svelte';
  import UsefulLinks from './UsefulLinks.svelte';
  import Skills from './Skills.svelte';
  import type { Task, Project, UsefulLink, SkillsMd } from '$lib/types';

  const WORK_TABS = ['kanban', 'projects', 'links', 'skills'] as const;
  type WorkTab = typeof WORK_TABS[number];

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let url = new URL(page.url.href);
  if (browser) {
    url = new URL(window.location.href);
  }
  const current = url.searchParams.get('tab');
  const defaultTab = WORK_TABS.includes(current as WorkTab) ? (current as WorkTab) : 'kanban';
  let activeTab = $state<WorkTab>(defaultTab);

  let tasks = $state<Task[]>([]);
  let projects = $state<Project[]>([]);
  let links = $state<UsefulLink[]>([]);
  let skills = $state<SkillsMd[]>([]);
  let copyToast = $state(false);

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadAll();
    }
  });

  function switchTab(tabId: WorkTab) {
    if (WORK_TABS.includes(activeTab)) {
      activeTab = tabId as typeof activeTab;
      const next = new URL(window.location.href);
      next.searchParams.set('tab', activeTab);
      window.history.replaceState(window.history.state, '', next);
    } else {
      activeTab = 'kanban';
    }
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
  }

  $effect(() => {
    if (typeof window === 'undefined') return;
    const urlTags = page.url.searchParams.getAll('tag').map((t) => t.trim()).filter(Boolean);
    const unique = [...new Set(urlTags)];
  });

  const tabs = [
    { id: 'kanban', label: 'Kanban', icon: '⌘' },
    { id: 'projects', label: 'Proyectos', icon: '🚀' },
    { id: 'links', label: 'Links útiles', icon: '🔗' },
    { id: 'skills', label: 'Markdown', icon: '📝' }
  ] as const;
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
  <Kanban {userId} bind:tasks />
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
  .work-page { max-width: 1200px; }
  
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