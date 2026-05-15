<script lang="ts">
  interface Props {
    title?: string;
    msg?: string;
  }

  let { title = '', msg = '' }: Props = $props();
</script>

{#if title && msg}
  <div class="oops-container">
    <h2 class="oops-title">{title}</h2>
    <div class="oops-message">
      <p>{msg}</p>
    </div>
  </div>
{/if}

<style>
  .oops-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 24px;
    background: var(--bg2);
    border-radius: var(--radius-lg);
    border: 1px solid var(--border);
  }

  .oops-title {
    text-align: center;
    font-size: 20px;
    font-weight: 800;
    color: var(--accent-red);
    margin-bottom: 8px;
  }

  .oops-message {
    text-align: center;
    font-size: 14px;
    color: var(--text2);
  }
</style>