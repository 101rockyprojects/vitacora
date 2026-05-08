<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { createRepository } from '$lib/services/repository';
  import { onDestroy } from 'svelte';
  import type { Book, LearningItem, SuccessExperience, Reward, MemoryPhoto, CalendarEvent, UsefulLink, CalendarTodo, Expense } from '$lib/types';
  import Vision from './Vision.svelte';
  import Books from './Books.svelte';
  import Learning from './Learning.svelte';
  import Memories from './Memories.svelte';
  import Calendar from './Calendar.svelte';
  import Successes from './Successes.svelte';
  import Rewards from './Rewards.svelte';
  import Expenses from './Expenses.svelte';

  const GOALS_TABS = ['vision', 'books', 'learning', 'memories', 'calendar', 'successes', 'rewards', 'expenses'] as const;
  type GoalsTab = typeof GOALS_TABS[number];

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let url = new URL(page.url.href);
  if (browser) {
    url = new URL(window.location.href);
  }
  const current = url.searchParams.get('tab');
  const defaultTab = GOALS_TABS.includes(current as GoalsTab) ? (current as GoalsTab) : 'vision';
  let activeTab = $state<GoalsTab>(defaultTab);

  let visionBoardLink = $state<UsefulLink | null>(null);
  let showVisionLinkForm = $state(false);
  let visionLinkMode = $state<'image' | 'canva'>('image');
  let visionLinkInput = $state('');
  let visionToast = $state(false);
  let visionToastTimer: ReturnType<typeof setTimeout> | null = $state(null);

  let books = $state<Book[]>([]);
  let learning = $state<LearningItem[]>([]);
  let memories = $state<MemoryPhoto[]>([]);
  let calEvents = $state<CalendarEvent[]>([]);
  let calendarTodos = $state<CalendarTodo[]>([]);
  let successes = $state<SuccessExperience[]>([]);
  let rewards = $state<Reward[]>([]);
  let expenses = $state<Expense[]>([]);

  let saving = $state(false);

  const tabs = [
    { id: 'vision', label: 'Visión', icon: '⊶' },
    { id: 'books', label: 'Libros', icon: '📚' },
    { id: 'learning', label: 'Aprendizaje', icon: '🧠' },
    { id: 'memories', label: 'Memorias', icon: '📸' },
    { id: 'calendar', label: 'Calendario', icon: '📅' },
    { id: 'successes', label: 'Logros', icon: '🏆' },
    { id: 'rewards', label: 'Recompensas', icon: '🎁' },
    { id: 'expenses', label: 'Gastos', icon: '💰' }
  ] as const;

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadAll();
    }
  });

  function switchTab(tabId: GoalsTab) {
    if (GOALS_TABS.includes(activeTab)) {
      activeTab = tabId as typeof activeTab;
      const next = new URL(window.location.href);
      next.searchParams.set('tab', activeTab);
      window.history.replaceState(window.history.state, '', next);
    } else {
      activeTab = 'vision';
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

  async function loadAll() {
    if (!userId) return;
    const [b, l, m, c, s, r, vb, ct, e] = await Promise.all([
      repo.books.list(),
      repo.learning.list(),
      repo.memories.list(),
      repo.calendar.list(),
      repo.successes.list(),
      repo.rewards.list(),
      repo.links.getVisionBoard(),
      repo.calendarTodos.list(),
      repo.expenses.list()
    ]);
    books = b.data || [];
    learning = l.data || [];
    memories = m.data || [];
    calEvents = c.data || [];
    successes = s.data || [];
    rewards = r.data || [];
    visionBoardLink = vb.data?.[0] || null;
    calendarTodos = ct.data || [];
    expenses = e.data || [];
    if (visionBoardLink?.link_type === 'vision_board_canva') visionLinkMode = 'canva';
    if (visionBoardLink?.link_type === 'vision_board_image') visionLinkMode = 'image';
    visionLinkInput = visionBoardLink?.url || '';
  }

  onDestroy(() => {
    if (visionToastTimer) {
      clearTimeout(visionToastTimer);
      visionToastTimer = null;
    }
  });

  async function saveVisionBoardLink() {
    const url = visionLinkInput.trim();
    if (!url) {
      alert('Agrega un enlace válido.');
      return;
    }
    if (!/^https?:\/\//i.test(url)) {
      alert('El enlace debe iniciar con http:// o https://');
      return;
    }

    const linkType = visionLinkMode === 'canva' ? 'vision_board_canva' : 'vision_board_image';
    const { error } = await repo.links.saveVisionBoard(url, linkType);
    if (error) {
      alert('No se pudo guardar el Vision Board Link.');
      return;
    }

    await loadAll();
    showVisionLinkForm = false;
    visionToast = true;
    if (visionToastTimer) clearTimeout(visionToastTimer);
    visionToastTimer = setTimeout(() => {
      visionToast = false;
      visionToastTimer = null;
    }, 3800);
  }

  export function refreshData() {
    return loadAll();
  }
</script>

<div class="goals-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Visión & Metas</h2>
      <div class="section-subtitle">Tu espacio de crecimiento</div>
    </div>
  </div>

  <div class="tabs-bar">
    {#each tabs as tab}
      <button class="tab-btn" class:active={activeTab === tab.id} onclick={() => switchTab(tab.id)}>
        <span>{tab.icon}</span> {tab.label}
      </button>
    {/each}
  </div>

  {#if activeTab === 'vision'}
    <Vision
      bind:visionBoardLink
      bind:showVisionLinkForm
      bind:visionLinkMode
      bind:visionLinkInput
      onSave={saveVisionBoardLink}
      onRefresh={loadAll}
    />
  {:else if activeTab === 'books'}
    <Books userId={userId} bind:books onRefresh={loadAll} />
  {:else if activeTab === 'learning'}
    <Learning userId={userId} bind:learning onRefresh={loadAll} />
  {:else if activeTab === 'memories'}
    <Memories userId={userId} bind:memories onRefresh={loadAll} />
  {:else if activeTab === 'calendar'}
    <Calendar userId={userId} bind:calEvents bind:calendarTodos onRefresh={loadAll} />
  {:else if activeTab === 'successes'}
    <Successes userId={userId} bind:successes onRefresh={loadAll} />
  {:else if activeTab === 'rewards'}
    <Rewards userId={userId} bind:rewards onRefresh={loadAll} />
  {:else if activeTab === 'expenses'}
    <Expenses userId={userId} bind:expenses onRefresh={loadAll} />
  {/if}
</div>

<style>
  .goals-page { max-width: 1100px; }

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

  .tab-btn.active {
    background: var(--surface2);
    color: var(--text);
  }

  .tab-btn:hover:not(.active) { background: var(--surface); color: var(--text2); }

  .tab-actions { margin-bottom: 20px; }
</style>