<script lang="ts">
  import { page } from '$app/stores';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import type { Task, Project, UsefulLink, SkillsMd } from '$lib/types';

  const userId = $derived($page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let activeTab = $state<'kanban' | 'projects' | 'links' | 'skills'>('kanban');

  // Kanban
  let tasks = $state<Task[]>([]);
  let showTaskForm = $state(false);
  let editingTask = $state<Task | null>(null);
  let taskForm = $state<Task>({ title: '', status: 'to_do' });
  let draggedTask = $state<Task | null>(null);

  // Projects
  let projects = $state<Project[]>([]);
  let showProjectForm = $state(false);
  let projectForm = $state<Project>({ name: '' });

  // Useful links
  let links = $state<UsefulLink[]>([]);
  let showLinkForm = $state(false);
  let linkForm = $state<UsefulLink>({ title: '', url: '' });

  // Skills MD
  let skillsMd = $state<SkillsMd | null>(null);
  let mdContent = $state('');
  let mdEditing = $state(false);
  let mdSaving = $state(false);

  let saving = $state(false);

  const statuses: { id: Task['status']; label: string; color: string }[] = [
    { id: 'to_do', label: 'Por hacer', color: 'var(--accent-blue)' },
    { id: 'doing', label: 'En progreso', color: 'var(--accent-yellow)' },
    { id: 'done', label: 'Hecho', color: 'var(--accent-green)' },
    { id: 'to_review', label: 'Revisar', color: 'var(--accent-orange)' }
  ];

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadAll();
    }
  });

  async function loadAll() {
    if (!userId) return;
    const [t, p, l, s] = await Promise.all([
      repo.tasks.list(),
      repo.projects.list(),
      repo.links.list(),
      repo.skillsMd.get()
    ]);
    tasks = t.data || [];
    projects = p.data || [];
    links = l.data || [];
    skillsMd = s.data || null;
    mdContent = skillsMd?.content || '# Skills\n\nEscribe tus habilidades aquí en Markdown...\n';
  }

  function staTasks(sta: Task['status']) {
    return tasks.filter(t => t.status === sta);
  }

  function resetTaskForm() { taskForm = { title: '', status: 'to_do' }; editingTask = null; }

  async function saveTask() {
    saving = true;
    if (editingTask?.id) {
      await repo.tasks.update(editingTask.id, { ...taskForm, updated_at: new Date().toISOString() });
      if (taskForm.status === 'done' && editingTask.status !== 'done') {
        await awardXP(userId, 'work', 'task_done', XP_VALUES.task_done, editingTask.id);
      }
    } else {
      await repo.tasks.insert(taskForm);
    }
    await loadAll();
    showTaskForm = false;
    resetTaskForm();
    saving = false;
  }

  async function moveTask(task: Task, sta: Task['status']) {
    if (task.status === sta) return;
    const wasDone = task.status === 'done';
    await repo.tasks.update(task.id!, { status: sta, updated_at: new Date().toISOString() });
    if (sta === 'done' && !wasDone) await awardXP(userId, 'work', 'task_done', XP_VALUES.task_done, task.id);
    await loadAll();
  }

  async function deleteTask(id: string) {
    await repo.tasks.remove(id);
    await loadAll();
  }

  function editTask(t: Task) { editingTask = t; taskForm = { ...t }; showTaskForm = true; }

  // Drag & drop (simple browser DnD)
  function onDragStart(task: Task) { draggedTask = task; }

  async function onDrop(sta: Task['status']) {
    if (draggedTask && draggedTask.status !== sta) {
      await moveTask(draggedTask, sta);
    }
    draggedTask = null;
  }

  // Projects
  async function saveProject() {
    saving = true;
    await repo.projects.insert(projectForm);
    projectForm = { name: '' };
    showProjectForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteProject(id: string) {
    await repo.projects.remove(id);
    await loadAll();
  }

  // Links
  async function saveLink() {
    saving = true;
    await repo.links.insert(linkForm);
    linkForm = { title: '', url: '' };
    showLinkForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteLink(id: string) {
    await repo.links.remove(id);
    await loadAll();
  }

  // Skills MD
  async function saveMd() {
    mdSaving = true;
    if (skillsMd?.id) {
      await repo.skillsMd.update(skillsMd.id, { content: mdContent, updated_at: new Date().toISOString() });
    } else {
      await repo.skillsMd.insert({ content: mdContent });
    }
    mdEditing = false;
    await loadAll();
    mdSaving = false;
  }

  // Simple markdown-to-html for preview
  function renderMd(md: string): string {
    return md
      .replace(/^### (.+)$/gm, '<h3>$1</h3>')
      .replace(/^## (.+)$/gm, '<h2>$1</h2>')
      .replace(/^# (.+)$/gm, '<h1>$1</h1>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      .replace(/`(.+?)`/g, '<code>$1</code>')
      .replace(/^- (.+)$/gm, '<li>$1</li>')
      .replace(/\n\n/g, '<br/><br/>')
      .replace(/(<li>.*<\/li>)/gs, '<ul>$1</ul>');
  }

  const tabs = [
    { id: 'kanban', label: 'Kanban', icon: '⬡' },
    { id: 'projects', label: 'Proyectos', icon: '🚀' },
    { id: 'links', label: 'Links útiles', icon: '🔗' },
    { id: 'skills', label: 'Skills.md', icon: '📝' }
  ] as const;
</script>

<div class="work-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Trabajo & Proyectos</h2>
      <div class="section-subtitle">Organiza tu flujo de trabajo</div>
    </div>
  </div>

  <div class="tabs-bar">
    {#each tabs as tab}
      <button class="tab-btn" class:active={activeTab === tab.id} onclick={() => activeTab = tab.id as typeof activeTab}>
        <span>{tab.icon}</span> {tab.label}
      </button>
    {/each}
  </div>

  <!-- KANBAN -->
  {#if activeTab === 'kanban'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { resetTaskForm(); showTaskForm = true; }}>+ Nueva tarea</button>
      </div>
      <div class="kanban-board">
        {#each statuses as sta}
          <div
            class="kanban-sta"
            ondragover={(e) => e.preventDefault()}
            ondrop={() => onDrop(sta.id)}
            role="region"
            aria-label={sta.label}
          >
            <div class="kanban-sta-header">
              <span class="sta-dot" style="background:{sta.color}"></span>
              <span class="sta-label">{sta.label}</span>
              <span class="sta-count">{staTasks(sta.id).length}</span>
            </div>
            <div class="kanban-cards">
              {#each staTasks(sta.id) as task}
                <div
                  class="kanban-card"
                  draggable="true"
                  ondragstart={() => onDragStart(task)}
                >
                  <div class="kcard-title">{task.title}</div>
                  {#if task.description}
                    <div class="kcard-desc">{task.description}</div>
                  {/if}
                  {#if task.tags?.length}
                    <div class="kcard-tags">
                      {#each task.tags as tag}
                        <span class="tag" style="background:var(--bg3);staor:var(--text3)">{tag}</span>
                      {/each}
                    </div>
                  {/if}
                  {#if task.due_date}
                    <div class="kcard-due">📅 {new Date(task.due_date).toLocaleDateString('es-ES')}</div>
                  {/if}
                  <div class="kcard-actions">
                    <button class="btn btn-ghost" style="font-size:11px;padding:3px 6px;" onclick={() => editTask(task)}>✎ editar</button>
                    <select class="kcard-move" onchange={(e) => moveTask(task, (e.target as HTMLSelectElement).value as Task['status'])} value={task.status}>
                      {#each statuses as s}
                        <option value={s.id}>{s.label}</option>
                      {/each}
                    </select>
                    <button class="btn btn-ghost" style="font-size:11px;staor:var(--accent-red);padding:3px 6px;" onclick={() => deleteTask(task.id!)}>✕</button>
                  </div>
                </div>
              {/each}
            </div>
          </div>
        {/each}
      </div>
    </div>

  <!-- PROJECTS -->
  {:else if activeTab === 'projects'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { projectForm = { name: '' }; showProjectForm = true; }}>+ Nuevo proyecto</button>
      </div>
      <div class="projects-grid">
        {#each projects as p}
          <div class="project-card card">
            <div class="project-header">
              <div class="project-name">{p.name}</div>
              <button class="btn btn-ghost" style="font-size:11px;" onclick={() => deleteProject(p.id!)}>✕</button>
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

  <!-- LINKS -->
  {:else if activeTab === 'links'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { linkForm = { title: '', url: '' }; showLinkForm = true; }}>+ Agregar link</button>
      </div>
      <div class="links-list">
        {#each links as l}
          <div class="link-item card">
            <div class="link-icon">🔗</div>
            <div class="link-info">
              <a href={l.url} target="_blank" class="link-title">{l.title}</a>
              <div class="link-url">{l.url}</div>
            </div>
            <button class="btn btn-ghost" onclick={() => deleteLink(l.id!)}>✕</button>
          </div>
        {/each}
        {#if links.length === 0}
          <div class="empty-state card">Guarda tus recursos favoritos 🔗</div>
        {/if}
      </div>
    </div>

  <!-- SKILLS MD -->
  {:else if activeTab === 'skills'}
    <div class="fade-in">
      <div class="skills-header">
        <span class="section-title" style="font-size:18px;">skills.md</span>
        <div style="display:flex;gap:8px;">
          {#if mdEditing}
            <button class="btn btn-secondary" onclick={() => mdEditing = false}>Cancelar</button>
            <button class="btn btn-primary" onclick={saveMd} disabled={mdSaving}>{mdSaving ? '...' : 'Guardar'}</button>
          {:else}
            <button class="btn btn-secondary" onclick={() => mdEditing = true}>✎ Editar</button>
          {/if}
        </div>
      </div>
      {#if mdEditing}
        <textarea class="md-editor" bind:value={mdContent} rows="24" placeholder="# Skills&#10;&#10;Escribe aquí en Markdown..."></textarea>
      {:else}
        <div class="md-preview card">
          {@html renderMd(mdContent)}
        </div>
      {/if}
    </div>
  {/if}
</div>

<!-- Modals -->
{#if showTaskForm}
  <div class="modal-backdrop" onclick={(e) => 
      {
        if (e.target === e.currentTarget) {
          showTaskForm = false; resetTaskForm();
        }
      }}>
    <div class="modal">
      <h3>{editingTask ? 'Editar tarea' : 'Nueva tarea'}</h3>
      <div class="form-group"><label>Título</label><input bind:value={taskForm.title} placeholder="¿Qué hay que hacer?" /></div>
      <div class="form-group"><label>Descripción</label><textarea bind:value={taskForm.description} rows="2"></textarea></div>
      <div class="form-group">
        <label>Status</label>
        <select bind:value={taskForm.status}>
          {#each statuses as sta}col
            <option value={sta.id}>{sta.label}</option>
          {/each}
        </select>
      </div>
      <div class="form-group"><label>Fecha límite</label><input type="date" bind:value={taskForm.due_date} /></div>
      <div class="form-group">
        <label>Tags (coma separados)</label>
        <input
          value={taskForm.tags?.join(', ') || ''}
          oninput={(e) => { taskForm.tags = (e.target as HTMLInputElement).value.split(',').map(t => t.trim()).filter(Boolean); }}
          placeholder="ej: urgente, trabajo, personal"
        />
      </div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => { showTaskForm = false; resetTaskForm(); }}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveTask} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

{#if showProjectForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showProjectForm = false
        }
      }}>
    <div class="modal">
      <h3>Nuevo proyecto</h3>
      <div class="form-group"><label>Nombre</label><input bind:value={projectForm.name} placeholder="Nombre del proyecto" /></div>
      <div class="form-group"><label>Descripción</label><textarea bind:value={projectForm.description} rows="3"></textarea></div>
      <div class="form-group"><label>GitHub</label><input bind:value={projectForm.github_link} placeholder="https://github.com/..." /></div>
      <div class="form-group"><label>Deploy</label><input bind:value={projectForm.deploy_link} placeholder="https://..." /></div>
      <div class="form-group"><label>Inspiración</label><input bind:value={projectForm.inspiration_link} placeholder="https://..." /></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showProjectForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveProject} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

{#if showLinkForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showLinkForm = false
        }
      }}>
    <div class="modal">
      <h3>Nuevo link útil</h3>
      <div class="form-group"><label>Título</label><input bind:value={linkForm.title} placeholder="Nombre del recurso" /></div>
      <div class="form-group"><label>URL</label><input bind:value={linkForm.url} placeholder="https://..." /></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showLinkForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveLink} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .work-page { max-width: 1200px; }

  .tabs-bar {
    display: flex;
    gap: 4px;
    flex-wrap: wrap;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 6px;
    margin-bottom: 24px;
  }

  .tab-btn {
    padding: 8px 14px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    color: var(--text3);
    transition: all var(--transition);
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .tab-btn.active { background: var(--surface2); color: var(--text); }
  .tab-btn:hover:not(.active) { background: var(--surface); color: var(--text2); }

  .tab-actions { margin-bottom: 20px; }

  /* Kanban */
  .kanban-board {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    align-items: start;
  }

  .kanban-sta {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 14px;
    min-height: 300px;
  }

  .kanban-sta-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 14px;
  }

  .sta-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

  .sta-label {
    font-size: 12px;
    font-weight: 700;
    color: var(--text2);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    font-family: var(--font-mono);
    flex: 1;
  }

  .sta-count {
    font-size: 11px;
    color: var(--text3);
    background: var(--bg3);
    border-radius: 99px;
    padding: 1px 7px;
    font-family: var(--font-mono);
  }

  .kanban-cards { display: flex; flex-direction: column; gap: 10px; }

  .kanban-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 12px;
    cursor: grab;
    transition: all var(--transition);
  }

  .kanban-card:hover { border-color: var(--accent-green); transform: translateY(-1px); }
  .kanban-card:active { cursor: grabbing; }

  .kcard-title { font-size: 14px; font-weight: 600; color: var(--text); margin-bottom: 4px; }
  .kcard-desc { font-size: 12px; color: var(--text2); margin-bottom: 6px; }
  .kcard-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 6px; }
  .kcard-due { font-size: 11px; color: var(--text3); font-family: var(--font-mono); margin-bottom: 8px; }

  .kcard-actions {
    display: flex;
    align-items: center;
    gap: 4px;
    border-top: 1px solid var(--border);
    padding-top: 8px;
    margin-top: 4px;
  }

  .kcard-move {
    font-size: 11px;
    padding: 3px 6px;
    flex: 1;
    background: var(--bg3);
    border-radius: 6px;
    cursor: pointer;
  }

  /* Projects */
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

  /* Links */
  .links-list { display: flex; flex-direction: column; gap: 10px; }

  .link-item { display: flex; align-items: center; gap: 14px; }
  .link-icon { font-size: 20px; }
  .link-info { flex: 1; }
  .link-title { font-weight: 600; font-size: 14px; color: var(--accent-green); }
  .link-url { font-size: 12px; color: var(--text3); font-family: var(--font-mono); }

  /* MD */
  .skills-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }

  .md-editor {
    width: 100%;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    color: var(--text);
    padding: 20px;
    font-family: var(--font-mono);
    font-size: 13px;
    line-height: 1.7;
    resize: vertical;
  }

  .md-preview {
    min-height: 300px;
    font-size: 14px;
    line-height: 1.7;
    color: var(--text);
  }

  :global(.md-preview h1) { font-size: 22px; margin: 16px 0 8px; color: var(--accent-green); }
  :global(.md-preview h2) { font-size: 18px; margin: 14px 0 6px; color: var(--text); }
  :global(.md-preview h3) { font-size: 15px; margin: 12px 0 4px; color: var(--text2); }
  :global(.md-preview code) { background: var(--bg3); padding: 2px 6px; border-radius: 4px; font-size: 12px; font-family: var(--font-mono); }
  :global(.md-preview ul) { padding-left: 20px; }
  :global(.md-preview li) { margin: 4px 0; }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 32px;
    font-family: var(--font-mono);
  }

  @media (max-width: 900px) {
    .kanban-board { grid-template-columns: 1fr 1fr; }
  }

  @media (max-width: 600px) {
    .kanban-board { grid-template-columns: 1fr; }
  }
</style>
