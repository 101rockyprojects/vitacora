<script lang="ts">
  import type { Task } from '$lib/types';

  interface Props {
    tasks?: Task[];
    loading?: boolean;
  }

  let { tasks = [], loading = false }: Props = $props();

  const todayTasks = $derived(tasks.filter(t => t.status !== 'done' && t.status !== 'to_review').slice(0, 5));
</script>

<div class="card">
  <h3 class="card-title">Pendientes <a href="/work" class="card-link">Ver pendientes →</a></h3>
  {#if loading}
    <div class="placeholder-list">
      {#each [1,2,3] as _}
        <div class="placeholder-item pulse"></div>
      {/each}
    </div>
  {:else if todayTasks.length === 0}
    <div class="empty-state">Sin tareas pendientes 🎉</div>
  {:else}
    <div class="task-list">
      {#each todayTasks as task}
        <div class="task-item">
          <span class="task-sta-dot" style="background:{task.status === 'doing' ? 'var(--accent-yellow)' : 'var(--accent-blue)'}"></span>
          <div class="task-item-info">
            <div class="task-item-title">{task.title}</div>
            {#if task.due_date}
              <div class="task-item-due">{new Date(task.due_date).toLocaleDateString('es-ES')}</div>
            {/if}
          </div>
          <span class="task-sta-tag">{task.status}</span>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .card-title {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-family: var(--font-display);
  }

  .card-link {
    font-size: 12px;
    color: var(--accent-green);
    font-weight: 500;
    font-family: var(--font-body);
  }

  .task-list { display: flex; flex-direction: column; gap: 8px; }

  .task-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px;
    border-radius: 8px;
    background: var(--bg3);
  }

  .task-sta-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .task-item-info { flex: 1; min-width: 0; }

  .task-item-title {
    font-size: 13px;
    color: var(--text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .task-item-due {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .task-sta-tag {
    font-size: 10px;
    color: var(--text3);
    font-family: var(--font-mono);
    background: var(--bg2);
    padding: 2px 6px;
    border-radius: 4px;
    white-space: nowrap;
  }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: center;
    padding: 24px 0;
  }

  .placeholder-list { display: flex; flex-direction: column; gap: 8px; }
  .placeholder-item {
    height: 40px;
    background: var(--bg3);
    border-radius: 8px;
  }
</style>