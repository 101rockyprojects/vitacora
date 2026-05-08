<script lang="ts">
  import type { Task, Book } from '$lib/types';

  interface Props {
    totalXP: number;
    tasks?: Task[];
    books?: Book[];
    userBadgesCount: number;
  }

  let { totalXP, tasks = [], books = [], userBadgesCount = 0 }: Props = $props();

  const todayTasks = $derived(tasks.filter(t => t.status !== 'done').slice(0, 5));
</script>

<div class="stats-row">
  <div class="stat-card">
    <span class="stat-icon">⚡</span>
    <div>
      <div class="stat-num">{totalXP}</div>
      <div class="stat-label">XP Total</div>
    </div>
  </div>
  <div class="stat-card">
    <span class="stat-icon">📋</span>
    <div>
      <div class="stat-num">{todayTasks.length}</div>
      <div class="stat-label">Tareas activas</div>
    </div>
  </div>
  <div class="stat-card">
    <span class="stat-icon">📚</span>
    <div>
      <div class="stat-num">{books.length}</div>
      <div class="stat-label">Libros</div>
    </div>
  </div>
  <div class="stat-card">
    <span class="stat-icon">🏅</span>
    <div>
      <div class="stat-num">{userBadgesCount}</div>
      <div class="stat-label">Logros</div>
    </div>
  </div>
</div>

<style>
  .stats-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
    margin-bottom: 24px;
  }

  .stat-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .stat-icon { font-size: 22px; }

  .stat-num {
    font-family: var(--font-display);
    font-size: 22px;
    font-weight: 800;
    color: var(--text);
    line-height: 1;
  }

  .stat-label {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-top: 2px;
  }

  @media (max-width: 900px) {
    .stats-row { grid-template-columns: 1fr 1fr; }
  }
</style>