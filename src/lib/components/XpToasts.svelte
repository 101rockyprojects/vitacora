<script lang="ts">
  import { flip } from 'svelte/animate';
  import { fade, fly } from 'svelte/transition';
  import { TOAST_DURATION_MS, xpToastStore } from '$lib/stores/xpToast.svelte';

  const toasts = $derived(xpToastStore.toasts);
</script>

<div class="xp-toasts" aria-live="polite">
  {#each toasts as toast (toast.id)}
    <button
      class="xp-toast"
      type="button"
      in:fly={{ y: 16, duration: 250 }}
      out:fade={{ duration: 200 }}
      animate:flip={{ duration: 200 }}
      onclick={() => xpToastStore.dismiss(toast.id)}
    >
      <span class="xp-toast-icon" aria-hidden="true">{toast.icon}</span>
      <span class="xp-toast-label">{toast.label}</span>
      {#if toast.xp !== undefined}
        <span class="xp-toast-amount">+{toast.xp} XP</span>
      {/if}
      <span
        class="xp-toast-timer"
        style="animation-duration: {TOAST_DURATION_MS}ms"
        aria-hidden="true"
      ></span>
    </button>
  {/each}
</div>

<style>
  .xp-toasts {
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 50;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 10px;
    pointer-events: none;
  }

  .xp-toast {
    position: relative;
    display: flex;
    align-items: center;
    gap: 10px;
    min-width: 220px;
    max-width: 320px;
    padding: 12px 16px 14px;
    background: var(--bg2);
    border: 1px solid var(--accent);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    overflow: hidden;
    cursor: pointer;
    pointer-events: auto;
    text-align: left;
  }

  .xp-toast-icon {
    font-size: 18px;
    line-height: 1;
    flex-shrink: 0;
  }

  .xp-toast-label {
    flex: 1;
    min-width: 0;
    font-size: 13px;
    color: var(--text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .xp-toast-amount {
    font-family: var(--font-mono);
    font-size: 13px;
    font-weight: 700;
    color: var(--accent);
    white-space: nowrap;
  }

  .xp-toast-timer {
    position: absolute;
    left: 0;
    bottom: 0;
    width: 100%;
    height: 2px;
    background: var(--accent);
    transform-origin: left center;
    animation-name: xp-toast-shrink;
    animation-timing-function: linear;
    animation-fill-mode: forwards;
  }

  @keyframes xp-toast-shrink {
    from {
      transform: scaleX(1);
    }
    to {
      transform: scaleX(0);
    }
  }

  @media (max-width: 640px) {
    .xp-toasts {
      left: 16px;
      right: 16px;
      bottom: 16px;
      align-items: center;
    }

    .xp-toast {
      min-width: 0;
      max-width: 100%;
    }

    .xp-toast-label {
      white-space: normal;
      overflow: visible;
      text-overflow: clip;
    }
  }
</style>
