<script lang="ts">
  import type { SkillsMd } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import { renderMd, formatLinks, getMarkdownHelp } from '$lib/utils/markdown';
  import { tick } from 'svelte';

  interface Props {
    userId: string;
    skills?: SkillsMd[];
  }

  let { userId, skills = $bindable([]) }: Props = $props();

  const repo = $derived(createRepository(userId));

  let editingSkillId = $state<string | null>(null);
  let mdContent = $state('');
  let mdSaving = $state(false);
  let mdTextarea: HTMLTextAreaElement | null = $state(null);
  let copyToast = $state(false);
  let copyToastTimer: ReturnType<typeof setTimeout> | null = $state(null);

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
    const { data: s } = await repo.skillsMd.list();
    skills = s || [];
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
    const nameMatch = content.match(/^---[\s\S]*?name:\s*([^\n]+)[\s\S]*?---/);
    if (nameMatch) {
      return formatTitle(nameMatch[1].trim());
    }
    const titleMatch = content.match(/^#\s+(.+)$/m);
    if (titleMatch) {
      return formatTitle(titleMatch[1].trim());
    }
    return `Skill #${index + 1}`;
  }

  async function saveMd() {
    if (!editingSkillId) return;
    mdSaving = true;
    await repo.skillsMd.update(editingSkillId, { content: formatLinks(mdContent), updated_at: new Date().toISOString() });
    await awardXP(userId, 'education', 'skill_document_updated', XP_VALUES.skill_document_updated, editingSkillId);
    const { data } = await repo.skillsMd.list();
    skills = data || [];
    mdSaving = false;
    editingSkillId = null;
  }

  async function copySkillContent(content: string) {
    try {
      await navigator.clipboard.writeText(content);
      copyToast = true;
      if (copyToastTimer) clearTimeout(copyToastTimer);
      copyToastTimer = setTimeout(() => {
        copyToast = false;
        copyToastTimer = null;
      }, 2500);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }
</script>

<div class="fade-in">
  <div class="skills-header">
    <button class="btn btn-primary" onclick={addSkill} disabled={mdSaving}>{mdSaving ? '...' : '+ Nueva skill'}</button>
  </div>

  {#if skills.length === 0 }
    <div class="empty-state card">
      Aun no tienes skills. Agrega la primera.
      <br />
      ↓↓↓ Aquí hay instrucciones ↓↓↓
    </div>
    <div class="markdown-info md-preview card">
      {@html renderMd(getMarkdownHelp())}
    </div>
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
                <button class="btn btn-ghost skill-copy-btn" onclick={() => copySkillContent(skill.content || '')} title="Copiar contenido">
                  ❏
                </button>
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

<style>
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

  .markdown-info {
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 20px;
    color: var(--text);
    font-size: 13px;
    margin-top: 16px;
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

  .skill-copy-btn {
    font-size: 20px;
    padding: 6px 10px;
  }

  .skill-copy-btn:hover {
    color: var(--accent-green);
    background: var(--surface);
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

  .skill-preview {
    max-height: 300px;
    overflow: auto;
  }

  .skill-editor {
    height: auto;
    resize: none;
  }


  @media (max-width: 900px) {
    .skills-grid { display: flex; flex-direction: column; gap: 14px; }
  }
</style>