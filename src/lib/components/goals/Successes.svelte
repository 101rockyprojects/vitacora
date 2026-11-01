<script lang="ts">
  import type { SuccessExperience } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import CardPreviewModal from '$lib/components/CardPreviewModal.svelte';

  interface Props {
    userId: string;
    successes?: SuccessExperience[];
    onRefresh?: () => void;
  }

  let { userId, successes = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showSuccessModal = $state(false);
  let successModalMode = $state<'view' | 'edit'>('view');
  let previewSuccessId = $state<string | null>(null);
  let successForm = $state<SuccessExperience>({ goal_description: '', done: false });
  let editingSuccessId = $state<string | null>(null);
  let saving = $state(false);

  const editingSuccess = $derived(editingSuccessId ? successes.find(s => s.id === editingSuccessId) ?? null : null);
  const previewSuccess = $derived(successes.find(s => s.id === previewSuccessId) ?? null);

  $effect(() => {
    if (editingSuccess?.done) {
      successForm.done = true;
    }
  });

  async function saveSuccess() {
    saving = true;
    let savedId = editingSuccessId;
    const wasDone = editingSuccess?.done ?? false;
    const wantsDone = !!successForm.done;

    if (wantsDone && !wasDone) {
      const ok = confirm('¿Marcar como completado? Esto no se podrá deshacer.');
      if (!ok) { saving = false; return; }
    }

    if (editingSuccessId) {
      await repo.successes.update(editingSuccessId, {
        goal_description: successForm.goal_description,
        reflection: successForm.reflection,
        done: wasDone ? true : wantsDone,
        completed_date: wasDone ? editingSuccess?.completed_date ?? new Date().toISOString() : (wantsDone ? new Date().toISOString() : null)
      });
      if (wantsDone && !wasDone) await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, editingSuccessId, successForm.goal_description);
    } else {
      const { data } = await repo.successes.insert({
        ...successForm,
        done: wantsDone,
        completed_date: wantsDone ? new Date().toISOString() : null
      });
      savedId = data?.id ?? null;
      if (wantsDone && data) await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, data.id, successForm.goal_description);
    }
    const { data } = await repo.successes.list();
    successes = data || [];
    saving = false;
    if (savedId) {
      previewSuccessId = savedId;
      successModalMode = 'view';
      successForm = { goal_description: '', done: false };
      editingSuccessId = null;
    }
  }

  async function toggleSuccess(s: SuccessExperience) {
    if (s.done) return;
    const ok = confirm('¿Marcar como completado? Esto no se podrá deshacer.');
    if (!ok) return;
    await repo.successes.update(s.id!, { done: true, completed_date: new Date().toISOString() });
    await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, s.id, s.goal_description);
    const { data } = await repo.successes.list();
    successes = data || [];
  }

  function openNewSuccess() {
    previewSuccessId = null;
    editingSuccessId = null;
    successForm = { goal_description: '', done: false };
    successModalMode = 'edit';
    showSuccessModal = true;
  }

  function openEditSuccess(s: SuccessExperience) {
    previewSuccessId = s.id || null;
    editingSuccessId = s.id || null;
    successForm = { ...s, done: !!s.done };
    successModalMode = 'edit';
    showSuccessModal = true;
  }

  function openSuccessPreview(s: SuccessExperience) {
    previewSuccessId = s.id || null;
    successModalMode = 'view';
    showSuccessModal = true;
  }

  function cancelSuccessEdit() {
    editingSuccessId = null;
    successForm = { goal_description: '', done: false };
  }

  function closeSuccessModal() {
    showSuccessModal = false;
    previewSuccessId = null;
    editingSuccessId = null;
    successForm = { goal_description: '', done: false };
  }

  async function deleteSuccess(id: string) {
    if (!confirm('¿Eliminar logro?')) return;
    await repo.successes.remove(id);
    const { data } = await repo.successes.list();
    successes = data || [];
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={openNewSuccess}>+ Nueva meta</button>
  </div>
  <div class="success-list">
    {#each successes as s}
      <article class="success-card item-card card" class:done={s.done}>
        <div class="success-main">
          <button
            class="success-check"
            class:checked={s.done}
            type="button"
            onclick={() => toggleSuccess(s)}
            disabled={s.done}
            aria-label={s.done ? "Completado" : "Marcar como completado"}
          >
            {s.done ? '✓' : ''}
          </button>
          <button
            class="success-preview-trigger"
            type="button"
            aria-label="Ver detalles de {s.goal_description}"
            onclick={() => openSuccessPreview(s)}
          >
            <h3 class="success-goal">{s.goal_description}</h3>
            {#if s.reflection}
              <p class="success-reflection">“{s.reflection}”</p>
            {/if}
          </button>
        </div>
        <div class="item-card-footer">
          {#if s.completed_date}
            <time class="success-date" datetime={s.completed_date}>
              Completado: {new Date(s.completed_date).toLocaleDateString('es-ES')}
            </time>
          {:else}
            <span></span>
          {/if}
          <div class="item-card-actions">
            <button
              class="icon-action"
              type="button"
              aria-label="Editar meta o logro"
              onclick={() => openEditSuccess(s)}>🖋</button
            >
            <button
              class="icon-action danger"
              type="button"
              aria-label="Eliminar meta o logro"
              onclick={() => deleteSuccess(s.id!)}>✕</button
            >
          </div>
        </div>
      </article>
    {/each}
    {#if successes.length === 0}
      <div class="empty-state card">Registra tus experiencias de éxito 🏆</div>
    {/if}
  </div>
</div>

{#if showSuccessModal}
  <CardPreviewModal
    title={successModalMode === 'view'
      ? previewSuccess?.goal_description ?? 'Meta o logro'
      : editingSuccessId
        ? 'Editar meta / logro'
        : 'Nueva meta / logro'}
    bind:mode={successModalMode}
    viewAvailable={!!previewSuccess}
    saving={saving}
    onclose={closeSuccessModal}
    onedit={() => previewSuccess && openEditSuccess(previewSuccess)}
    oncancel={cancelSuccessEdit}
    onsave={saveSuccess}
  >
    {#snippet view()}
      {#if previewSuccess}
        <div class="success-preview">
          {#if previewSuccess.reflection}
            <section>
              <h3>Reflexión</h3>
              <p class="success-preview-reflection">“{previewSuccess.reflection}”</p>
            </section>
          {/if}
          {#if previewSuccess.completed_date}
            <time class="success-date" datetime={previewSuccess.completed_date}>
              Completado: {new Date(previewSuccess.completed_date).toLocaleDateString('es-ES')}
            </time>
          {/if}
          {#if previewSuccess.done}
            <span class="success-completed-badge">✓ Completado</span>
          {/if}
        </div>
      {/if}
    {/snippet}

    {#snippet form()}
      <div class="form-group">
        <label for="success-goal">Descripción de la meta</label>
        <textarea
          id="success-goal"
          bind:value={successForm.goal_description}
          rows="2"
          placeholder="¿Qué quieres lograr?"
        ></textarea>
      </div>
      <div class="form-group">
        <label for="success-reflection">Reflexión</label>
        <textarea
          id="success-reflection"
          bind:value={successForm.reflection}
          rows="8"
          placeholder="¿Qué aprendiste?"
        ></textarea>
      </div>
      <div class="success-done-field">
        <input
          type="checkbox"
          bind:checked={successForm.done}
          id="done-check"
          disabled={!!editingSuccess?.done}
        />
        <label for="done-check">Marcar como completada</label>
      </div>
      {#if editingSuccess?.done}
        <p class="success-done-help">
          Ya está completada y no se puede desmarcar.
        </p>
      {/if}
    {/snippet}
  </CardPreviewModal>
{/if}

<style>
  .success-list { display: flex; flex-direction: column; gap: 12px; }

  .success-card {
    gap: 12px;
  }

  .success-card.done {
    border-color: var(--accent-yellow);
  }

  .success-main {
    display: flex;
    align-items: flex-start;
    gap: 12px;
  }

  .success-preview-trigger {
    flex: 1;
    min-width: 0;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    text-align: left;
    cursor: pointer;
  }

  .success-preview-trigger:focus-visible {
    outline: 2px solid var(--accent);
    outline-offset: 4px;
    border-radius: var(--radius-sm);
  }

  .success-check {
    width: 24px;
    height: 24px;
    border-radius: 6px;
    border: 2px solid var(--border);
    background: transparent;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    color: var(--accent-green);
    flex-shrink: 0;
    transition: all var(--transition);
  }

  .success-check:hover:not(:disabled) { border-color: var(--accent-green); }

  .success-check.checked:not(:disabled) {
    background: transparent;
    border-color: var(--accent-green);
    color: var(--accent-green);
  }
  .success-check.checked:disabled {
    background: transparent;
    border-color: var(--text3);
    color: var(--accent-yellow);
  }

  .success-goal {
    margin: 0;
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
  }

  .success-reflection {
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    overflow: hidden;
    font-size: 12px;
    color: var(--text2);
    font-style: italic;
    margin-top: 4px;
  }

  .success-date {
    font-size: 11px;
    color: var(--accent-yellow);
    font-family: var(--font-mono);
  }

  .success-preview {
    display: flex;
    flex-direction: column;
    gap: 14px;
  }

  .success-preview h3 {
    font-size: 14px;
  }

  .success-preview-reflection {
    white-space: pre-wrap;
  }

  .success-completed-badge {
    align-self: flex-start;
    padding: 3px 8px;
    border-radius: 999px;
    background: var(--accent-yellow);
    color: var(--bg);
    font-size: 11px;
    font-weight: 700;
  }

  .success-done-field {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .success-done-field input {
    width: auto;
  }

  .success-done-field label {
    color: var(--text);
    font-size: 14px;
  }

  .success-done-help {
    margin-top: -10px;
    color: var(--text3);
    font-family: var(--font-mono);
    font-size: 12px;
  }

  @media (max-width: 480px) {
    .success-main {
      gap: 8px;
    }
  }
</style>
