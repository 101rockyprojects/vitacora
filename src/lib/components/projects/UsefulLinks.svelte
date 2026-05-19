<script lang="ts">
  import type { UsefulLink } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';

  interface Props {
    userId: string;
    links?: UsefulLink[];
  }

  let { userId, links = $bindable([]) }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showLinkForm = $state(false);
  let editingLinkId = $state<string | null>(null);
  let linkForm = $state<UsefulLink>({ title: '', url: '' });
  let saving = $state(false);

  async function saveLink() {
    saving = true;
    if (editingLinkId) {
      await repo.links.update(editingLinkId, linkForm);
    } else {
      await repo.links.insert(linkForm);
      await awardXP(userId, 'work', 'useful_link_added', XP_VALUES.useful_link_added);
    }
    linkForm = { title: '', url: '' };
    editingLinkId = null;
    showLinkForm = false;
    const { data } = await repo.links.list();
    links = data || [];
    saving = false;
  }

  async function deleteLink(id: string) {
    if (!confirm('¿Eliminar link?')) return;
    await repo.links.remove(id);
    const { data } = await repo.links.list();
    links = data || [];
  }

  function editLink(link: UsefulLink) {
    editingLinkId = link.id || null;
    linkForm = { ...link };
    showLinkForm = true;
  }

  export function openNewLink() {
    editingLinkId = null;
    linkForm = { title: '', url: '' };
    showLinkForm = true;
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { editingLinkId = null; linkForm = { title: '', url: '' }; showLinkForm = true; }}>+ Agregar link</button>
  </div>
  <div class="links-list">
    {#each links as l}
      <div class="link-item card responsive-link">
        <div class="rc-icon">
          <a href={l.url} target="_blank" class="link-anchor" aria-label="Abrir {l.title}">
            <span class="link-icon" aria-hidden="true">🔗</span>
          </a>
        </div>
        <div class="rc-content">
          <div class="link-info">
            <a href={l.url} target="_blank" class="link-title">{l.title}</a>
            <div class="link-url">{l.url}</div>
          </div>
        </div>
        <div class="rc-actions">
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

{#if showLinkForm}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) showLinkForm = false; }}
    onkeydown={(e) => { if (e.key === 'Escape') showLinkForm = false; }}
    role="presentation"
  >
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="link-form-title">
      <h3 id="link-form-title">{editingLinkId ? 'Editar link útil' : 'Nuevo link útil'}</h3>
      <form onsubmit={(e) => { e.preventDefault(); saveLink(); }}>
        <div class="form-group">
          <label for="link-title">Título</label>
          <input id="link-title" bind:value={linkForm.title} placeholder="Nombre del recurso" />
        </div>
        <div class="form-group">
          <label for="link-url">URL</label>
          <input id="link-url" type="url" bind:value={linkForm.url} placeholder="https://..." />
        </div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick={() => showLinkForm = false}>Cancelar</button>
          <button type="submit" class="btn btn-primary" disabled={saving}>{saving ? '...' : 'Guardar'}</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .links-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(500px, 1fr)); gap: 12px; }

  .link-anchor {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: var(--radius);
    background: var(--bg3);
    border: 1px solid var(--border);
    transition: all var(--transition);
    text-decoration: none;
  }

  .link-anchor:hover, .link-anchor:focus {
    background: var(--surface);
    border-color: var(--accent-green);
    outline: none;
  }

  .link-anchor:focus-visible {
    box-shadow: 0 0 0 2px var(--accent-green);
  }

  .link-icon { font-size: 18px; }

  .link-info { flex: 1; min-width: 0; }
  .link-title { 
    display: block;
    font-weight: 600; 
    font-size: 14px; 
    color: var(--accent-green); 
    line-height: 1.4;
    text-decoration: none;
    transition: color var(--transition);
  }

  .link-title:hover, .link-title:focus {
    color: var(--accent-yellow);
    text-decoration: underline;
  }

  .link-title:focus-visible {
    outline: 2px solid var(--accent-yellow);
    outline-offset: 2px;
  }

  .link-url { 
    display: block;
    font-size: 12px; 
    color: var(--text3); 
    font-family: var(--font-mono);
    margin-top: 4px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  @media (min-width: 769px) {
    .responsive-link { display: flex; gap: 14px; align-items: center; }
    .responsive-link .rc-content { display: block; text-overflow: clip; }
    .responsive-link .rc-actions { display: flex; gap: 6px; flex-shrink: 0; }
  }

  @media (max-width: 768px) {
    .responsive-link { position: relative; display: flex; flex-direction: column; gap: 10px; align-items: center; }
    .responsive-link .rc-icon { width: 100%; }
    .responsive-link .rc-content { flex: 1; width: 100%; }
    .responsive-link .rc-actions { position: absolute; right: 12px; display: flex; }
    .links-list { grid-template-columns: 1fr; gap: 12px; }
    .link-anchor {
      width: 44px;
      height: 44px;
    }
    .link-title {
      font-size: 15px;
    }
    .link-url {
      font-size: 11px;
      white-space: normal;
      word-break: break-all;
    }
  }
</style>