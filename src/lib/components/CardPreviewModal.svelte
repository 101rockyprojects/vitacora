<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    title: string;
    mode?: "view" | "edit";
    viewAvailable?: boolean;
    saving?: boolean;
    view?: Snippet;
    form: Snippet;
    onclose: () => void;
    onedit?: () => void;
    oncancel?: () => void;
    onsave: () => void | Promise<void>;
  }

  let {
    title,
    mode = $bindable("view"),
    viewAvailable = false,
    saving = false,
    view,
    form,
    onclose,
    onedit,
    oncancel,
    onsave,
  }: Props = $props();

  let dialogRef: HTMLDialogElement | null = $state(null);

  const titleId = $derived(
    `card-preview-${title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`,
  );

  $effect(() => {
    if (dialogRef && !dialogRef.open) dialogRef.showModal();
  });

  function handleBackdropClick(event: MouseEvent) {
    if (event.target === dialogRef) onclose();
  }

  function handleCancel(event: Event) {
    event.preventDefault();
    onclose();
  }

  function edit() {
    onedit?.();
    mode = "edit";
  }

  function cancelEdit() {
    if (!viewAvailable) {
      onclose();
      return;
    }
    oncancel?.();
    mode = "view";
  }
</script>

<dialog
  bind:this={dialogRef}
  class="modal card-preview-modal"
  aria-labelledby={titleId}
  onclick={handleBackdropClick}
  oncancel={handleCancel}
>
  <header class="card-preview-header">
    <h2 id={titleId}>{title}</h2>
    <div class="card-preview-header-actions">
      {#if mode === "view" && viewAvailable}
        <button
          class="icon-action"
          type="button"
          aria-label="Editar"
          title="Editar"
          onclick={edit}>🖋</button
        >
      {/if}
      <button
        class="icon-action"
        type="button"
        aria-label="Cerrar"
        onclick={onclose}>✕</button
      >
    </div>
  </header>

  {#if mode === "view"}
    {#if viewAvailable && view}{@render view()}{/if}
  {:else}
    <form
      onsubmit={(event) => {
        event.preventDefault();
        if (!saving) void onsave();
      }}
    >
      {@render form()}
      <div class="form-actions">
        <button type="button" class="btn btn-secondary" onclick={cancelEdit}
          >Cancelar</button
        >
        <button type="submit" class="btn btn-primary" disabled={saving}>
          {saving ? "..." : "Guardar"}
        </button>
      </div>
    </form>
  {/if}
</dialog>

<style>
  .card-preview-modal {
    max-width: 680px;
    width: min(680px, calc(100vw - 32px));
    max-height: 90vh;
    padding: 24px;
    margin: auto;
  }

  .card-preview-modal::backdrop {
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(4px);
  }

  .card-preview-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 16px;
    padding-bottom: 12px;
    border-bottom: 1px solid var(--border);
  }

  .card-preview-header h2 {
    margin: 0;
    font-size: 18px;
    font-weight: 700;
    color: var(--text);
  }

  .card-preview-header-actions {
    display: flex;
    gap: 4px;
    flex-shrink: 0;
  }

  .form-actions {
    margin-top: 20px;
  }

  @media (max-width: 600px) {
    .card-preview-modal {
      padding: 20px;
    }
  }
</style>
