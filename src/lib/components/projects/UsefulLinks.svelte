<script lang="ts">
  import type { UsefulLink } from '$lib/types';
  import { createRepository } from '$lib/services/repository';

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
    if (editingLinkId) await repo.links.update(editingLinkId, linkForm);
    else await repo.links.insert(linkForm);
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
  .links-list { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }

  .link-item { display: flex; align-items: center; gap: 14px; }
  .link-icon { font-size: 20px; }
  .link-info { flex: 1; }
  .link-title { font-weight: 600; font-size: 14px; color: var(--accent-green); }
  .link-url { font-size: 12px; color: var(--text3); font-family: var(--font-mono); }

  @media (max-width: 600px) {
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