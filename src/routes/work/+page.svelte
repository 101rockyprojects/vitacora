<script lang="ts">
  import Kanban from '$lib/components/projects/Kanban.svelte';
  import { createRepository } from '$lib/services/repository';
  import type { Task } from '$lib/types';
  import { page } from '$app/state';

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  
  let tasks = $state<Task[]>([]);
  let initialized = $state(false);
  let loading = $state(true);

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
</script>

<div class="fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Trabajo</h2>
      <div class="section-subtitle">Organiza tu flujo de trabajo</div>
    </div>
  </div>
  
  {#if loading}
  <div class="loading">Cargando...</div>
  {:else}
    <Kanban 
      {userId} 
      tasks={tasks} 
      onTasksChange={handleTasksChange}
      workFilterOnly={true}
    />
  {/if}
</div>

<style>
  .loading {
    text-align: center;
    padding: 40px;
    color: var(--text3);
  }
</style>