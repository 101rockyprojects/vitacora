<script lang="ts">
  import { tick } from 'svelte';

  let { 
    open = $bindable(false),
    title = '',
    onclose = () => {},
    children
  } = $props();

  let dialogRef: HTMLDialogElement | null = $state(null);

  $effect(() => {
    if (open && dialogRef) {
      dialogRef.showModal();
    } else if (!open && dialogRef?.open) {
      dialogRef.close();
    }
  });

  function handleBackdropClick(e: MouseEvent) {
    if (e.target === dialogRef) {
      closeModal();
    }
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      e.preventDefault();
      closeModal();
    }
  }

  function closeModal() {
    open = false;
    onclose();
  }

  function handleSubmit(e: Event) {
    e.preventDefault();
  }
</script>

<dialog
  bind:this={dialogRef}
  class="modal-dialog"
  onclick={handleBackdropClick}
  onkeydown={handleKeydown}
  aria-modal="true"
  aria-labelledby={title ? `modal-title-${title.toLowerCase().replace(/\s+/g, '-')}` : undefined}
>
  <div class="modal-content">
    {#if title}
      <header class="modal-header">
        <h2 id={`modal-title-${title.toLowerCase().replace(/\s+/g, '-')}`}>{title}</h2>
        <button type="button" class="modal-close" onclick={closeModal} aria-label="Cerrar">
          <span aria-hidden="true">&times;</span>
        </button>
      </header>
    {/if}
    {@render children()}
  </div>
</dialog>

<style>
  .modal-dialog {
    background: var(--bg-primary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: 0;
    max-width: 500px;
    width: 90vw;
    max-height: 85vh;
    overflow-y: auto;
    box-shadow: var(--shadow-lg);
  }

  .modal-dialog::backdrop {
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(2px);
  }

  .modal-content {
    padding: 20px;
  }

  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    padding-bottom: 12px;
    border-bottom: 1px solid var(--border-color);
  }

  .modal-header h2 {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .modal-close {
    background: none;
    border: none;
    font-size: 24px;
    line-height: 1;
    color: var(--text-secondary);
    cursor: pointer;
    padding: 4px 8px;
    border-radius: 4px;
    transition: all var(--transition);
  }

  .modal-close:hover {
    background: var(--bg-secondary);
    color: var(--text-primary);
  }
</style>