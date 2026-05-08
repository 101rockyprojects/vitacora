<script lang="ts">
  import type { SuccessExperience } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';

  interface Props {
    userId: string;
    successes?: SuccessExperience[];
    onRefresh?: () => void;
  }

  let { userId, successes = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showSuccessForm = $state(false);
  let successForm = $state<SuccessExperience>({ goal_description: '', done: false });
  let editingSuccessId = $state<string | null>(null);
  let saving = $state(false);

  const editingSuccess = $derived(editingSuccessId ? successes.find(s => s.id === editingSuccessId) ?? null : null);

  $effect(() => {
    if (editingSuccess?.done) {
      successForm.done = true;
    }
  });

  async function saveSuccess() {
    saving = true;
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
      if (wantsDone && !wasDone) await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, editingSuccessId);
    } else {
      const { data } = await repo.successes.insert({
        ...successForm,
        done: wantsDone,
        completed_date: wantsDone ? new Date().toISOString() : null
      });
      if (wantsDone && data) await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, data.id);
    }
    successForm = { goal_description: '', done: false };
    editingSuccessId = null;
    showSuccessForm = false;
    const { data } = await repo.successes.list();
    successes = data || [];
    saving = false;
  }

  async function toggleSuccess(s: SuccessExperience) {
    if (s.done) return;
    const ok = confirm('¿Marcar como completado? Esto no se podrá deshacer.');
    if (!ok) return;
    await repo.successes.update(s.id!, { done: true, completed_date: new Date().toISOString() });
    await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, s.id);
    const { data } = await repo.successes.list();
    successes = data || [];
  }

  function openNewSuccess() {
    editingSuccessId = null;
    successForm = { goal_description: '', done: false };
    showSuccessForm = true;
  }

  function openEditSuccess(s: SuccessExperience) {
    editingSuccessId = s.id || null;
    successForm = { ...s, done: !!s.done };
    showSuccessForm = true;
  }

  function closeSuccessForm() {
    showSuccessForm = false;
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
      <div class="success-card card" class:done={s.done}>
        <button class="success-check" class:checked={s.done} onclick={() => toggleSuccess(s)} disabled={s.done} aria-label="Marcar como completado">
          {s.done ? '✓' : ''}
        </button>
        <div class="success-info">
          <div class="success-goal">{s.goal_description}</div>
          {#if s.reflection}
            <div class="success-reflection">"{s.reflection}"</div>
          {/if}
          {#if s.completed_date}
            <div class="success-date">Completado: {new Date(s.completed_date).toLocaleDateString('es-ES')}</div>
          {/if}
        </div>
        <button class="small-btn btn-ghost" onclick={() => openEditSuccess(s)}>🖋</button>
        <button class="small-btn btn-ghost" onclick={() => deleteSuccess(s.id!)}>✕</button>
      </div>
    {/each}
    {#if successes.length === 0}
      <div class="empty-state card">Registra tus experiencias de éxito 🏆</div>
    {/if}
  </div>
</div>

{#if showSuccessForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          closeSuccessForm()
        }
      }}>
    <div class="modal">
      <h3>{editingSuccessId ? 'Editar meta / logro' : 'Nueva meta / logro'}</h3>
      <div class="form-group"><label>Descripción de la meta</label><textarea bind:value={successForm.goal_description} rows="2" placeholder="¿Qué quieres lograr?"></textarea></div>
      <div class="form-group"><label>Reflexión</label><textarea bind:value={successForm.reflection} rows="8" placeholder="¿Qué aprendiste?"></textarea></div>
      <div class="form-group" style="display:flex;align-items:center;gap:8px;">
        <input type="checkbox" bind:checked={successForm.done} id="done-check" style="width:auto;" disabled={!!editingSuccess?.done} />
        <label for="done-check" style="text-transform:none;font-size:14px;color:var(--text);">Marcar como completada</label>
      </div>
      {#if editingSuccess?.done}
        <div style="color:var(--text3);font-size:12px;font-family:var(--font-mono);margin-top:-15px;">
          Ya esta completada y no se puede desmarcar.
        </div>
      {/if}
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={closeSuccessForm}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveSuccess} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .success-list { display: flex; flex-direction: column; gap: 12px; }

  .success-card {
    display: flex;
    gap: 12px;
    align-items: flex-start;
  }

  .success-card.done { border-color: var(--accent-yellow); }

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

  .success-check.checked {
    background: var(--accent-green);
    border-color: var(--accent-green);
    color: var(--bg-primary);
  }

  .success-info { flex: 1; min-width: 0; }

  .success-goal {
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
  }

  .success-reflection {
    font-size: 12px;
    color: var(--text2);
    font-style: italic;
    margin-top: 4px;
  }

  .success-date {
    font-size: 11px;
    color: var(--accent-yellow);
    font-family: var(--font-mono);
    margin-top: 6px;
  }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: center;
    padding: 24px 0;
  }
</style>