<script lang="ts">
  import type { LearningItem } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';

  interface Props {
    userId: string;
    learning?: LearningItem[];
    onRefresh?: () => void;
  }

  let { userId, learning = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showLearnForm = $state(false);
  let editingLearnId = $state<string | null>(null);
  let learnForm = $state<LearningItem>({ topic: '' });
  let saving = $state(false);

  async function saveLearn() {
    saving = true;
    if (editingLearnId) {
      await repo.learning.update(editingLearnId, learnForm);
    } else {
      await repo.learning.insert(learnForm);
      await awardXP(userId, 'education', 'learning_added', XP_VALUES.learning_added);
    }
    learnForm = { topic: '' };
    editingLearnId = null;
    showLearnForm = false;
    const { data } = await repo.learning.list();
    learning = data || [];
    saving = false;
  }

  async function deleteLearn(id: string) {
    if (!confirm('¿Eliminar tema?')) return;
    await repo.learning.remove(id);
    const { data } = await repo.learning.list();
    learning = data || [];
  }

  function editLearn(item: LearningItem) {
    editingLearnId = item.id || null;
    learnForm = { ...item };
    showLearnForm = true;
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { editingLearnId = null; learnForm = { topic: '' }; showLearnForm = true; }}>+ Agregar tema</button>
  </div>
  <div class="learn-list">
    {#each learning as item}
      <div class="learn-card card responsive-card">
        {#if item.image_url}
          <div class="rc-image">
            <img src={item.image_url} alt="screenshot" />
          </div>
        {/if}
        <div class="rc-content">
          <div class="learn-main">
            <div class="learn-topic">{item.topic}</div>
            {#if item.resource_link}
              <a href={item.resource_link} target="_blank" class="learn-link">🔗 Recurso</a>
            {/if}
            {#if item.notes}
              <div class="learn-notes">{item.notes}</div>
            {/if}
          </div>
          <div class="rc-actions card-actions-inline">
            <button class="small-btn btn-secondary" onclick={() => editLearn(item)}>🖋</button>
            <button class="small-btn btn-ghost" onclick={() => deleteLearn(item.id!)}>✕</button>
          </div>
        </div>
      </div>
    {/each}
    {#if learning.length === 0}
      <div class="empty-state card">Empieza a registrar lo que aprendes 🧠</div>
    {/if}
  </div>
</div>

{#if showLearnForm}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) showLearnForm = false; }}
    onkeydown={(e) => { if (e.key === 'Escape') showLearnForm = false; }}
    role="presentation"
  >
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="learn-form-title">
      <h3 id="learn-form-title">{editingLearnId ? 'Editar tema de aprendizaje' : 'Nuevo tema de aprendizaje'}</h3>
      <form onsubmit={(e) => { e.preventDefault(); saveLearn(); }}>
        <div class="form-group">
          <label for="learn-topic">Tema</label>
          <input id="learn-topic" bind:value={learnForm.topic} placeholder="Ej: Diseño de APIs REST" />
        </div>
        <div class="form-group">
          <label for="learn-resource">Enlace de recurso</label>
          <input id="learn-resource" type="url" bind:value={learnForm.resource_link} placeholder="https://..." />
        </div>
        <div class="form-group">
          <label for="learn-image">URL imagen/captura</label>
          <input id="learn-image" type="url" bind:value={learnForm.image_url} placeholder="https://..." />
        </div>
        <div class="form-group">
          <label for="learn-notes">Notas</label>
          <textarea id="learn-notes" bind:value={learnForm.notes} rows="3"></textarea>
        </div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick={() => showLearnForm = false}>Cancelar</button>
          <button type="submit" class="btn btn-primary" disabled={saving}>{saving ? '...' : 'Guardar'}</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .learn-list { display: flex; flex-direction: column; gap: 12px; }

  .learn-topic {
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
  }

  .learn-link {
    display: inline-block;
    font-size: 12px;
    color: var(--accent-green);
    margin-top: 4px;
  }

  .learn-notes {
    font-size: 12px;
    color: var(--text2);
    margin-top: 6px;
    line-height: 1.5;
  }
</style>