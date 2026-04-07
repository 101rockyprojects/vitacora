<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import { tick, untrack } from 'svelte';
  import type { Task, Project, UsefulLink, SkillsMd } from '$lib/types';

  const WORK_TABS = ['kanban', 'projects', 'links', 'skills'] as const;
  type WorkTab = typeof WORK_TABS[number];

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let url = new URL(page.url.href);
  if (browser) {
    url = new URL(window.location.href);
  }
  const current = url.searchParams.get('tab');
  const defaultTab = WORK_TABS.includes(current as WorkTab) ? (current as WorkTab) : 'kanban';
  let activeTab = $state<WorkTab>(defaultTab);

  // Kanban
  let tasks = $state<Task[]>([]);
  let showTaskForm = $state(false);
  let editingTask = $state<Task | null>(null);
  let taskForm = $state<Task>({ title: '', status: 'to_do' });
  let draggedTask = $state<Task | null>(null);
  let selectedTags = $state<string[]>(page.data.selectedTags ?? []);
  let expandedTaskDescKeys = $state<string[]>([]);

  const selectedTagSet = $derived(new Set(selectedTags));
  const expandedTaskDescSet = $derived(new Set(expandedTaskDescKeys));
  const tagCounts = $derived((() => {
    const counts = new Map<string, number>();
    for (const task of tasks) {
      for (const tag of task.tags ?? []) {
        const normalized = tag.trim();
        if (!normalized) continue;
        counts.set(normalized, (counts.get(normalized) ?? 0) + 1);
      }
    }
    return [...counts.entries()]
      .map(([tag, count]) => ({ tag, count }))
      .sort((a, b) => b.count - a.count || a.tag.localeCompare(b.tag, 'es', { sensitivity: 'base' }));
  })());

  // Projects
  let projects = $state<Project[]>([]);
  let showProjectForm = $state(false);
  let editingProjectId = $state<string | null>(null);
  let projectForm = $state<Project>({ name: '' });

  // Useful links
  let links = $state<UsefulLink[]>([]);
  let showLinkForm = $state(false);
  let editingLinkId = $state<string | null>(null);
  let linkForm = $state<UsefulLink>({ title: '', url: '' });

  // Skills MD
  let skills = $state<SkillsMd[]>([]);
  let editingSkillId = $state<string | null>(null);
  let mdContent = $state('');
  let mdSaving = $state(false);
  let mdTextarea: HTMLTextAreaElement | null = $state(null);

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

  function switchTab(tabId: WorkTab) {
    if (WORK_TABS.includes(activeTab)) {
      activeTab = tabId as typeof activeTab;
      const next = new URL(window.location.href);
      next.searchParams.set('tab', activeTab);
      window.history.replaceState(window.history.state, '', next);
    } else {
      activeTab = 'kanban';
    }
  }

  $effect(() => {
    if (typeof window === 'undefined') return;

    const url = new URL(window.location.href);
    const current = url.searchParams.get('tab');

    if (current === activeTab) return;

    url.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', url);
  });

  $effect(() => {
    if (typeof window === 'undefined') return;
    const current = page.url.searchParams.get('tab');
    if (current === activeTab) return;
    const next = new URL(window.location.href);
    next.searchParams.set('tab', activeTab);
    window.history.replaceState(window.history.state, '', next);
  });

  async function loadAll() {
    if (!userId) return;
    const [t, p, l, s] = await Promise.all([
      repo.tasks.list(),
      repo.projects.list(),
      repo.links.list(),
      repo.skillsMd.list()
    ]);
    tasks = t.data || [];
    projects = p.data || [];
    links = l.data || [];
    skills = s.data || [];
  }

  $effect(() => {
    if (typeof window === 'undefined') return;
    const urlTags = page.url.searchParams.getAll('tag').map((t) => t.trim()).filter(Boolean);
    const unique = [...new Set(urlTags)];
    const current = untrack(() => selectedTags);
    if (unique.length === current.length && unique.every((t) => current.includes(t))) return;
    selectedTags = unique;
  });

  function syncSelectedTagsToUrl() {
    if (typeof window === 'undefined') return;
    const next = new URL(window.location.href);
    next.searchParams.delete('tag');
    for (const tag of selectedTags) next.searchParams.append('tag', tag);
    window.history.replaceState(window.history.state, '', next);
  }

  function toggleTagFilter(tag: string) {
    const normalized = tag.trim();
    if (!normalized) return;
    if (selectedTagSet.has(normalized)) selectedTags = selectedTags.filter((t) => t !== normalized);
    else selectedTags = [...selectedTags, normalized];
    syncSelectedTagsToUrl();
  }

  function clearTagFilters() {
    selectedTags = [];
    syncSelectedTagsToUrl();
  }

  function getTaskKey(task: Task): string {
    if (task.id) return task.id;
    const createdAt = task.created_at ?? '';
    return `${task.title}::${createdAt}`;
  }

  function getTaskDescDomId(key: string): string {
    return `task-desc-${key.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
  }

  function toggleTaskDescription(key: string) {
    if (expandedTaskDescSet.has(key)) expandedTaskDescKeys = expandedTaskDescKeys.filter((k) => k !== key);
    else expandedTaskDescKeys = [...expandedTaskDescKeys, key];
  }

  function matchesTagFilters(task: Task, filters: string[]): boolean {
    if (filters.length === 0) return true;
    const tags = task.tags ?? [];
    return filters.some((filter) => tags.includes(filter));
  }

  const filteredTasks = $derived(tasks.filter((t) => matchesTagFilters(t, selectedTags)));

  function staTasks(sta: Task['status']) {
    return filteredTasks.filter(t => t.status === sta);
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
    if (!confirm('¿Eliminar tarea?')) return;
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
    if (editingProjectId) await repo.projects.update(editingProjectId, projectForm);
    else await repo.projects.insert(projectForm);
    projectForm = { name: '' };
    editingProjectId = null;
    showProjectForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteProject(id: string) {
    if (!confirm('¿Eliminar proyecto?')) return;
    await repo.projects.remove(id);
    await loadAll();
  }

  // Links
  async function saveLink() {
    saving = true;
    if (editingLinkId) await repo.links.update(editingLinkId, linkForm);
    else await repo.links.insert(linkForm);
    linkForm = { title: '', url: '' };
    editingLinkId = null;
    showLinkForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteLink(id: string) {
    if (!confirm('¿Eliminar link?')) return;
    await repo.links.remove(id);
    await loadAll();
  }

  function editProject(project: Project) {
    editingProjectId = project.id || null;
    projectForm = { ...project };
    showProjectForm = true;
  }

  function editLink(link: UsefulLink) {
    editingLinkId = link.id || null;
    linkForm = { ...link };
    showLinkForm = true;
  }

  // Skills MD
  $effect(() => {
    if (!mdTextarea) return;
    mdTextarea.style.height = 'auto';
    mdTextarea.style.height = `${mdTextarea.scrollHeight}px`;
  });

  async function startEditSkill(skill: SkillsMd) {
    editingSkillId = skill.id || null;
    mdContent = skill.content || '';
    await tick();
    mdTextarea?.focus();
  }

  function cancelEditSkill() {
    editingSkillId = null;
    mdContent = '';
  }

  async function addSkill() {
    mdSaving = true;
    const now = new Date().toISOString();
    const initialContent = '# Skill\n\nEscribe tu skill aqui en Markdown...\n';
    const { data } = await repo.skillsMd.insert({ content: initialContent, updated_at: now });
    await loadAll();
    mdSaving = false;
    if (data?.id) {
      await startEditSkill(data);
    }
  }

  function formatTitle(str: string): string {
    return str
      .replace(/-/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  function getSkillName(content: string, index: number): string {
    if (!content) return `Skill ${index + 1}`;
    // Search explicit name of skill --- name: Skill Name ---
    const nameMatch = content.match(/^---[\s\S]*?name:\s*([^\n]+)[\s\S]*?---/);
    if (nameMatch) {
      return formatTitle(nameMatch[1].trim());
    }
    // Search first header # Title
    const titleMatch = content.match(/^#\s+(.+)$/m);
    if (titleMatch) {
      return formatTitle(titleMatch[1].trim());
    }
    // Default fallback
    return `Skill #${index + 1}`;
  }

  async function saveMd() {
    if (!editingSkillId) return;
    mdSaving = true;
    await repo.skillsMd.update(editingSkillId, { content: mdContent, updated_at: new Date().toISOString() });
    await loadAll();
    mdSaving = false;
    editingSkillId = null;
  }

  // Simple markdown-to-html for preview
  function renderMd(md: string): string {
    return md
      .replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/,"")
      // Headers
      .replace(/^### (.+)$/gm, '<h3>$1</h3>')
      .replace(/^## (.+)$/gm, '<h2>$1</h2>')
      .replace(/^# (.+)$/gm, '<h1>$1</h1>')
      // Divider (---, ***, ___)
      .replace(/^(---|\*\*\*|___)$/gm, '<hr/>')
      // Bold / Italic
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      // Code
      .replace(/`(.+?)`/g, '<code>$1</code>')
      // Links [text](url)
      .replace(
        /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
      )
      // Lists
      // - Numeric List
      .replace(/^(\s*)(\d+)\.\s+(.+)$/gm, (_, spaces, num, content) => {
        const indent = (spaces.length + 1) * (spaces.length > 0 ? 0.5 : 1);
        return `<li style="margin-left:${indent}px">${num}. ${content}</li>`;
      })
      // - Bullet list
      .replace(/^(\s*)- (.+)$/gm, (_, spaces, content) => {
        const indent = (spaces.length + 1) * (spaces.length > 0 ? 0.5 : 1); // ajusta esto
        return `<li style="margin-left:${indent}rem">${content}</li>`;
      })
      .replace(/(<li>.*<\/li>(?:\n<li>.*<\/li>)*)/g, '<ul>$1</ul>\n')
      // Line breaks
      .replace(/\n/g, '<br/>')
      .replace(/\n\n/g, '');
  }

  const tabs = [
    { id: 'kanban', label: 'Kanban', icon: '⌘' },
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
      <button class="tab-btn" class:active={activeTab === tab.id} onclick={() => switchTab(tab.id)}>
        <span>{tab.icon}</span> {tab.label}
      </button>
    {/each}
  </div>

  <!-- KANBAN -->
  {#if activeTab === 'kanban'}
    <div class="fade-in">
      <div class="tab-actions kanban-actions">
        <button class="btn btn-primary" onclick={() => { resetTaskForm(); showTaskForm = true; }}>+ Nueva tarea</button>
        {#if tagCounts.length > 0}
          <div class="tag-filters" aria-label="Filtrar por tags">
            <span class="tag-filter-label">Tags:</span>
            {#each tagCounts as t}
              <button
                class="tag-filter"
                class:active={selectedTagSet.has(t.tag)}
                type="button"
                onclick={() => toggleTagFilter(t.tag)}
                aria-pressed={selectedTagSet.has(t.tag)}
              >
                {t.tag} <span class="tag-filter-count">({t.count})</span>
              </button>
            {/each}
            {#if selectedTags.length > 0}
              <button class="tag-filter-clear" type="button" onclick={clearTagFilters}>Limpiar</button>
            {/if}
          </div>
        {/if}
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
                {@const key = getTaskKey(task)}
                {@const descId = getTaskDescDomId(key)}
                <div
                  class="kanban-card"
                  draggable="true"
                  ondragstart={() => onDragStart(task)}
                >
                  <div class="kcard-header">
                    <div class="kcard-title">{task.title}</div>
                    {#if task.description}
                      <button
                        class="kcard-desc-toggle"
                        type="button"
                        draggable="false"
                        aria-expanded={expandedTaskDescSet.has(key)}
                        aria-controls={descId}
                        onpointerdown={(e) => e.stopPropagation()}
                        onclick={(e) => { e.stopPropagation(); toggleTaskDescription(key); }}
                        ondragstart={(e) => e.preventDefault()}
                      >
                        <span class="kcard-desc-toggle-label">
                          {expandedTaskDescSet.has(key) ? 'Ocultar' : 'Ver más'}
                        </span>
                        <span class="kcard-desc-toggle-icon" class:open={expandedTaskDescSet.has(key)}>▾</span>
                      </button>
                    {/if}
                  </div>
                  {#if task.description && expandedTaskDescSet.has(key)}
                    <div class="kcard-desc" id={descId}>{task.description}</div>
                  {/if}
                  {#if task.tags?.length && expandedTaskDescSet.has(key)}
                    <div class="kcard-tags">
                      {#each task.tags as tag}
                        <span class="tag">{tag}</span>
                      {/each}
                    </div>
                  {/if}
                  {#if task.due_date}
                    <div class="kcard-due">📅 {new Date(task.due_date).toLocaleDateString('es-ES')}</div>
                  {/if}
                  <div class="kcard-actions">
                    <select class="kcard-move" onchange={(e) => moveTask(task, (e.target as HTMLSelectElement).value as Task['status'])} value={task.status}>
                      {#each statuses as s}
                      <option value={s.id}>{s.label}</option>
                      {/each}
                    </select>
                    <button class="btn btn-secondary" style="font-size:11px;padding:3px 6px;" onclick={() => editTask(task)}>Editar</button>
                    <button class="btn btn-ghost" style="font-size:11px;color:var(--accent-red);padding:3px 6px;" onclick={() => deleteTask(task.id!)}>✕</button>
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

  <!-- LINKS -->
  {:else if activeTab === 'links'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { editingLinkId = null; linkForm = { title: '', url: '' }; showLinkForm = true; }}>+ Agregar link</button>
      </div>
      <div class="links-list">
        {#each links as l}
          <div class="link-item card">
            <div class="link-icon">🔗</div>
            <div class="link-info">
              <a href={l.url} target="_blank" class="link-title">{l.title}</a>
              <div class="link-url">{l.url}</div>
            </div>
            <div style="display:flex;gap:6px;">
              <button class="small-btn btn-secondary" onclick={() => editLink(l)}>🖋</button>
              <button class="small-btn btn-ghost" onclick={() => deleteLink(l.id!)}>✕</button>
            </div>
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
          <button class="btn btn-primary" onclick={addSkill} disabled={mdSaving}>{mdSaving ? '...' : '+ Nueva skill'}</button>
        </div>
      </div>

      {#if skills.length === 0}
        <div class="empty-state card">Aun no tienes skills. Agrega la primera.</div>
      {:else}
        <div class="skills-grid">
          {#each skills as skill, index (skill.id)}
            {@const isEditing = editingSkillId === skill.id}
            <div class="card skill-card">
              <div class="skill-card-header">
                <div class="skill-meta">
                  <div class="skill-title">{getSkillName(skill.content, index)}</div>
                  <div class="skill-updated">
                    {skill.updated_at ? new Date(skill.updated_at).toLocaleString('es-ES') : ''}
                  </div>
                </div>
                <div style="display:flex;gap:8px;">
                  {#if isEditing}
                    <button class="btn btn-secondary" onclick={cancelEditSkill}>Cancelar</button>
                    <button class="btn btn-primary" onclick={saveMd} disabled={mdSaving}>{mdSaving ? '...' : 'Guardar'}</button>
                  {:else}
                    <button class="btn btn-secondary" onclick={() => startEditSkill(skill)}>Editar</button>
                  {/if}
                </div>
              </div>

              {#if isEditing}
                <textarea
                  class="md-editor skill-editor"
                  bind:this={mdTextarea}
                  bind:value={mdContent}
                  rows="8"
                  placeholder="# Skill&#10;&#10;Escribe aqui en Markdown..."
                ></textarea>
              {:else}
                <div class="md-preview skill-preview">
                  {@html renderMd(skill.content || '')}
                </div>
              {/if}
            </div>
          {/each}
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
          {#each statuses as sta}
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
      <h3>{editingProjectId ? 'Editar proyecto' : 'Nuevo proyecto'}</h3>
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
      <h3>{editingLinkId ? 'Editar link útil' : 'Nuevo link útil'}</h3>
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
  .kanban-actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
  }

  .tag-filters {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-wrap: wrap;
    justify-content: flex-end;
  }

  .tag-filter-label {
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
    margin-right: 2px;
    user-select: none;
  }

  .tag-filter {
    font-size: 12px;
    padding: 4px 10px;
    border-radius: 8px;
    background: var(--bg2);
    border: 1px solid var(--border);
    color: var(--text2);
    text-transform: uppercase;
    font-family: var(--font-mono);
    font-weight: 600;
    transition: all var(--transition);
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }

  .tag-filter:hover { border-color: var(--accent-green); color: var(--text2); }

  .tag-filter.active {
    background: rgba(168,230,207,0.12);
    border-color: rgba(168,230,207,0.45);
    color: var(--text);
  }

  .tag-filter-count {
    font-size: 11px;
    opacity: 0.85;
    font-family: var(--font-mono);
  }

  .tag-filter-clear {
    font-size: 12px;
    padding: 4px 10px;
    border-radius: 999px;
    color: var(--text3);
    border: 1px dashed var(--border);
    background: transparent;
    transition: all var(--transition);
  }

  .tag-filter-clear:hover { border-color: var(--text3); color: var(--text2); }

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

  .kcard-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 4px;
  }

  .kcard-title { font-size: 14px; font-weight: 600; color: var(--text); margin-bottom: 4px; }
  .kcard-desc { font-size: 12px; color: var(--text2); margin-bottom: 6px; }
  .kcard-tags { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 6px; }
  .kcard-due { font-size: 11px; color: var(--text3); font-family: var(--font-mono); margin-bottom: 8px; }

  .kcard-desc-toggle {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    font-family: var(--font-mono);
    padding: 3px 8px;
    border-radius: 999px;
    background: var(--bg3);
    border: 1px solid var(--border);
    color: var(--text3);
    transition: all var(--transition);
    cursor: pointer;
    flex-shrink: 0;
  }

  .kcard-desc-toggle:hover { border-color: var(--text3); color: var(--text2); }

  .kcard-desc-toggle-icon {
    display: inline-block;
    transition: transform var(--transition);
    transform-origin: center;
  }

  .kcard-desc-toggle-icon.open { transform: rotate(180deg); }

  .tag {
    font-size: 11px;
    padding: 2px 7px;
    border-radius: 999px;
    background: var(--bg3);
    border: 1px solid var(--border);
    color: var(--text3);
    font-family: var(--font-mono);
    white-space: nowrap;
  }

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

  .skills-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 14px;
  }

  @media (max-width: 900px) {
    .skills-grid { grid-template-columns: 1fr; }
  }

  .skill-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    margin-bottom: 10px;
  }

  .skill-meta { display: flex; flex-direction: column; gap: 2px; }
  .skill-title { font-size: 13px; font-weight: 800; color: var(--text); font-family: var(--font-mono); }
  .skill-updated { font-size: 11px; color: var(--text3); font-family: var(--font-mono); }

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

  .skill-preview {
    max-height: 300px;
    overflow: auto;
  }

  .skill-editor {
    height: auto;
    resize: none;
  }

  :global(.md-preview h1) { font-size: 22px; margin: 16px 0 8px; color: var(--accent-green); }
  :global(.md-preview h2) { font-size: 18px; margin: 14px 0 6px; color: var(--accent-orange); }
  :global(.md-preview h3) { font-size: 15px; margin: 12px 0 4px; color: var(--accent-purple); }
  :global(.md-preview code) { background: var(--bg2); padding: 2px 6px; border-radius: 4px; font-size: 12px; font-family: var(--font-mono); }
  :global(.md-preview ul) { padding-left: 20px; }
  :global(.md-preview li) { margin: 4px 0; }
  :global(.md-preview a) { color: var(--accent-yellow); font-weight: 600; font-style: italic; text-decoration: underline; }
  :global(.md-preview hr) { border: none; border-top: 1px solid var(--border); margin: 16px 0; }
  :global(.md-preview br) { display: block; content: ""; margin: 2px 0; }

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

    .links-list { gap: 12px; }

    .link-item {
      align-items: flex-start;
      gap: 10px;
      flex-wrap: wrap;
    }

    .link-title {
      font-size: 13px;
      word-break: break-word;
    }

    .link-url {
      font-size: 11px;
      line-height: 1.4;
      overflow-wrap: anywhere;
      word-break: break-word;
    }
  }
</style>
