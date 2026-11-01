<script lang="ts">
  import type { LearningItem } from "$lib/types";
  import { createRepository } from "$lib/services/repository";
  import { awardXP, XP_VALUES } from "$lib/utils/xp";
  import CardPreviewModal from "$lib/components/CardPreviewModal.svelte";

  interface Props {
    userId: string;
    learning?: LearningItem[];
    onRefresh?: () => void;
  }

  let { userId, learning = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showLearnModal = $state(false);
  let learnModalMode = $state<"view" | "edit">("view");
  let previewLearnId = $state<string | null>(null);
  let editingLearnId = $state<string | null>(null);
  let learnForm = $state<LearningItem>({ topic: "" });
  let saving = $state(false);
  const previewLearn = $derived(
    learning.find((item) => item.id === previewLearnId) ?? null,
  );

  async function saveLearn() {
    saving = true;
    let savedId = editingLearnId;
    if (editingLearnId) {
      await repo.learning.update(editingLearnId, learnForm);
    } else {
      const { data } = await repo.learning.insert(learnForm);
      savedId = data?.id ?? null;
      await awardXP(
        userId,
        "education",
        "learning_added",
        XP_VALUES.learning_added,
        undefined,
        learnForm.topic,
      );
    }
    const { data } = await repo.learning.list();
    learning = data || [];
    saving = false;
    if (savedId) {
      previewLearnId = savedId;
      learnModalMode = "view";
      editingLearnId = null;
      learnForm = { topic: "" };
    }
  }

  async function deleteLearn(id: string) {
    if (!confirm("¿Eliminar tema?")) return;
    await repo.learning.remove(id);
    const { data } = await repo.learning.list();
    learning = data || [];
  }

  function editLearn(item: LearningItem) {
    previewLearnId = item.id ?? null;
    editingLearnId = item.id || null;
    learnForm = { ...item };
    learnModalMode = "edit";
    showLearnModal = true;
  }

  function openLearnPreview(item: LearningItem) {
    previewLearnId = item.id ?? null;
    learnModalMode = "view";
    showLearnModal = true;
  }

  function openNewLearn() {
    previewLearnId = null;
    editingLearnId = null;
    learnForm = { topic: "" };
    learnModalMode = "edit";
    showLearnModal = true;
  }

  function cancelLearnEdit() {
    editingLearnId = null;
    learnForm = { topic: "" };
  }

  function closeLearnModal() {
    showLearnModal = false;
    previewLearnId = null;
    editingLearnId = null;
    learnForm = { topic: "" };
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button
      class="btn btn-primary"
      onclick={openNewLearn}>+ Agregar tema</button
    >
  </div>
  <div class="learn-list">
    {#each learning as item}
      <article class="learn-card item-card card">
        <button
          class="learn-preview-trigger"
          type="button"
          aria-label="Ver detalles de {item.topic}"
          onclick={() => openLearnPreview(item)}
        >
          {#if item.image_url}
            <img class="learn-card-image" src={item.image_url} alt="" />
          {/if}
          <div class="learn-main">
            <h3 class="learn-topic">{item.topic}</h3>
            {#if item.notes}
              <p class="learn-notes learn-notes-preview">{item.notes}</p>
            {/if}
          </div>
        </button>
        <div class="item-card-footer">
          {#if item.resource_link}
            <a
              href={item.resource_link}
              target="_blank"
              rel="noopener noreferrer"
              class="learn-link"
            >🔗 Recurso</a>
          {:else}
            <span></span>
          {/if}
          <div class="item-card-actions">
            <button
              class="icon-action"
              type="button"
              aria-label="Editar tema"
              onclick={() => editLearn(item)}>🖋</button
            >
            <button
              class="icon-action danger"
              type="button"
              aria-label="Eliminar tema"
              onclick={() => deleteLearn(item.id!)}>✕</button
            >
          </div>
        </div>
      </article>
    {/each}
    {#if learning.length === 0}
      <div class="empty-state card">Empieza a registrar lo que aprendes 🧠</div>
    {/if}
  </div>
</div>

{#if showLearnModal}
  <CardPreviewModal
    title={learnModalMode === "view"
      ? previewLearn?.topic ?? "Aprendizaje"
      : editingLearnId
        ? "Editar tema de aprendizaje"
        : "Nuevo tema de aprendizaje"}
    bind:mode={learnModalMode}
    viewAvailable={!!previewLearn}
    saving={saving}
    onclose={closeLearnModal}
    onedit={() => previewLearn && editLearn(previewLearn)}
    oncancel={cancelLearnEdit}
    onsave={saveLearn}
  >
    {#snippet view()}
      {#if previewLearn}
        <div class="learn-preview">
          {#if previewLearn.image_url}
            <img class="learn-preview-image" src={previewLearn.image_url} alt="" />
          {/if}
          <div class="learn-preview-content">
            {#if previewLearn.resource_link}
              <a
                class="learn-preview-link"
                href={previewLearn.resource_link}
                target="_blank"
                rel="noopener noreferrer"
              >🔗 Abrir recurso</a>
            {/if}
            <h3>Notas</h3>
            {#if previewLearn.notes}
              <p class="learn-preview-notes">{previewLearn.notes}</p>
            {:else}
              <p class="learn-preview-empty">Sin notas</p>
            {/if}
          </div>
        </div>
      {/if}
    {/snippet}

    {#snippet form()}
        <div class="form-group">
          <label for="learn-topic">Tema</label>
          <input
            id="learn-topic"
            bind:value={learnForm.topic}
            placeholder="Ej: Diseño de APIs REST"
          />
        </div>
        <div class="form-group">
          <label for="learn-resource">Enlace de recurso</label>
          <input
            id="learn-resource"
            type="url"
            bind:value={learnForm.resource_link}
            placeholder="https://..."
          />
        </div>
        <div class="form-group">
          <label for="learn-image">URL imagen/captura</label>
          <input
            id="learn-image"
            type="url"
            bind:value={learnForm.image_url}
            placeholder="https://..."
          />
        </div>
        <div class="form-group">
          <label for="learn-notes">Notas</label>
          <textarea id="learn-notes" bind:value={learnForm.notes} rows="3"
          ></textarea>
        </div>
    {/snippet}
  </CardPreviewModal>
{/if}

<style>
  .learn-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .learn-card {
    gap: 12px;
  }

  .learn-preview-trigger {
    display: flex;
    align-items: flex-start;
    gap: 14px;
    width: 100%;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    text-align: left;
    cursor: pointer;
  }

  .learn-preview-trigger:focus-visible {
    outline: 2px solid var(--accent);
    outline-offset: 4px;
    border-radius: var(--radius-sm);
  }

  .learn-card-image {
    width: 120px;
    max-height: 90px;
    flex-shrink: 0;
    border-radius: var(--radius-sm);
    object-fit: cover;
  }

  .learn-main {
    flex: 1;
    min-width: 0;
  }

  .learn-topic {
    margin: 0;
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
  }

  .learn-link {
    display: inline-block;
    font-size: 12px;
    color: var(--accent);
  }

  .learn-notes {
    font-size: 12px;
    color: var(--text2);
    margin-top: 6px;
    line-height: 1.5;
  }

  .learn-notes-preview {
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    overflow: hidden;
  }

  .learn-preview {
    display: flex;
    align-items: flex-start;
    gap: 16px;
  }

  .learn-preview-image {
    width: min(35%, 180px);
    max-height: 240px;
    flex-shrink: 0;
    border-radius: var(--radius-sm);
    object-fit: cover;
  }

  .learn-preview-content {
    flex: 1;
    min-width: 0;
  }

  .learn-preview-link {
    display: inline-block;
    margin-bottom: 16px;
    color: var(--accent);
  }

  .learn-preview-content h3 {
    font-size: 14px;
  }

  .learn-preview-notes {
    white-space: pre-wrap;
  }

  .learn-preview-empty {
    color: var(--text3);
    font-style: italic;
  }

  @media (max-width: 600px) {
    .learn-preview-trigger,
    .learn-preview {
      flex-direction: column;
    }

    .learn-card-image,
    .learn-preview-image {
      width: 100%;
      max-height: 180px;
    }
  }
</style>
