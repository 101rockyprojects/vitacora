<script lang="ts">
  let { visible = false, message = '' }: { visible?: boolean; message?: string } = $props();
</script>

{#if visible}
  <div class="toast" role="status" aria-live="polite">
    {message}
  </div>
{/if}

<style>
  .toast {
    position: fixed;
    right: 20px;
    bottom: 20px;
    z-index: 120;
    background: #172327;
    color: #e9f6ef;
    border: 1px solid rgba(168, 230, 207, 0.35);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.25);
    border-radius: 10px;
    padding: 10px 14px;
    font-size: 13px;
    line-height: 1.4;
    max-width: min(92vw, 420px);
  }
</style>
