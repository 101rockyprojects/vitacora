<script lang="ts">
  export let title = '';
  export let msg = '';
</script>

{#if title && msg}
  <div class="oops">
    <h2 class="oops-title">{title}</h2>
    <div class="oops-message">{msg}</div>
  </div>
{/if}

<style>
  .oops {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    gap: 10px;
    padding: 18px;
    border-radius: var(--radius-lg);
    border: 1px dashed var(--border);
    background: rgba(0, 0, 0, 0.12);
  }

  .oops-title {
    text-align: center;
    font-size: 18px;
    line-height: 1.2;
    color: var(--accent-red);
    font-weight: 900;
    margin: 0;
  }

  .oops-message {
    text-align: center;
    color: var(--text2);
    font-size: 13px;
    line-height: 1.4;
    margin: 0;
  }
</style>

