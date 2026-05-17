<script lang="ts">
  import type { Task } from '$lib/types';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import { createRepository } from '$lib/services/repository';
  import { page } from '$app/state';
  import { workFilterTag } from '$lib/stores/workFilter.svelte';

  interface Props {
    userId: string;
    tasks?: Task[];
    onTasksChange?: (tasks: Task[]) => void;
    useWorkFilter?: boolean;
  }

  let { userId, tasks = $bindable([]), onTasksChange, useWorkFilter = false }: Props = $props();

  const filterTag = $derived(useWorkFilter ? workFilterTag.value : null);

  const repo = $derived(createRepository(userId));
  const statuses: { id: Task['status']; label: string; color: string }[] = [
    { id: 'to_do', label: 'Por hacer', color: 'var(--accent-blue)' },
    { id: 'doing', label: 'En progreso', color: 'var(--accent-yellow)' },
    { id: 'done', label: 'Hecho', color: 'var(--accent-green)' },
    { id: 'to_review', label: 'Revisar', color: 'var(--accent-orange)' }
  ];

  let showTaskForm = $state(false);
  let editingTask = $state<Task | null>(null);
  let taskForm = $state<Task>({ title: '', status: 'to_do' });
  let draggedTask = $state<Task | null>(null);
  let selectedTags = $state<string[]>(page.data.selectedTags ?? []);
  let expandedTaskDescKeys = $state<string[]>([]);
  let collapsedColumns = $state<Record<string, boolean>>({
    to_do: false,
    doing: false,
    done: true,
    to_review: true
  });
  let saving = $state(false);

  const selectedTagSet = $derived(new Set(selectedTags));
  const expandedTaskDescSet = $derived(new Set(expandedTaskDescKeys));
  const tagCounts = $derived((() => {
    const counts = new Map<string, number>();
    for (const task of tasks) {
      for (const tag of task.tags ?? []) {
        const normalized = tag.trim();
        if (!normalized) continue;
        counts.set(normalized, (counts.get(normalized) ?? 0) + 1);
      }
    }
    return [...counts.entries()]
      .map(([tag, count]) => ({ tag, count }))
      .sort((a, b) => b.count - a.count || a.tag.localeCompare(b.tag, 'es', { sensitivity: 'base' }));
  })());

  function toggleTagFilter(tag: string) {
    const normalized = tag.trim();
    if (!normalized) return;
    if (selectedTagSet.has(normalized)) selectedTags = selectedTags.filter((t) => t !== normalized);
    else selectedTags = [...selectedTags, normalized];
    syncSelectedTagsToUrl();
  }

  function clearTagFilters() {
    selectedTags = [];
    syncSelectedTagsToUrl();
  }

  function syncSelectedTagsToUrl() {
    if (typeof window === 'undefined') return;
    const next = new URL(window.location.href);
    next.searchParams.delete('tag');
    for (const tag of selectedTags) next.searchParams.append('tag', tag);
    window.history.replaceState(window.history.state, '', next);
  }

  function matchesTagFilters(task: Task, filters: string[]): boolean {
    if (filters.length === 0) return true;
    const tags = task.tags ?? [];
    return filters.some((filter) => tags.includes(filter));
  }

  const workFilteredTasks = $derived(
    filterTag ? tasks.filter(t => t.tags?.includes(filterTag)) : tasks
  );

  const filteredTasks = $derived(workFilteredTasks.filter((t) => matchesTagFilters(t, selectedTags)));

  function staTasks(sta: Task['status']) {
    return filteredTasks.filter(t => t.status === sta);
  }

  function getTaskKey(task: Task): string {
    if (task.id) return task.id;
    const createdAt = task.created_at ?? '';
    return `${task.title}::${createdAt}`;
  }

  function getTaskDescDomId(key: string): string {
    return `task-desc-${key.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
  }

  function toggleTaskDescription(key: string) {
    if (expandedTaskDescSet.has(key)) expandedTaskDescKeys = expandedTaskDescKeys.filter((k) => k !== key);
    else expandedTaskDescKeys = [...expandedTaskDescKeys, key];
  }

  function resetTaskForm() { taskForm = { title: '', status: 'to_do' }; editingTask = null; }

  async function saveTask() {
    saving = true;
    if (editingTask?.id) {
      await repo.tasks.update(editingTask.id, { ...taskForm, updated_at: new Date().toISOString() });
      if (taskForm.status === 'done' && editingTask.status !== 'done') {
        await awardXP(userId, 'work', 'task_done', XP_VALUES.task_done, editingTask.id);
      }
    } else {
      await repo.tasks.insert(taskForm);
    }
    const { data } = await repo.tasks.list();
    tasks = data || [];
    showTaskForm = false;
    resetTaskForm();
    saving = false;
  }

  async function moveTask(task: Task, sta: Task['status']) {
    if (task.status === sta) return;
    const wasDone = task.status === 'done';
    await repo.tasks.update(task.id!, { status: sta, updated_at: new Date().toISOString() });
    if (sta === 'done' && !wasDone) await awardXP(userId, 'work', 'task_done', XP_VALUES.task_done, task.id);
    const { data } = await repo.tasks.list();
    tasks = data || [];
  }

  async function deleteTask(id: string) {
    if (!confirm('¿Eliminar tarea?')) return;
    await repo.tasks.remove(id);
    const { data } = await repo.tasks.list();
    tasks = data || [];
  }

  function editTask(t: Task) { editingTask = t; taskForm = { ...t }; showTaskForm = true; }

  function onDragStart(task: Task) { draggedTask = task; }

  async function onDrop(sta: Task['status']) {
    if (draggedTask && draggedTask.status !== sta) {
      await moveTask(draggedTask, sta);
    }
    draggedTask = null;
  }

  export function openNewTask() {
    resetTaskForm();
    showTaskForm = true;
  }
</script>

<div class="fade-in">
  <div class="tab-actions kanban-actions">
    <button class="btn btn-primary" onclick={() => { resetTaskForm(); showTaskForm = true; }}>+ Nueva tarea</button>
    {#if !useWorkFilter && tagCounts.length > 0}
      <div class="tag-filters" aria-label="Filtrar por tags">
        <span class="tag-filter-label">Tags:</span>
        {#each tagCounts as t}
          <button
            class="tag-filter"
            class:active={selectedTagSet.has(t.tag)}
            type="button"
            onclick={() => toggleTagFilter(t.tag)}
            aria-pressed={selectedTagSet.has(t.tag)}
          >
            {t.tag} <span class="tag-filter-count">({t.count})</span>
          </button>
        {/each}
        {#if selectedTags.length > 0}
          <button class="tag-filter-clear" type="button" onclick={clearTagFilters}>Limpiar</button>
        {/if}
      </div>
    {/if}
  </div>
  <div class="kanban-board">
    {#each statuses as sta}
      {@const isCollapsed = collapsedColumns[sta.id]}
      <div
        class="kanban-sta"
        class:collapsed={isCollapsed}
        class:wide={sta.id === 'to_review'}
        ondragover={(e) => e.preventDefault()}
        ondrop={() => onDrop(sta.id)}
        role="region"
        aria-label={sta.label}
      >
        <button
          class="kanban-sta-header"
          type="button"
          onclick={() => collapsedColumns[sta.id] = !collapsedColumns[sta.id]}
          aria-expanded={!isCollapsed}
        >
          <span class="sta-toggle" class:collapsed={isCollapsed}>❯</span>
          <span class="sta-dot" style="background:{sta.color}"></span>
          <span class="sta-label">{sta.label}</span>
          <span class="sta-count" class:active={staTasks(sta.id).length > 0} style="--status-color: {sta.color}">
            {staTasks(sta.id).length}
            </span>
        </button>
        {#if !isCollapsed}
          <div class="kanban-cards">
            {#each staTasks(sta.id) as task}
              {@const key = getTaskKey(task)}
              {@const descId = getTaskDescDomId(key)}
              <div
                id={`card-${task.id ?? key}`}
                class="kanban-card"
                class:wide={sta.id === 'to_review'}
                draggable="true"
                role="application"
                ondragstart={() => onDragStart(task)}
              >
                <div class="kcard-header">
                  <div class="kcard-title">{task.title}</div>
                  {#if task.description && task.description.trim() !== ''}
                    <button
                      class="kcard-desc-toggle"
                      type="button"
                      draggable="false"
                      aria-expanded={expandedTaskDescSet.has(key)}
                      aria-controls={descId}
                      onpointerdown={(e) => e.stopPropagation()}
                      onclick={(e) => { e.stopPropagation(); toggleTaskDescription(key); }}
                      ondragstart={(e) => e.preventDefault()}
                    >
                      <span class="kcard-desc-toggle-label">
                        {expandedTaskDescSet.has(key) ? 'Ocultar' : 'Ver más'}
                      </span>
                      <span class="kcard-desc-toggle-icon" class:open={expandedTaskDescSet.has(key)}>▾</span>
                    </button>
                  {/if}
                </div>
                {#if task.description && expandedTaskDescSet.has(key)}
                  <div class="kcard-desc" id={descId}>{task.description}</div>
                {/if}
                {#if task.tags?.length && expandedTaskDescSet.has(key)}
                  <div class="kcard-tags">
                    {#each task.tags as tag}
                      <span class="tag">{tag}</span>
                    {/each}
                  </div>
                {/if}
                {#if task.due_date}
                  <div class="kcard-due">📅 {new Date(task.due_date).toLocaleDateString('es-ES')}</div>
                {/if}
                <div class="kcard-actions">
                  <select class="kcard-move" onchange={(e) => moveTask(task, (e.target as HTMLSelectElement).value as Task['status'])} value={task.status}>
                    {#each statuses as s}
                      <option value={s.id}>{s.label}</option>
                    {/each}
                  </select>
                  <button class="btn btn-secondary" style="font-size:11px;padding:3px 6px;" onclick={() => editTask(task)}>Editar</button>
                  <button class="btn btn-ghost" style="font-size:11px;color:var(--accent-red);padding:3px 6px;" onclick={() => deleteTask(task.id!)}>✕</button>
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </div>
    {/each}
  </div>
</div>

{#if showTaskForm}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) { showTaskForm = false; resetTaskForm(); } }}
    onkeydown={(e) => { if (e.key === 'Escape') { showTaskForm = false; resetTaskForm(); } }}
    role="presentation"
  >
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="task-form-title">
      <h3 id="task-form-title">{editingTask ? 'Editar tarea' : 'Nueva tarea'}</h3>
      <form onsubmit={(e) => { e.preventDefault(); saveTask(); }}>
        <div class="form-group">
          <label for="task-title">Título</label>
          <input id="task-title" bind:value={taskForm.title} placeholder="¿Qué hay que hacer?" />
        </div>
        <div class="form-group">
          <label for="task-desc">Descripción</label>
          <textarea id="task-desc" bind:value={taskForm.description} rows="2"></textarea>
        </div>
        <div class="form-group">
          <label for="task-status">Status</label>
          <select id="task-status" bind:value={taskForm.status}>
            {#each statuses as sta}
              <option value={sta.id}>{sta.label}</option>
            {/each}
          </select>
        </div>
        <div class="form-group">
          <label for="task-due">Fecha límite</label>
          <input id="task-due" type="date" bind:value={taskForm.due_date} />
        </div>
        <div class="form-group">
          <label for="task-tags">Tags (coma separados)</label>
          <input
            id="task-tags"
            value={taskForm.tags?.join(', ') || ''}
            oninput={(e) => { taskForm.tags = (e.target as HTMLInputElement).value.split(',').map(t => t.trim()).filter(Boolean); }}
            placeholder="ej: urgente, trabajo, personal"
          />
        </div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick={() => { showTaskForm = false; resetTaskForm(); }}>Cancelar</button>
          <button type="submit" class="btn btn-primary" disabled={saving}>{saving ? '...' : 'Guardar'}</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .kanban-actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
  }

  .tag-filters {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-wrap: wrap;
    justify-content: flex-end;
  }

  .tag-filter-label {
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
    margin-right: 2px;
    user-select: none;
  }

  .tag-filter {
    font-size: 12px;
    padding: 4px 10px;
    border-radius: 8px;
    background: var(--bg2);
    border: 1px solid var(--border);
    color: var(--text2);
    text-transform: uppercase;
    font-family: var(--font-mono);
    font-weight: 600;
    transition: all var(--transition);
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }

  .tag-filter:hover { border-color: var(--accent-green); color: var(--text2); }

  .tag-filter.active {
    background: rgba(168,230,207,0.12);
    border-color: rgba(168,230,207,0.45);
    color: var(--text);
  }

  .tag-filter-count {
    font-size: 11px;
    opacity: 0.85;
    font-family: var(--font-mono);
  }

  .tag-filter-clear {
    font-size: 12px;
    padding: 4px 10px;
    border-radius: 999px;
    color: var(--text3);
    border: 1px dashed var(--border);
    background: transparent;
    transition: all var(--transition);
  }

  .tag-filter-clear:hover { border-color: var(--text3); color: var(--text2); }

  .kanban-board {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    align-items: start;
  }

  .kanban-sta {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 14px;
    min-height: 300px;
    max-height: 600px;
    overflow-y: auto;
    transition: all var(--transition);
  }

  .kanban-sta.collapsed {
    min-height: auto;
    padding: 10px 14px;
    max-height: none;
    overflow: visible;
  }

  .kanban-sta.collapsed .kanban-cards {
    display: none;
  }

  .kanban-sta.wide {
    grid-column: span 3;
  }

  .kanban-sta-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 14px;
    cursor: pointer;
    background: none;
    border: none;
    width: 100%;
    padding: 0;
    text-align: left;
  }

  .kanban-sta.collapsed .kanban-sta-header {
    margin-bottom: 0;
  }

  .sta-toggle {
    font-size: 10px;
    color: var(--text3);
    transition: transform var(--transition);
    flex-shrink: 0;
    transform: rotate(90deg);
  }

  .sta-toggle.collapsed {
    transform: rotate(0deg);
  }

  .kanban-sta-header:hover .sta-toggle {
    color: var(--text);
  }

  .kanban-sta-header:hover {
    color: var(--text);
  }

  .sta-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

  .sta-label {
    font-size: 12px;
    font-weight: 700;
    color: var(--text2);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    font-family: var(--font-mono);
    flex: 1;
  }

  .sta-count {
    font-size: 12px;
    color: var(--text3);
    background: var(--bg3);
    border-radius: 99px;
    padding: 1px 7px;
    font-family: var(--font-mono);
  }
  .sta-count.active {
    background: var(--status-color);
    color: var(--bg3);
  }

  .kanban-cards { display: flex; flex-direction: row; gap: 10px; }

  .kanban-card {
    width: 100%;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 12px;
    cursor: grab;
    transition: all var(--transition);
  }

  .kanban-card:hover { border-color: var(--accent-green); transform: translateY(-1px); }
  .kanban-card:active { cursor: grabbing; }

  .kanban-card.wide {
    width: 33.33%;
  }

  .kcard-header {
    display: flex;
    align-items: flex-start;
    flex-wrap: wrap;
    justify-content: space-between;
    margin-bottom: 4px;
  }

  .kcard-title { font-size: 14px; font-weight: 600; color: var(--text); margin-bottom: 4px; line-height: 1.3; }
  .kcard-desc { font-size: 12px; color: var(--text2); margin-bottom: 6px; }
  .kcard-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 6px; }
  .kcard-due { font-size: 11px; color: var(--text3); font-family: var(--font-mono); margin-bottom: 8px; }

  .kcard-desc-toggle {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    font-family: var(--font-mono);
    padding: 3px 8px;
    border-radius: var(--radius-sm);
    background: var(--bg3);
    border: 1px solid var(--border);
    color: var(--text);
    transition: all var(--transition);
    cursor: pointer;
    flex-shrink: 0;
  }

  .kcard-desc-toggle:hover { border-color: var(--text3); color: var(--text2); }

  .kcard-desc-toggle-icon {
    display: inline-block;
    transition: transform var(--transition);
    transform-origin: center;
  }

  .kcard-desc-toggle-icon.open { transform: rotate(180deg); }

  .tag {
    font-size: 11px;
    padding: 2px 7px;
    border-radius: 999px;
    background: var(--bg3);
    border: 1px solid var(--border);
    color: var(--text3);
    font-family: var(--font-mono);
    white-space: nowrap;
  }

  .kcard-actions {
    display: flex;
    align-items: center;
    gap: 4px;
    border-top: 1px solid var(--border);
    padding-top: 8px;
    margin-top: 4px;
  }

  .kcard-move {
    font-size: 11px;
    padding: 3px 6px;
    flex: 1;
    background: var(--bg3);
    border-radius: 6px;
    cursor: pointer;
  }

  @media (max-width: 900px) {
    .kanban-board { grid-template-columns: 1fr 1fr; }
    .kanban-sta.wide { grid-column: span 1; }
    .kanban-card.wide { width: 100%; }
  }

  @media (max-width: 768px) {
    .kanban-sta.collapsed {
      padding: 8px 10px;
    }

    .kanban-sta.collapsed .sta-label {
      writing-mode: horizontal-tb;
    }

    .sta-toggle.collapsed {
      transform: none;
    }
  }

  @media (max-width: 600px) {
    .kanban-board { grid-template-columns: 1fr; }
  }
</style>