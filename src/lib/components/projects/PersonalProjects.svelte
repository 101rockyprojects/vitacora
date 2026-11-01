<script lang="ts">
  import type { Project } from "$lib/types";
  import { createRepository } from "$lib/services/repository";
  import { awardXP, XP_VALUES } from "$lib/utils/xp";
  import CardPreviewModal from "$lib/components/CardPreviewModal.svelte";

  interface Props {
    userId: string;
    projects?: Project[];
  }

  let { userId, projects = $bindable([]) }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showProjectModal = $state(false);
  let projectModalMode = $state<"view" | "edit">("view");
  let previewProjectId = $state<string | null>(null);
  let editingProjectId = $state<string | null>(null);
  let projectForm = $state<Project>({ name: "" });
  let saving = $state(false);
  const previewProject = $derived(
    projects.find((project) => project.id === previewProjectId) ?? null,
  );

  async function saveProject() {
    saving = true;
    let savedId = editingProjectId;
    if (editingProjectId) {
      await repo.projects.update(editingProjectId, projectForm);
    } else {
      const { data } = await repo.projects.insert(projectForm);
      savedId = data?.id ?? null;
      await awardXP(
        userId,
        "work",
        "project_created",
        XP_VALUES.project_created,
        undefined,
        projectForm.name,
      );
    }
    const { data } = await repo.projects.list();
    projects = data || [];
    saving = false;
    if (savedId) {
      previewProjectId = savedId;
      projectModalMode = "view";
      projectForm = { name: "" };
      editingProjectId = null;
    }
  }

  async function deleteProject(id: string) {
    if (!confirm("¿Eliminar proyecto?")) return;
    await repo.projects.remove(id);
    const { data } = await repo.projects.list();
    projects = data || [];
  }

  function editProject(project: Project) {
    previewProjectId = project.id ?? null;
    editingProjectId = project.id || null;
    projectForm = { ...project };
    projectModalMode = "edit";
    showProjectModal = true;
  }

  export function openNewProject() {
    previewProjectId = null;
    editingProjectId = null;
    projectForm = { name: "" };
    projectModalMode = "edit";
    showProjectModal = true;
  }

  function openProjectPreview(project: Project) {
    previewProjectId = project.id ?? null;
    projectModalMode = "view";
    showProjectModal = true;
  }

  function cancelProjectEdit() {
    editingProjectId = null;
    projectForm = { name: "" };
  }

  function closeProjectModal() {
    showProjectModal = false;
    previewProjectId = null;
    editingProjectId = null;
    projectForm = { name: "" };
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button
      class="btn btn-primary"
      onclick={openNewProject}>+ Nuevo proyecto</button
    >
  </div>
  <div class="projects-grid">
    {#each projects as p}
      <article class="project-card item-card card">
        <button
          class="project-preview-trigger"
          type="button"
          aria-label="Ver detalles de {p.name}"
          onclick={() => openProjectPreview(p)}
        >
          <h3 class="project-name">{p.name}</h3>
          {#if p.description}
            <p class="project-desc project-desc-preview">{p.description}</p>
          {/if}
        </button>
        <div class="project-links">
          {#if p.github_link}
            <a href={p.github_link} target="_blank" rel="noopener noreferrer" class="plink">GitHub →</a>
          {/if}
          {#if p.deploy_link}
            <a href={p.deploy_link} target="_blank" rel="noopener noreferrer" class="plink plink-deploy">Deploy →</a>
          {/if}
          {#if p.inspiration_link}
            <a href={p.inspiration_link} target="_blank" rel="noopener noreferrer" class="plink">Inspiración →</a>
          {/if}
        </div>
        <div class="item-card-footer">
          <span></span>
          <div class="item-card-actions">
            <button
              class="icon-action"
              type="button"
              aria-label="Editar proyecto"
              onclick={() => editProject(p)}>🖋</button
            >
            <button
              class="icon-action danger"
              type="button"
              aria-label="Eliminar proyecto"
              onclick={() => deleteProject(p.id!)}>✕</button
            >
          </div>
        </div>
      </article>
    {/each}
    {#if projects.length === 0}
      <div class="empty-state card" style="grid-column:1/-1">
        Registra tus proyectos e ideas 🚀
      </div>
    {/if}
  </div>
</div>

{#if showProjectModal}
  <CardPreviewModal
    title={projectModalMode === "view"
      ? previewProject?.name ?? "Proyecto"
      : editingProjectId
        ? "Editar proyecto"
        : "Nuevo proyecto"}
    bind:mode={projectModalMode}
    viewAvailable={!!previewProject}
    saving={saving}
    onclose={closeProjectModal}
    onedit={() => previewProject && editProject(previewProject)}
    oncancel={cancelProjectEdit}
    onsave={saveProject}
  >
    {#snippet view()}
      {#if previewProject}
        <div class="project-preview">
          {#if previewProject.description}
            <p>{previewProject.description}</p>
          {:else}
            <p class="project-preview-empty">Sin descripción</p>
          {/if}
          <div class="project-preview-links">
            {#if previewProject.github_link}
              <a href={previewProject.github_link} target="_blank" rel="noopener noreferrer">GitHub →</a>
            {/if}
            {#if previewProject.deploy_link}
              <a href={previewProject.deploy_link} target="_blank" rel="noopener noreferrer">Deploy →</a>
            {/if}
            {#if previewProject.inspiration_link}
              <a href={previewProject.inspiration_link} target="_blank" rel="noopener noreferrer">Inspiración →</a>
            {/if}
          </div>
        </div>
      {/if}
    {/snippet}

    {#snippet form()}
        <div class="form-group">
          <label for="project-name">Nombre</label>
          <input
            id="project-name"
            bind:value={projectForm.name}
            placeholder="Nombre del proyecto"
          />
        </div>
        <div class="form-group">
          <label for="project-desc">Descripción</label>
          <textarea
            id="project-desc"
            bind:value={projectForm.description}
            rows="3"></textarea>
        </div>
        <div class="form-group">
          <label for="project-github">GitHub</label>
          <input
            id="project-github"
            bind:value={projectForm.github_link}
            placeholder="https://github.com/..."
          />
        </div>
        <div class="form-group">
          <label for="project-deploy">Deploy</label>
          <input
            id="project-deploy"
            bind:value={projectForm.deploy_link}
            placeholder="https://..."
          />
        </div>
        <div class="form-group">
          <label for="project-inspiration">Inspiración</label>
          <input
            id="project-inspiration"
            bind:value={projectForm.inspiration_link}
            placeholder="https://..."
          />
        </div>
    {/snippet}
  </CardPreviewModal>
{/if}

<style>
  .projects-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
  }

  .project-card {
    gap: 12px;
    transition: transform var(--transition);
  }
  .project-card:hover {
    transform: translateY(-2px);
  }

  .project-preview-trigger {
    width: 100%;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    text-align: left;
    cursor: pointer;
  }

  .project-preview-trigger:focus-visible {
    outline: 2px solid var(--accent);
    outline-offset: 4px;
    border-radius: var(--radius-sm);
  }

  .project-name {
    margin: 0;
    font-weight: 700;
    font-size: 16px;
  }
  .project-desc {
    font-size: 13px;
    color: var(--text2);
    margin: 8px 0 0;
    line-height: 1.5;
  }

  .project-desc-preview {
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    overflow: hidden;
  }

  .project-links {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .plink {
    font-size: 12px;
    font-family: var(--font-mono);
    color: var(--accent);
    padding: 3px 8px;
    background: rgba(168, 230, 207, 0.08);
    border-radius: 6px;
    border: 1px solid rgba(168, 230, 207, 0.2);
    transition: all var(--transition);
  }

  .plink:hover {
    background: rgba(168, 230, 207, 0.15);
  }
  .plink-deploy {
    color: var(--accent-yellow);
    background: rgba(255, 217, 61, 0.08);
    border-color: rgba(255, 217, 61, 0.2);
  }
  .plink-deploy:hover {
    background: rgba(255, 217, 61, 0.15);
  }

  .project-preview {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .project-preview-links {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .project-preview-links a {
    color: var(--accent);
    text-decoration: underline;
    text-underline-offset: 2px;
  }

  .project-preview-empty {
    color: var(--text3);
    font-style: italic;
  }

  @media (max-width: 768px) {
    .projects-grid {
      grid-template-columns: 1fr;
      gap: 12px;
    }
    .project-name {
      font-size: 14px;
      line-height: 1.3;
      word-break: break-word;
    }
  }
</style>
