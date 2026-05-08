<script lang="ts">
  import type { Reward } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';

  interface Props {
    userId: string;
    rewards?: Reward[];
    onRefresh?: () => void;
  }

  let { userId, rewards = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showRewardForm = $state(false);
  let editingRewardId = $state<string | null>(null);
  let rewardForm = $state<Reward>({ achievement_name: '', reward_given: '', date_awarded: new Date().toISOString().split('T')[0] });
  let saving = $state(false);

  async function saveReward() {
    saving = true;
    if (editingRewardId) {
      await repo.rewards.update(editingRewardId, rewardForm);
    } else {
      await repo.rewards.insert(rewardForm);
      await awardXP(userId, 'selfcare', 'reward_earned', XP_VALUES.reward_earned);
    }
    rewardForm = { achievement_name: '', reward_given: '', date_awarded: new Date().toISOString().split('T')[0] };
    editingRewardId = null;
    showRewardForm = false;
    const { data } = await repo.rewards.list();
    rewards = data || [];
    saving = false;
  }

  async function deleteReward(id: string) {
    if (!confirm('¿Eliminar recompensa?')) return;
    await repo.rewards.remove(id);
    const { data } = await repo.rewards.list();
    rewards = data || [];
  }

  function editReward(item: Reward) {
    editingRewardId = item.id || null;
    rewardForm = { ...item };
    showRewardForm = true;
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { editingRewardId = null; rewardForm = { achievement_name: '', reward_given: '', date_awarded: new Date().toISOString().split('T')[0] }; showRewardForm = true; }}>+ Agregar recompensa</button>
  </div>
  <div class="rewards-grid">
    {#each rewards as r}
      <div class="reward-card card">
        <div class="reward-icon">🎁</div>
        <div class="reward-info">
          <div class="reward-name">{r.achievement_name}</div>
          <div class="reward-given">{r.reward_given}</div>
          <div class="reward-date">{new Date(r.date_awarded).toLocaleDateString('es-ES')}</div>
        </div>
        <div class="card-actions-inline">
          <button class="small-btn btn-secondary" onclick={() => editReward(r)}>🖋</button>
          <button class="small-btn btn-ghost" onclick={() => deleteReward(r.id!)}>✕</button>
        </div>
      </div>
    {/each}
    {#if rewards.length === 0}
      <div class="empty-state card" style="grid-column:1/-1">Celebra tus logros con recompensas 🎁</div>
    {/if}
  </div>
</div>

{#if showRewardForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showRewardForm = false
        }
      }}>
    <div class="modal">
      <h3>{editingRewardId ? 'Editar recompensa' : 'Nueva recompensa'}</h3>
      <div class="form-group"><label>Logro</label><input bind:value={rewardForm.achievement_name} placeholder="¿Qué lograste?" /></div>
      <div class="form-group"><label>Recompensa</label><input bind:value={rewardForm.reward_given} placeholder="¿Cómo te premiaste?" /></div>
      <div class="form-group"><label>Fecha</label><input type="date" bind:value={rewardForm.date_awarded} /></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showRewardForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveReward} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .rewards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 16px;
  }

  .reward-card {
    display: flex;
    gap: 12px;
    align-items: flex-start;
  }

  .reward-icon { font-size: 24px; }

  .reward-info { flex: 1; min-width: 0; }

  .reward-name {
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
  }

  .reward-given {
    font-size: 12px;
    color: var(--text2);
    margin-top: 2px;
  }

  .reward-date {
    font-size: 11px;
    color: var(--text3);
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