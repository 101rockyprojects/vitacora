<script lang="ts">
  import type { Project } from '$lib/types';
  import { createRepository } from '$lib/services/repository';

  interface Props {
    userId: string;
    projects?: Project[];
  }

  let { userId, projects = $bindable([]) }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showProjectForm = $state(false);
  let editingProjectId = $state<string | null>(null);
  let projectForm = $state<Project>({ name: '' });
  let saving = $state(false);

  async function saveProject() {
    saving = true;
    if (editingProjectId) await repo.projects.update(editingProjectId, projectForm);
    else await repo.projects.insert(projectForm);
    projectForm = { name: '' };
    editingProjectId = null;
    showProjectForm = false;
    const { data } = await repo.projects.list();
    projects = data || [];
    saving = false;
  }

  async function deleteProject(id: string) {
    if (!confirm('¿Eliminar proyecto?')) return;
    await repo.projects.remove(id);
    const { data } = await repo.projects.list();
    projects = data || [];
  }

  function editProject(project: Project) {
    editingProjectId = project.id || null;
    projectForm = { ...project };
    showProjectForm = true;
  }

  export function openNewProject() {
    editingProjectId = null;
    projectForm = { name: '' };
    showProjectForm = true;
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { editingProjectId = null; projectForm = { name: '' }; showProjectForm = true; }}>+ Nuevo proyecto</button>
  </div>
  <div class="projects-grid">
    {#each projects as p}
      <div class="project-card card">
        <div class="project-header">
          <div class="project-name">{p.name}</div>
          <div style="display:flex;gap:6px;">
            <button class="small-btn btn-secondary" style="font-size:11px;" onclick={() => editProject(p)}>🖋</button>
            <button class="small-btn btn-ghost" style="font-size:11px;" onclick={() => deleteProject(p.id!)}>✕</button>
          </div>
        </div>
        {#if p.description}
          <div class="project-desc">{p.description}</div>
        {/if}
        <div class="project-links">
          {#if p.github_link}
            <a href={p.github_link} target="_blank" class="plink">GitHub →</a>
          {/if}
          {#if p.deploy_link}
            <a href={p.deploy_link} target="_blank" class="plink plink-deploy">Deploy →</a>
          {/if}
          {#if p.inspiration_link}
            <a href={p.inspiration_link} target="_blank" class="plink">Inspiración →</a>
          {/if}
        </div>
      </div>
    {/each}
    {#if projects.length === 0}
      <div class="empty-state card" style="grid-column:1/-1">Registra tus proyectos e ideas 🚀</div>
    {/if}
  </div>
</div>

{#if showProjectForm}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) showProjectForm = false; }}
    onkeydown={(e) => { if (e.key === 'Escape') showProjectForm = false; }}
    role="presentation"
  >
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="project-form-title">
      <h3 id="project-form-title">{editingProjectId ? 'Editar proyecto' : 'Nuevo proyecto'}</h3>
      <form onsubmit={(e) => { e.preventDefault(); saveProject(); }}>
        <div class="form-group">
          <label for="project-name">Nombre</label>
          <input id="project-name" bind:value={projectForm.name} placeholder="Nombre del proyecto" />
        </div>
        <div class="form-group">
          <label for="project-desc">Descripción</label>
          <textarea id="project-desc" bind:value={projectForm.description} rows="3"></textarea>
        </div>
        <div class="form-group">
          <label for="project-github">GitHub</label>
          <input id="project-github" bind:value={projectForm.github_link} placeholder="https://github.com/..." />
        </div>
        <div class="form-group">
          <label for="project-deploy">Deploy</label>
          <input id="project-deploy" bind:value={projectForm.deploy_link} placeholder="https://..." />
        </div>
        <div class="form-group">
          <label for="project-inspiration">Inspiración</label>
          <input id="project-inspiration" bind:value={projectForm.inspiration_link} placeholder="https://..." />
        </div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick={() => showProjectForm = false}>Cancelar</button>
          <button type="submit" class="btn btn-primary" disabled={saving}>{saving ? '...' : 'Guardar'}</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .projects-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
  }

  .project-card { transition: transform var(--transition); }
  .project-card:hover { transform: translateY(-2px); }

  .project-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 8px;
  }

  .project-name { font-weight: 700; font-size: 16px; }
  .project-desc { font-size: 13px; color: var(--text2); margin-bottom: 12px; line-height: 1.5; }

  .project-links { display: flex; flex-wrap: wrap; gap: 8px; }

  .plink {
    font-size: 12px;
    font-family: var(--font-mono);
    color: var(--accent-green);
    padding: 3px 8px;
    background: rgba(168,230,207,0.08);
    border-radius: 6px;
    border: 1px solid rgba(168,230,207,0.2);
    transition: all var(--transition);
  }

  .plink:hover { background: rgba(168,230,207,0.15); }
  .plink-deploy { color: var(--accent-yellow); background: rgba(255,217,61,0.08); border-color: rgba(255,217,61,0.2); }
  .plink-deploy:hover { background: rgba(255,217,61,0.15); }

  @media (max-width: 600px) {
    .projects-grid {
      grid-template-columns: 1fr;
      gap: 12px;
    }

    .project-name {
      font-size: 14px;
      line-height: 1.3;
      word-break: break-word;
    }

    .project-desc {
      font-size: 12px;
      line-height: 1.45;
      word-break: break-word;
    }
  }
</style>