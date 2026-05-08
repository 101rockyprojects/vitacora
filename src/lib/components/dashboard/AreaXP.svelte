<script lang="ts">
  import { AREAS } from '$lib/utils/xp';

  interface Props {
    areaXP: Record<string, number>;
  }

  let { areaXP = $bindable({}) }: Props = $props();

  import { levelFromXp } from '$lib/utils/xp';
</script>

<div class="card areaxp-card">
  <h3 class="card-title">Áreas de vida</h3>
  <div class="area-bars">
    {#each AREAS as area}
      {@const aXP = areaXP[area.key] || 0}
      {@const lvl = levelFromXp(aXP)}
      <div class="area-bar-item">
        <div class="area-bar-header">
          <span>{area.icon} {area.label}</span>
          <span class="area-bar-lv" style="color:{area.color}">Lv.{lvl.level}</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill"
            style="width:{(lvl.progress/lvl.nextLevelXp)*100}%;background:{area.color};">
          </div>
        </div>
        <div class="area-bar-xp">{aXP} XP</div>
      </div>
    {/each}
  </div>
</div>

<style>
  .card-title {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-family: var(--font-display);
  }

  .area-bars { display: flex; flex-direction: column; gap: 12px; }

  .area-bar-header {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    color: var(--text2);
    margin-bottom: 5px;
  }

  .area-bar-lv { font-family: var(--font-mono); font-size: 11px; font-weight: 700; }

  .area-bar-xp {
    font-size: 10px;
    color: var(--text3);
    font-family: var(--font-mono);
    margin-top: 3px;
  }
</style>