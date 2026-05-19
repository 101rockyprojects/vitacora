<script lang="ts">
  import Kanban from '$lib/components/projects/Kanban.svelte';
  import { createRepository } from '$lib/services/repository';
  import type { Task } from '$lib/types';
  import { page } from '$app/state';
  import { workFilterTag } from '$lib/stores/workFilter.svelte';
  import Toast from '$lib/components/Toast.svelte';

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  
  let tasks = $state<Task[]>([]);
  let initialized = $state(false);
  let loading = $state(true);
  let editingFilter = $state(false);
  let filterInput = $state('');
  let resumeStart = $state('');
  let resumeEnd = $state('');
  let copyToast = $state(false);
  let copyToastTimer: ReturnType<typeof setTimeout> | null = $state(null);

  function getWeekRange() {
    const now = new Date();
    const dayOfWeek = now.getDay();
    const monday = new Date(now);
    monday.setDate(now.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    return {
      start: monday.toISOString().split('T')[0],
      end: sunday.toISOString().split('T')[0]
    };
  }

  function loadDateRange() {
    if (typeof window === 'undefined') return;
    const stored = localStorage.getItem('vitacora_resume_date_range');
    if (stored) {
      const { start, end } = JSON.parse(stored);
      resumeStart = start;
      resumeEnd = end;
    } else {
      const range = getWeekRange();
      resumeStart = range.start;
      resumeEnd = range.end;
    }
  }

  function saveDateRange() {
    if (typeof window === 'undefined') return;
    localStorage.setItem('vitacora_resume_date_range', JSON.stringify({ start: resumeStart, end: resumeEnd }));
  }

  $effect(() => {
    if (typeof window !== 'undefined' && !resumeStart) {
      loadDateRange();
    }
  });

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      loadTasks();
    }
  });

  async function loadTasks() {
    if (!userId) return;
    const { data } = await repo.tasks.list();
    tasks = data || [];
    loading = false;
  }

  function handleTasksChange(updatedTasks: Task[]) {
    tasks = updatedTasks;
  }

  function toggleFilterEditor() {
    filterInput = workFilterTag.value;
    editingFilter = !editingFilter;
  }

  function saveFilter() {
    if (filterInput.trim()) {
      workFilterTag.set(filterInput.trim());
    }
    editingFilter = false;
  }

  function resetFilter() {
    if (!confirm('¿Restablecer filtro? El filtro se reiniciará con el valor \'trabajo\'.')) return;
    workFilterTag.reset();
    editingFilter = false;
  }

  const resumeTasks = $derived(() => {
    if (!resumeStart || !resumeEnd) return [];
    const tag = workFilterTag.value;
    const startDate = new Date(resumeStart);
    const endDate = new Date(resumeEnd);
    endDate.setHours(23, 59, 59, 999);

    return tasks
      .filter(t => 
        (t.status === 'done' || t.status === 'to_review') &&
        t.tags?.includes(tag) &&
        t.updated_at &&
        new Date(t.updated_at) >= startDate &&
        new Date(t.updated_at) <= endDate
      )
      .sort((a, b) => {
        const dateA = a.created_at ? new Date(a.created_at).getTime() : 0;
        const dateB = b.created_at ? new Date(b.created_at).getTime() : 0;
        return dateA - dateB;
      });
  });

  async function copyResumeContent() {
    const list = resumeTasks();
    if (list.length === 0) {
      alert('No hay tareas completadas para copiar.');
      return;
    }
    const dateLabel = `${resumeStart} al ${resumeEnd}`;
    const text = `📋 Tareas completadas (${dateLabel})\n${list.map(t => `- ${t.title}`).join('\n')}`;
    try {
      await navigator.clipboard.writeText(text);
      copyToast = true;
      if (copyToastTimer) clearTimeout(copyToastTimer);
      copyToastTimer = setTimeout(() => {
        copyToast = false;
        copyToastTimer = null;
      }, 2500);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }
</script>

<Toast visible={copyToast} message="Copiado al portapapeles" />

<div class="fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">{workFilterTag.value}</h2>
      <div class="section-subtitle">Organiza tu flujo de trabajo</div>
    </div>
  </div>

  <div class="filter-kanban">
    <button class="btn-filter" type="button" onclick={toggleFilterEditor} title="Editar filtro de trabajo">
      <span class="filter-icon">🏷️ Filtro:</span>
      <span class="filter-tag">{workFilterTag.value}</span>
    </button>
    
    {#if editingFilter}
      <div class="filter-editor">
        <label for="filter-input">Tag para filtrar:</label>
        <input 
          id="filter-input"
          type="text" 
          bind:value={filterInput} 
          placeholder="ej: trabajo, work, laboral"
          onkeydown={(e) => e.key === 'Enter' && saveFilter()}
        />
        <div class="filter-actions">
          <button class="btn btn-secondary" onclick={resetFilter}>Restablecer</button>
          <button class="btn btn-primary" onclick={saveFilter}>Guardar</button>
        </div>
      </div>
    {/if}
  </div>

  <article class="resume-section">
    <div class="resume-header">
      <div class="resume-info">
        <h3 class="resume-title">Resumen de la semana</h3>
        <button class="btn-copy" onclick={() => copyResumeContent()} title="Copiar resumen">❏ Copiar</button>
      </div>
      <form class="resume-dates">
        <div class="form-group">
          <label for="resume-start">Desde:</label>
          <input id="resume-start" type="date" bind:value={resumeStart} onchange={saveDateRange} />
        </div>
        <div class="form-group">
          <label for="resume-end">Hasta:</label>
          <input id="resume-end" type="date" bind:value={resumeEnd} onchange={saveDateRange} />
        </div>
      </form>
    </div>
    {#if resumeTasks().length > 0}
      <ul class="resume-list">
        {#each resumeTasks() as task}
          <li class="resume-item">
            <span class="resume-check">✓</span>
            <span class="resume-task-title">{task.title}</span>
          </li>
        {/each}
      </ul>
      <div class="resume-count">{resumeTasks().length} tarea{resumeTasks().length === 1 ? '' : 's'} completada{resumeTasks().length === 1 ? '' : 's'}</div>
    {:else}
      <div class="resume-empty">No hay tareas completadas en este período</div>
    {/if}
  </article>

  {#if loading}
  <div class="loading">Cargando...</div>
  {:else}
    <Kanban 
      {userId} 
      tasks={tasks} 
      onTasksChange={handleTasksChange}
      useWorkFilter={true}
    />
  {/if}
</div>

<style>
  .loading {
    text-align: center;
    padding: 40px;
    color: var(--text3);
  }

  .filter-kanban {
    display: flex;
    justify-content: flex-start;
    align-items: flex-start;
    flex: auto 1;
    gap: 8px;
    margin-bottom: 16px;
  }

  .btn-filter {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--text2);
    font-family: var(--font-mono);
    font-size: 12px;
    cursor: pointer;
    transition: all var(--transition);
  }

  .btn-filter:hover {
    border-color: var(--accent-green);
    color: var(--text);
  }

  .filter-icon { font-size: 14px; }

  .filter-tag {
    background: var(--bg3);
    padding: 2px 6px;
    border-radius: 4px;
  }

  .filter-editor {
    position: relative;
    flex: 1;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 14px;
    display: flex;
    flex-direction: column;
    gap: 15px;
  }

  .filter-editor label {
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
  }

  .filter-editor input {
    padding: 8px 12px;
    font-size: 14px;
  }

  .filter-actions {
    position: absolute;
    right: 15px;
    top: 6px;
    display: flex;
    gap: 8px;
    justify-content: flex-end;
  }

  .resume-section {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    margin-bottom: 20px;
  }

  .resume-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
    margin-bottom: 12px;
  }

  .resume-info {
    display: flex;
    flex-direction: column;
    align-items: start;
    gap: 6px;
  }

  .resume-title {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    margin: 0;
    font-family: var(--font-mono);
  }

  .form-group {
    margin-bottom: 5px;
  }

  .resume-dates {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;
  }

  .resume-dates label {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .resume-dates input {
    padding: 4px 8px;
    font-size: 12px;
    font-family: var(--font-mono);
    width: 130px;
  }

  .btn-copy {
    padding: 5px 10px;
    background: var(--bg3);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    font-size: 12px;
    font-family: var(--font-mono);
    color: var(--text2);
    cursor: pointer;
    transition: all var(--transition);
  }

  .btn-copy:hover {
    border-color: var(--accent-green);
    color: var(--text);
  }

  .resume-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
    max-height: 150px;
    overflow-y: auto;
  }

  .resume-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 10px;
    background: var(--surface);
    border-radius: var(--radius);
    font-size: 13px;
  }

  .resume-check {
    color: var(--accent-green);
    font-weight: 700;
  }

  .resume-task-title {
    color: var(--text);
  }

  .resume-count {
    margin-top: 10px;
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
    text-align: right;
  }

  .resume-empty {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 12px;
  }

  @media (max-width: 768px) {
    .filter-kanban { flex-direction: column; }
    .filter-editor { width: 100%; }
  }
</style>