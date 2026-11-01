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
      await awardXP(userId, 'selfcare', 'reward_earned', XP_VALUES.reward_earned, undefined, rewardForm.achievement_name);
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
      <article class="reward-card item-card card">
        <div class="reward-info">
          <div class="reward-heading item-card-header">
          <span class="reward-icon" aria-hidden="true">🎁</span>
          <h3 class="reward-name">{r.achievement_name}</h3>
          </div>
          <p class="reward-given">{r.reward_given}</p>
        </div>
        <div class="item-card-footer">
          <time class="reward-date" datetime={r.date_awarded}>
            {new Date(r.date_awarded).toLocaleDateString('es-ES')}
          </time>
          <div class="item-card-actions">
            <button
              class="icon-action"
              type="button"
              aria-label="Editar recompensa"
              onclick={() => editReward(r)}>🖋</button
            >
            <button
              class="icon-action danger"
              type="button"
              aria-label="Eliminar recompensa"
              onclick={() => deleteReward(r.id!)}>✕</button
            >
          </div>
        </div>
      </article>
    {/each}
    {#if rewards.length === 0}
      <div class="empty-state card" style="grid-column:1/-1">Celebra tus logros con recompensas 🎁</div>
    {/if}
  </div>
</div>

{#if showRewardForm}
  <div class="modal-backdrop" role="presentation" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showRewardForm = false
        }
      }} onkeydown={(e) => e.key === 'Escape' && (showRewardForm = false)}>
    <div class="modal" role="document">
      <h3>{editingRewardId ? 'Editar recompensa' : 'Nueva recompensa'}</h3>
      <div class="form-group"><label for="reward-achievement">Logro</label><input id="reward-achievement" bind:value={rewardForm.achievement_name} placeholder="¿Qué lograste?" /></div>
      <div class="form-group"><label for="reward-given">Recompensa</label><input id="reward-given" bind:value={rewardForm.reward_given} placeholder="¿Cómo te premiaste?" /></div>
      <div class="form-group"><label for="reward-date">Fecha</label><input id="reward-date" type="date" bind:value={rewardForm.date_awarded} /></div>
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
    gap: 12px;
  }

  .reward-heading {
    justify-content: flex-start;
    gap: 10px;
  }

  .reward-icon {
    font-size: 22px;
    line-height: 1.2;
  }

  .reward-info { flex: 1; min-width: 0; }

  .reward-name {
    flex: 1;
    min-width: 0;
    margin: 0;
    font-size: 15px;
    font-weight: 600;
    color: var(--text);
    line-height: 1.35;
    overflow-wrap: anywhere;
  }

  .reward-given {
    font-size: 13px;
    color: var(--text2);
    margin: 8px 0 0 32px;
    overflow-wrap: anywhere;
  }

  .reward-date {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

</style>
