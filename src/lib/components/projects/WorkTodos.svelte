<script lang="ts">
  import type { WorkTodo } from '$lib/types';
  import { createRepository } from '$lib/services/repository';

  interface Props {
    userId: string;
    todos?: WorkTodo[];
    onTodosChange?: (todos: WorkTodo[]) => void;
  }

  let { userId, todos = $bindable([]), onTodosChange }: Props = $props();

  const repo = $derived(createRepository(userId));
  let todoInput = $state('');
  let saving = $state(false);

  const pending = $derived(todos.filter(t => !t.done));
  const doneTodos = $derived(todos.filter(t => t.done));

  async function addTodo() {
    const name = todoInput.trim();
    if (!name || saving) return;
    saving = true;
    await repo.workTodos.insert({ name, done: false });
    todoInput = '';
    const { data } = await repo.workTodos.list();
    todos = data || [];
    onTodosChange?.(todos);
    saving = false;
  }

  async function toggleTodo(todo: WorkTodo) {
    if (!todo.id) return;
    await repo.workTodos.update(todo.id, { done: !todo.done });
    const { data } = await repo.workTodos.list();
    todos = data || [];
    onTodosChange?.(todos);
  }

  async function deleteTodo(id: string) {
    await repo.workTodos.remove(id);
    const { data } = await repo.workTodos.list();
    todos = data || [];
    onTodosChange?.(todos);
  }
</script>

<div class="card work-todos">
  <div class="work-todos-head">
    <h3 class="wt-title">Pendientes <span class="todos-count">{pending.length}</span></h3>
  </div>
  <div class="todo-form">
    <input
      class="todo-input"
      placeholder="¿Qué queda pendiente?"
      bind:value={todoInput}
      onkeydown={(e) => e.key === 'Enter' && addTodo()}
      aria-label="Nuevo pendiente"
    />
    <button class="btn btn-primary" onclick={addTodo} disabled={!todoInput.trim() || saving} title="Agregar pendiente">+</button>
  </div>
  {#if todos.length === 0}
    <div class="todos-empty">Agrega tus pendientes aquí</div>
  {:else}
    <ul class="todos-list">
      {#each pending as todo (todo.id)}
        <li class="todo-item">
          <button
            class="todo-check"
            type="button"
            aria-label={`Marcar ${todo.name} como completada`}
            onclick={() => toggleTodo(todo)}
          >✓</button>
          <span class="todo-name">{todo.name}</span>
          <button class="small-btn btn-ghost" onclick={() => deleteTodo(todo.id!)} title="Eliminar">✕</button>
        </li>
      {/each}
      {#each doneTodos as todo (todo.id)}
        <li class="todo-item done">
          <button
            class="todo-check checked"
            type="button"
            aria-label={`Marcar ${todo.name} como pendiente`}
            onclick={() => toggleTodo(todo)}
          >✓</button>
          <span class="todo-name">{todo.name}</span>
          <button class="small-btn btn-ghost" onclick={() => deleteTodo(todo.id!)} title="Eliminar">✕</button>
        </li>
      {/each}
    </ul>
  {/if}
</div>

<style>
  .work-todos {
    padding: 14px;
    margin-bottom: 16px;
  }

  .work-todos-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 10px;
  }

  .wt-title {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    margin: 0;
    font-family: var(--font-display);
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .todos-count {
    font-size: 11px;
    color: var(--bg3);
    background: var(--accent-green);
    border-radius: 999px;
    padding: 1px 7px;
    font-family: var(--font-mono);
  }

  .todo-form {
    display: flex;
    gap: 8px;
    margin-bottom: 10px;
  }

  .todo-input {
    flex: 1;
    padding: 8px 12px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--text);
    font-size: 13px;
  }

  .todos-empty {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 14px;
  }

  .todos-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .todo-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 10px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius);
  }

  .todo-item.done { opacity: 0.55; }

  .todo-item.done .todo-name {
    text-decoration: line-through;
    color: var(--text3);
  }

  .todo-check {
    width: 22px;
    height: 22px;
    flex-shrink: 0;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    background: var(--bg3);
    border: 1px solid var(--border);
    border-radius: 6px;
    color: var(--text3);
    font-size: 11px;
    cursor: pointer;
    transition: all var(--transition);
  }

  .todo-check:hover { border-color: var(--accent-green); color: var(--text2); }

  .todo-check.checked {
    background: var(--accent-green);
    border-color: var(--accent-green);
    color: var(--bg3);
    font-weight: 700;
  }

  .todo-name {
    flex: 1;
    font-size: 13px;
    color: var(--text);
    min-width: 0;
    word-break: break-word;
  }

  .todo-item .small-btn {
    flex-shrink: 0;
  }
</style>
