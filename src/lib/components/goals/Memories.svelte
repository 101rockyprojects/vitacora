<script lang="ts">
  import type { MemoryPhoto } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { onDestroy, tick } from 'svelte';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import 'gridstack/dist/gridstack.min.css';

  interface Props {
    userId: string;
    memories?: MemoryPhoto[];
    onRefresh?: () => void;
  }

  let { userId, memories = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));
  const memory_size_limit_kb = 999;

  let showMemForm = $state(false);
  let memForm = $state<MemoryPhoto>({ date: '', description: '' });
  let memFile = $state<File | null>(null);
  let memImageMode = $state<'file' | 'link'>('file');
  let memImageLink = $state('');
  let memGridEl = $state<HTMLElement | null>(null);
  let memGrid = $state<any>(null);
  let saving = $state(false);

  $effect(() => {
    if (typeof window === 'undefined' || !memGridEl) return;
    const count = memories.length;
    void initMemGrid();
  });

  async function initMemGrid() {
    if (!memGridEl) return;
    await tick();
    memGrid?.destroy(false);
    const { GridStack } = await import('gridstack');
    memGrid = GridStack.init(
      {
        column: 12,
        cellHeight: 80,
        margin: 10,
        float: true,
        animate: true,
        draggable: { handle: '.mem-drag' },
        resizable: { handles: 'se', autoHide: false },
        alwaysShowResizeHandle: true
      },
      memGridEl as any
    );
    if (window.innerWidth <= 640) {
      memGrid.column(1, 'moveScale');
    }
  }

  onDestroy(() => {
    if (memGrid) {
      memGrid.destroy(false);
      memGrid = null;
    }
  });

  function clamp(n: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, n));
  }

  function onMemoryImageLoad(memId: string, e: Event) {
    if (!memGridEl || !memGrid) return;
    const img = e.currentTarget as HTMLImageElement | null;
    if (!img || !img.naturalWidth || !img.naturalHeight) return;
    const ratio = img.naturalWidth / img.naturalHeight;
    let w = 4;
    let h = 4;
    if (ratio >= 1.35) { w = 6; h = 3; }
    else if (ratio <= 0.8) { w = 3; h = 6; }
    w = clamp(w, 3, 6);
    h = clamp(h, 3, 6);
    const el = memGridEl.querySelector(`[data-mem-id="${memId}"]`) as HTMLElement | null;
    if (!el) return;
    memGrid.update(el, { w, h });
  }

  async function saveMem() {
    saving = true;
    let photo_path = '';
    const link = memImageLink.trim();
    if (memImageMode === 'link' && link) {
      photo_path = link;
    } else if (memImageMode === 'file' && memFile) {
      const ext = memFile.name.split('.').pop();
      const fileSizeKb = memFile.size / 1024;
      if (fileSizeKb > memory_size_limit_kb) {
        alert('El archivo es demasiado grande. El tamaño máximo es de 999 KB.');
        saving = false;
        return;
      }
      const path = `${userId}/${Date.now()}.${ext}`;
      const { data, error } = await repo.storage.uploadMemory(path, memFile);
      if (error || !data) {
        alert('No se pudo subir la imagen. ¿Existe el bucket "memories" y sus policies?');
        console.error('Upload error:', error?.message?.trim() || '');
        saving = false;
        return;
      }
      photo_path = path;
    }

    await repo.memories.insert({ ...memForm, photo_url: photo_path });
    await awardXP(userId, 'social', 'memory_added', XP_VALUES.memory_added);

    memForm = { date: '', description: '' };
    memFile = null;
    memImageLink = '';
    memImageMode = 'file';
    showMemForm = false;

    const { data } = await repo.memories.list();
    memories = data || [];
    saving = false;
  }

  async function deleteMem(id: string) {
    if (!confirm('¿Eliminar recuerdo?')) return;
    await repo.memories.remove(id);
    await repo.storage.getMemorySignedUrl(`${userId}/${id}`).then(url => {
      if (url) repo.storage.deleteMemory(`${userId}/${id}`);
    });
    const { data } = await repo.memories.list();
    memories = data || [];
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => {
      memForm = { date: new Date().toISOString().split('T')[0], description: '' };
      memFile = null;
      memImageLink = '';
      memImageMode = 'file';
      showMemForm = true;
    }}>+ Agregar recuerdo</button>
  </div>
  {#if memories.length === 0}
    <div class="empty-state card">Crea tu álbum de recuerdos 📸</div>
  {:else}
    <div class="grid-stack memory-grid" bind:this={memGridEl}>
      {#each memories as mem (mem.id)}
        <div
          class="grid-stack-item mem-drag" aria-label="Drag"
          data-mem-id={mem.id}
          data-gs-w="4"
          data-gs-h="4"
          data-gs-min-w="4"
          data-gs-min-h="4"
          data-gs-max-w="6"
          data-gs-max-h="6"
        >
          <div class="grid-stack-item-content">
            <div class="mem-card">
              {#if mem.photo_url}
                <img src={mem.photo_url} alt={mem.description} class="mem-photo" onload={(e) => onMemoryImageLoad(mem.id!, e)} />
              {:else}
                <div class="mem-placeholder">📷</div>
              {/if}
              <div class="mem-info">
                <div class="mem-date">{new Date(mem.date).toLocaleDateString('es-ES')}</div>
                <div class="mem-desc">{mem.description}</div>
              </div>
              <button class="mem-delete btn" onclick={() => deleteMem(mem.id!)}>✕</button>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

{#if showMemForm}
  <div class="modal-backdrop" role="presentation" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showMemForm = false
        }
      }} onkeydown={(e) => e.key === 'Escape' && (showMemForm = false)}>
    <div class="modal" role="document">
      <h3>Nuevo recuerdo</h3>
      <div class="form-group"><label for="mem-date">Fecha</label><input id="mem-date" type="date" bind:value={memForm.date} /></div>
      <div class="form-group"><label for="mem-desc">Descripción</label><textarea id="mem-desc" bind:value={memForm.description} rows="2"></textarea></div>
      <div class="form-group">
        <label for="mem-file">Imagen</label>
        <div class="mem-upload-toggle" id="mem-image-mode">
          <button type="button" class="toggle-pill" class:active={memImageMode === 'file'} onclick={() => { memImageMode = 'file'; memImageLink = ''; }}>Archivo</button>
          <button type="button" class="toggle-pill" class:active={memImageMode === 'link'} onclick={() => { memImageMode = 'link'; memFile = null; }}>Link</button>
        </div>

        {#if memImageMode === 'file'}
          <input
            id="mem-file"
            class="file-input"
            type="file"
            accept="image/*"
            onchange={(e) => { const t = e.target as HTMLInputElement; memFile = t.files?.[0] || null; }}
          />
          <div class="file-row">
            <label class="file-btn" for="mem-file">Elegir imagen</label>
            <div class="file-name">{memFile?.name || 'Ningun archivo seleccionado'}</div>
            {#if memFile}
              <button type="button" class="btn btn-ghost" style="font-size:12px;" onclick={() => memFile = null}>Quitar</button>
            {/if}
          </div>
        {:else}
          <input bind:value={memImageLink} placeholder="https://..." />
        {/if}
      </div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showMemForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveMem} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .memory-grid {
    min-height: 300px;
  }

  .mem-card {
    height: 100%;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .mem-photo {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 8px;
  }

  .mem-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--bg3);
    border-radius: 8px;
    font-size: 28px;
  }

  .mem-info {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 25px 10px 15px;
    background: linear-gradient(transparent, rgb(36, 43, 61, 0.75), rgb(36, 43, 61));
    border-radius: 0 0 8px 8px;
  }

  .mem-date {
    font-size: 12px;
    color: var(--text);
    font-family: var(--font-mono);
  }

  .mem-desc {
    font-size: 12px;
    color: white;
    font-weight: 500;
    overflow: hidden;
    line-height: normal;
    text-overflow: ellipsis;
    line-clamp: 2;
  }

  .mem-delete {
    position: absolute;
    padding: 5px 8px;
    top: 4px;
    right: 4px;
    border-radius: var(--radius-lg);
    background: var(--surface);
    color: var(--accent-green);
  }

  @media (min-width: 600px) {
    .mem-card { height: 50%; }
  }
</style>