<script lang="ts">
  import type { CalendarEvent, CalendarTodo } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import WeekPlanner from '$lib/components/WeekPlanner.svelte';

  interface Props {
    userId: string;
    calEvents?: CalendarEvent[];
    calendarTodos?: CalendarTodo[];
    onRefresh?: () => void;
  }

  let { userId, calEvents = $bindable([]), calendarTodos = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showCalForm = $state(false);
  let calForm = $state<CalendarEvent>({ event_name: '', event_date: '', type: 'event' });

  let todoInput = $state('');
  let todoDateInput = $state(new Date().toISOString().split('T')[0]);
  let editingTodoId = $state<string | null>(null);
  let editTodoName = $state('');
  let editTodoDate = $state('');

  let saving = $state(false);

  async function addTodo() {
    const name = todoInput.trim();
    if (!name || !todoDateInput) return;
    saving = true;
    await repo.calendarTodos.insert({ name, todo_date: todoDateInput });
    todoInput = '';
    todoDateInput = new Date().toISOString().split('T')[0];
    const { data } = await repo.calendarTodos.list();
    calendarTodos = data || [];
    saving = false;
  }

  function startEditTodo(todo: CalendarTodo) {
    editingTodoId = todo.id || null;
    editTodoName = todo.name;
    editTodoDate = todo.todo_date;
  }

  async function saveEditTodo() {
    if (!editingTodoId || !editTodoName.trim() || !editTodoDate) return;
    saving = true;
    await repo.calendarTodos.update(editingTodoId, { name: editTodoName.trim(), todo_date: editTodoDate });
    editingTodoId = null;
    editTodoName = '';
    editTodoDate = '';
    const { data } = await repo.calendarTodos.list();
    calendarTodos = data || [];
    saving = false;
  }

  function cancelEditTodo() {
    editingTodoId = null;
    editTodoName = '';
    editTodoDate = '';
  }

  async function deleteTodo(id: string) {
    if (!confirm('¿Eliminar tarea?')) return;
    await repo.calendarTodos.remove(id);
    const { data } = await repo.calendarTodos.list();
    calendarTodos = data || [];
  }

  async function saveCal() {
    saving = true;
    await repo.calendar.insert(calForm);
    calForm = { event_name: '', event_date: '', type: 'event' };
    showCalForm = false;
    const { data } = await repo.calendar.list();
    calEvents = data || [];
    saving = false;
  }
</script>

<div class="fade-in">
  <div class="task-title">Pendientes</div>
  <div class="calendar-todo-section">
    <div class="todo-header">
      <div class="todo-form">
        <input
          type="text"
          bind:value={todoInput}
          placeholder="Nueva tarea..."
          class="todo-input"
          onkeydown={(e) => e.key === 'Enter' && addTodo()}
        />
        <input
          type="date"
          bind:value={todoDateInput}
          class="todo-date"
        />
        <button class="btn btn-primary" onclick={addTodo} disabled={!todoInput.trim()}>+</button>
      </div>
    </div>
    {#if calendarTodos.length === 0}
      <div class="empty-todos">Sin tareas pendientes</div>
    {:else}
      <div class="todo-list">
        {#each calendarTodos as todo (todo.id)}
          <div class="todo-item">
            {#if editingTodoId === todo.id}
              <div class="todo-edit-form">
                <input
                  type="text"
                  bind:value={editTodoName}
                  class="todo-edit-input"
                  onkeydown={(e) => e.key === 'Enter' && saveEditTodo()}
                />
                <input
                  type="date"
                  bind:value={editTodoDate}
                  class="todo-edit-date"
                />
                <button class="btn btn-primary" onclick={saveEditTodo}>Guardar</button>
                <button class="btn btn-secondary" onclick={cancelEditTodo}>Cancelar</button>
              </div>
            {:else}
              <span class="todo-name">{todo.name}</span>
              <span class="todo-date-label">{new Date(todo.todo_date).toLocaleDateString('es-ES')}</span>
              <div class="todo-actions">
                <button class="small-btn btn-secondary" onclick={() => startEditTodo(todo)}>🖋</button>
                <button class="small-btn btn-ghost" onclick={() => deleteTodo(todo.id!)}>✕</button>
              </div>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </div>
  <hr style="border: none; border-top: 1px solid var(--border); margin: 20px 0;" />
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { calForm = { event_name: '', event_date: '', type: 'event' }; showCalForm = true; }}>+ Agregar evento</button>
  </div>
  <WeekPlanner events={calEvents} todos={calendarTodos} />
</div>

{#if showCalForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showCalForm = false
        }
      }}>
    <div class="modal">
      <h3>Nuevo evento</h3>
      <div class="form-group"><label>Nombre</label><input bind:value={calForm.event_name} placeholder="Cumpleaños, viaje..." /></div>
      <div class="form-group"><label>Fecha</label><input type="date" bind:value={calForm.event_date} /></div>
      <div class="form-group">
        <label>Tipo</label>
        <select bind:value={calForm.type}>
          <option value="event">Evento</option>
          <option value="special_day">Día especial</option>
        </select>
      </div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showCalForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveCal} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .task-title {
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 600;
    color: var(--text);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin-bottom: 12px;
  }

  .calendar-todo-section {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 20px;
    margin-bottom: 20px;
  }

  .todo-header {
    margin-bottom: 12px;
  }

  .todo-form {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
  }

  .todo-input {
    flex: 1;
    min-width: 150px;
  }

  .todo-date {
    width: 140px;
  }

  .empty-todos {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 16px;
  }

  .todo-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .todo-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px;
    background: var(--bg3);
    border-radius: 8px;
  }

  .todo-name {
    flex: 1;
    font-size: 14px;
    color: var(--text);
  }

  .todo-date-label {
    font-size: 12px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .todo-actions {
    display: flex;
    gap: 4px;
  }

  .todo-edit-form {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    width: 100%;
  }

  .todo-edit-input {
    flex: 1;
    min-width: 150px;
  }

  .todo-edit-date {
    width: 140px;
  }
</style>