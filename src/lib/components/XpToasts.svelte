<script lang="ts">
  import { xpToastStore } from '$lib/stores/xpToast.svelte';

  const toasts = $derived(xpToastStore.toasts);
</script>

{#if toasts.length > 0}
  <div class="xp-toasts" aria-live="polite">
    {#each toasts as toast (toast.id)}
      <button
        class="xp-toast"
        type="button"
        onclick={() => xpToastStore.dismiss(toast.id)}
      >
        <span class="xp-toast-amount">+{toast.amount} XP</span>
        <span class="xp-toast-message">{toast.message}</span>
      </button>
    {/each}
  </div>
{/if}

<style>
  .xp-toasts {
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 50;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 8px;
    pointer-events: none;
  }

  .xp-toast {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 16px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-left: 3px solid var(--accent-yellow);
    border-radius: 10px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.4);
    cursor: pointer;
    pointer-events: auto;
    animation: xp-toast-in 0.25s ease;
  }

  .xp-toast-amount {
    font-family: var(--font-mono);
    font-size: 13px;
    font-weight: 700;
    color: var(--accent-yellow);
    white-space: nowrap;
  }

  .xp-toast-message {
    font-size: 13px;
    color: var(--text2);
    max-width: 240px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  @keyframes xp-toast-in {
    from {
      opacity: 0;
      transform: translateY(12px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @media (max-width: 640px) {
    .xp-toasts {
      bottom: 16px;
      right: 16px;
      left: 16px;
      align-items: stretch;
    }

    .xp-toast-message {
      max-width: none;
    }
  }
</style>
