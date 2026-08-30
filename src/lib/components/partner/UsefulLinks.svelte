<script lang="ts">
  import { page } from '$app/state';
  import { createRepository } from '$lib/services/repository';
  import type { CoupleLink } from '$lib/types';

  interface Props {
    userId: string;
  }

  let { userId }: Props = $props();
  const repo = $derived(createRepository(userId));

  let links = $state<CoupleLink[]>([]);
  let initialized = $state(false);
  let showForm = $state(false);
  let editingLink = $state<CoupleLink | null>(null);
  let newLinkUrl = $state('');
  let newLinkTitle = $state('');
  let newLinkDescription = $state('');
  let newLinkImage = $state('');
  let saving = $state(false);
  let fetching = $state(false);

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadLinks();
    }
  });

  async function loadLinks() {
    const { data, error } = await repo.coupleLinks.list();
    if (error) {
      console.error('Error loading couple links:', error);
    }
    links = data || [];
  }

  async function fetchMetadata(url?: string) {
    const target = (url || newLinkUrl).trim();
    if (!target) return;
    fetching = true;
    try {
      const response = await fetch(`/api/og?url=${encodeURIComponent(target)}`);
      const metadata = await response.json();
      newLinkTitle = metadata.title || target;
      newLinkDescription = metadata.description || '';
      newLinkImage = metadata.image || '';
    } catch (error) {
      console.error('Failed to fetch metadata:', error);
    }
    fetching = false;
  }

  let fetchDebounce: ReturnType<typeof setTimeout> | null = null;

  function onUrlInput(value: string) {
    newLinkUrl = value;
    newLinkTitle = '';
    newLinkDescription = '';
    newLinkImage = '';
    if (fetchDebounce) clearTimeout(fetchDebounce);
    if (value.trim().startsWith('http')) {
      fetchDebounce = setTimeout(() => fetchMetadata(value), 800);
    }
  }

  async function saveLink() {
    if (!newLinkUrl.trim()) return;
    saving = true;
    if (!newLinkTitle && !fetching) {
      await fetchMetadata();
    }
    if (editingLink?.id) {
      const { error } = await repo.coupleLinks.update(editingLink.id, {
        url: newLinkUrl.trim(),
        title: newLinkTitle || newLinkUrl,
        description: newLinkDescription,
        og_image: newLinkImage
      });
      if (error) {
        console.error('Error updating link:', error);
        saving = false;
        return;
      }
    } else {
      const { error } = await repo.coupleLinks.insert({
        url: newLinkUrl.trim(),
        title: newLinkTitle || newLinkUrl,
        description: newLinkDescription,
        og_image: newLinkImage
      });
      if (error) {
        console.error('Error saving link:', error);
        saving = false;
        return;
      }
    }
    newLinkUrl = '';
    newLinkTitle = '';
    newLinkDescription = '';
    newLinkImage = '';
    editingLink = null;
    showForm = false;
    await loadLinks();
    saving = false;
  }

  function editLink(link: CoupleLink) {
    editingLink = link;
    newLinkUrl = link.url;
    newLinkTitle = link.title || '';
    newLinkDescription = link.description || '';
    newLinkImage = link.og_image || '';
    showForm = true;
  }

  function openNewForm() {
    editingLink = null;
    newLinkUrl = '';
    newLinkTitle = '';
    newLinkDescription = '';
    newLinkImage = '';
    showForm = true;
  }

  async function deleteLink(id: string) {
    if (!confirm('¿Eliminar este enlace?')) return;
    await repo.coupleLinks.remove(id);
    await loadLinks();
  }

  function copyShareUrl(link: CoupleLink) {
    const baseUrl = window.location.origin;
    const shareUrl = `${baseUrl}/partner?link=${link.id}`;
    navigator.clipboard.writeText(shareUrl);
  }
</script>

<div class="couple-links-section fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">🔗 Couple Links</h2>
      <div class="section-subtitle">Enlaces compartidos</div>
    </div>
    <button class="btn btn-primary" onclick={openNewForm}>+ Nuevo enlace</button>
  </div>

  {#if links.length === 0}
    <div class="empty-state card">
      Comiencen a compartir enlaces importantes ✨
    </div>
  {:else}
    <div class="links-grid">
      {#each links as link (link.id)}
        <div class="link-card card">
          {#if link.og_image}
            <div class="link-image">
              <img src={link.og_image} alt={link.title} />
            </div>
          {/if}
          <div class="link-content">
            <h3 class="link-title">{link.title}</h3>
            {#if link.description}
              <p class="link-description">{link.description}</p>
            {/if}
            <a href={link.url} target="_blank" rel="noreferrer" class="link-url">
              {new URL(link.url).hostname}
            </a>
          </div>
          <div class="link-actions">
            <button class="action-btn" onclick={() => copyShareUrl(link)} title="Copiar enlace compartible">🔗</button>
            <button class="action-btn" onclick={() => editLink(link)} title="Editar">🖋</button>
            <button class="action-btn delete" onclick={() => deleteLink(link.id!)} title="Eliminar">✕</button>
          </div>
        </div>
      {/each}
    </div>
  {/if}

  {#if showForm}
    <div class="modal-backdrop" role="presentation" onclick={(e) => {
      if (e.target === e.currentTarget) showForm = false;
    }}>
      <div class="modal" role="dialog">
        <h3>{editingLink ? 'Editar enlace' : 'Nuevo enlace compartido'}</h3>
        <div class="form-group">
          <label for="link-url">URL</label>
          <div class="url-input-group">
            <input
              id="link-url"
              value={newLinkUrl}
              oninput={(e) => onUrlInput((e.target as HTMLInputElement).value)}
              placeholder="https://example.com"
              type="url"
            />
            <button
              class="btn btn-secondary"
              onclick={() => fetchMetadata()}
              disabled={fetching || !newLinkUrl.trim()}
            >
              {fetching ? '...' : 'Obtener'}
            </button>
          </div>
        </div>
        <div class="form-group">
          <label for="link-title">Título</label>
          <input
            id="link-title"
            bind:value={newLinkTitle}
            placeholder="Título del enlace"
          />
        </div>
        <div class="form-group">
          <label for="link-description">Descripción</label>
          <textarea
            id="link-description"
            bind:value={newLinkDescription}
            placeholder="Descripción"
            rows="3"
          ></textarea>
        </div>
        {#if newLinkImage}
          <div class="form-group">
            <span>Imagen OG</span>
            <div class="og-preview">
              <img src={newLinkImage} alt="OG Preview" />
            </div>
          </div>
        {/if}
        <div class="form-actions">
          <button class="btn btn-secondary" onclick={() => { showForm = false; editingLink = null; }}>Cancelar</button>
          <button
            class="btn btn-primary"
            onclick={saveLink}
            disabled={saving || !newLinkUrl.trim()}
          >
            {saving ? '...' : 'Guardar'}
          </button>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .couple-links-section {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .links-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(min(250px, 100%), 1fr));
    gap: 16px;
  }

  .link-card {
    display: flex;
    flex-direction: column;
    overflow: hidden;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .link-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
  }

  .link-image {
    width: 100%;
    height: 160px;
    overflow: hidden;
    background: var(--bg3);
  }

  .link-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .link-content {
    padding: 12px;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .link-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
    margin: 0;
    line-height: 1.4;
  }

  .link-description {
    font-size: 12px;
    color: var(--text2);
    margin: 0;
    line-height: 1.4;
  }

  .link-url {
    font-size: 11px;
    color: var(--accent-blue);
    text-decoration: none;
    margin-top: auto;
  }

  .link-url:hover {
    text-decoration: underline;
  }

  .link-actions {
    display: flex;
    gap: 8px;
    padding: 8px 12px;
    border-top: 1px solid var(--border);
    justify-content: flex-end;
  }

  .action-btn {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 14px;
    padding: 4px 8px;
    color: var(--text2);
    transition: color 0.2s;
  }

  .action-btn:hover {
    color: var(--text);
  }

  .action-btn.delete:hover {
    color: var(--accent-red);
  }

  .url-input-group {
    display: flex;
    gap: 8px;
  }

  .url-input-group input {
    flex: 1;
  }

  .og-preview {
    width: 100%;
    height: 160px;
    overflow: hidden;
    background: var(--bg3);
    border-radius: 4px;
  }

  .og-preview img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .empty-state {
    text-align: center;
    padding: 40px 20px;
    color: var(--text2);
  }

  .form-actions {
    display: flex;
    gap: 12px;
    justify-content: flex-end;
    margin-top: 20px;
  }
</style>
