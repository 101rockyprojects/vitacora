<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { onDestroy } from 'svelte';
  import { createRepository } from '$lib/services/repository';
  import {
    PALETTES,
    SECTIONS,
    TABS,
    orderedTabs,
    readSettings,
    type SectionId,
    type TabGroup,
    type VitacoraSettings
  } from '$lib/settings';

  const GROUPS: { id: TabGroup; label: string }[] = [
    { id: 'goals', label: 'Visión & Metas' },
    { id: 'projects', label: 'Proyectos' },
    { id: 'partner', label: 'Partner' }
  ];

  const user = $derived(page.data.user);
  const saved = readSettings(page.data.user);

  let draft = $state<VitacoraSettings>(structuredClone(saved));
  let email = $state(page.data.user?.email ?? '');
  let saving = $state(false);
  let error = $state('');
  let confirmDialog: HTMLDialogElement | null = $state(null);

  const emailChanged = $derived(email.trim() !== '' && email.trim() !== user?.email);

  function selectPalette(id: string) {
    draft.palette = id;
    if (browser) document.documentElement.dataset.palette = id;
  }

  function resetPalette() {
    if (browser) document.documentElement.dataset.palette = saved.palette;
  }

  function discard() {
    draft = structuredClone(saved);
    email = user?.email ?? '';
    resetPalette();
  }

  function toggleSection(id: SectionId) {
    draft.sections[id] = !draft.sections[id];
  }

  function toggleTab(id: string) {
    draft.hidden_tabs = draft.hidden_tabs.includes(id)
      ? draft.hidden_tabs.filter((tabId) => tabId !== id)
      : [...draft.hidden_tabs, id];
  }

  function moveTab(group: TabGroup, id: string, dir: -1 | 1) {
    const order = draft.tab_order[group];
    const index = order.indexOf(id);
    const target = index + dir;
    if (index < 0 || target < 0 || target >= order.length) return;
    [order[index], order[target]] = [order[target], order[index]];
  }

  function tabDef(group: TabGroup, id: string) {
    return TABS[group].find((tab) => tab.id === id);
  }

  async function apply() {
    if (!user) return;
    saving = true;
    error = '';

    const repo = createRepository(user.id);
    const { error: metaError } = await repo.auth.updateUser({
      vitacora: { ...draft, display_name: draft.display_name.trim() }
    });
    if (metaError) {
      error = metaError.message;
      saving = false;
      return;
    }

    if (emailChanged) {
      const { error: emailError } = await repo.auth.updateEmail(email.trim());
      if (emailError) {
        error = emailError.message;
        saving = false;
        return;
      }
    }

    confirmDialog?.close();
    resetPalette();
    location.reload();
  }

  onDestroy(resetPalette);
</script>

<svelte:head>
  <title>Ajustes | VitaCora</title>
</svelte:head>

<div class="settings-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Ajustes</h2>
      <div class="section-subtitle">Personaliza tu espacio</div>
    </div>
  </div>

  {#if !user}
    <p class="empty-state">Inicia sesión para editar tus ajustes.</p>
  {:else}
    <section class="card settings-card" aria-labelledby="profile-title">
      <h3 id="profile-title">Perfil</h3>
      <div class="grid-2">
        <div class="form-group">
          <label for="display-name">Nombre de usuario</label>
          <input id="display-name" bind:value={draft.display_name} placeholder="Tu nombre" autocomplete="nickname" />
        </div>
        <div class="form-group">
          <label for="email">Email</label>
          <input id="email" type="email" bind:value={email} autocomplete="email" />
        </div>
      </div>
      {#if emailChanged}
        <p class="hint">Te enviaremos un correo para confirmar el nuevo email.</p>
      {/if}
    </section>

    <section class="card settings-card" aria-labelledby="theme-title">
      <h3 id="theme-title">Tema</h3>
      <div class="palette-list" role="radiogroup" aria-labelledby="theme-title">
        {#each PALETTES as palette}
          <label class="palette-option" class:active={draft.palette === palette.id}>
            <input
              class="visually-hidden"
              type="radio"
              name="palette"
              value={palette.id}
              checked={draft.palette === palette.id}
              onchange={() => selectPalette(palette.id)}
            />
            <span class="palette-swatch" data-palette={palette.id} aria-hidden="true"></span>
            {palette.label}
          </label>
        {/each}
      </div>
    </section>

    <section class="card settings-card" aria-labelledby="sections-title">
      <h3 id="sections-title">Secciones</h3>
      <div class="setting-list">
        {#each SECTIONS as section}
          <label class="setting-row">
            <span class="setting-label">{section.icon} {section.label}</span>
            <input
              type="checkbox"
              checked={draft.sections[section.id]}
              onchange={() => toggleSection(section.id)}
              aria-label={`Mostrar ${section.label}`}
            />
          </label>
        {/each}
      </div>
    </section>

    <section class="card settings-card" aria-labelledby="tabs-title">
      <h3 id="tabs-title">Pestañas</h3>
      <div class="groups">
        {#each GROUPS as group}
          <div class="tab-group">
            <h4>{group.label}</h4>
            {#each draft.tab_order[group.id] as id}
              {@const tab = tabDef(group.id, id)}
              {#if tab}
                {@const hidden = draft.hidden_tabs.includes(id)}
                <div class="setting-row" class:hidden>
                  <label class="setting-label">
                    <input
                      type="checkbox"
                      checked={!hidden}
                      onchange={() => toggleTab(id)}
                      aria-label={`Mostrar ${tab.label}`}
                    />
                    {tab.icon} {tab.label}
                  </label>
                  <div class="row-actions">
                    <button
                      type="button"
                      class="move-btn"
                      onclick={() => moveTab(group.id, id, -1)}
                      disabled={draft.tab_order[group.id][0] === id}
                      aria-label={`Subir ${tab.label}`}
                    >↑</button>
                    <button
                      type="button"
                      class="move-btn"
                      onclick={() => moveTab(group.id, id, 1)}
                      disabled={draft.tab_order[group.id][draft.tab_order[group.id].length - 1] === id}
                      aria-label={`Bajar ${tab.label}`}
                    >↓</button>
                  </div>
                </div>
              {/if}
            {/each}
          </div>
        {/each}
      </div>
    </section>

    <section class="card settings-card" aria-labelledby="preview-title">
      <h3 id="preview-title">Vista previa</h3>
      <div class="preview">
        <nav class="preview-sidebar" aria-label="Vista previa del menú">
          <div class="preview-logo">{draft.display_name || 'VitaCora'}</div>
          {#each SECTIONS.filter((section) => draft.sections[section.id]) as section}
            <span class="preview-nav-item">{section.icon} {section.label}</span>
          {/each}
          <span class="preview-nav-item">⚙ Ajustes</span>
        </nav>
        <div class="preview-content">
          {#each GROUPS as group}
            <div class="preview-group">
              <div class="preview-group-title">{group.label}</div>
              <div class="preview-tabs">
                {#each orderedTabs(group.id, draft) as tab}
                  <span class="preview-tab">{tab.icon} {tab.label}</span>
                {:else}
                  <span class="preview-empty">Sin pestañas visibles</span>
                {/each}
              </div>
            </div>
          {/each}
        </div>
      </div>
    </section>

    {#if error}
      <p class="error" role="alert">{error}</p>
    {/if}

    <div class="form-actions">
      <button type="button" class="btn btn-secondary" onclick={discard}>Descartar</button>
      <button type="button" class="btn btn-primary" onclick={() => confirmDialog?.showModal()}>
        Aplicar cambios
      </button>
    </div>
  {/if}
</div>

<dialog bind:this={confirmDialog} class="modal" aria-labelledby="confirm-title">
  <h3 id="confirm-title">¿Aplicar cambios?</h3>
  <p>Se guardará tu configuración y la página se recargará.</p>
  {#if emailChanged}
    <p class="hint">Se enviará un correo de confirmación a {email.trim()}.</p>
  {/if}
  {#if error}
    <p class="error" role="alert">{error}</p>
  {/if}
  <div class="form-actions">
    <button type="button" class="btn btn-secondary" onclick={() => confirmDialog?.close()}>Cancelar</button>
    <button type="button" class="btn btn-primary" onclick={apply} disabled={saving}>
      {saving ? 'Guardando…' : 'Confirmar'}
    </button>
  </div>
</dialog>

<style>
  .settings-page {
    max-width: 900px;
  }

  .settings-card {
    padding: 20px;
    margin-bottom: 16px;
  }

  .settings-card h3 {
    font-size: 16px;
    margin-bottom: 14px;
  }

  .settings-card h4 {
    font-size: 13px;
    color: var(--text2);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    font-family: var(--font-mono);
    margin-bottom: 8px;
  }

  .hint {
    color: var(--text3);
    font-size: 12px;
  }

  .error {
    color: var(--accent-red);
    font-size: 13px;
    margin-bottom: 12px;
  }

  .palette-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .palette-option {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: var(--bg2);
    color: var(--text2);
    font-size: 13px;
    transition: all var(--transition);
  }

  .palette-option:hover {
    border-color: var(--surface2);
    color: var(--text);
  }

  .palette-option.active {
    border-color: var(--accent-green);
    color: var(--text);
  }

  .visually-hidden {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0 0 0 0);
    white-space: nowrap;
    border: 0;
  }

  .palette-option:focus-within {
    outline: 2px solid var(--accent-green);
    outline-offset: 2px;
  }

  .palette-swatch {
    width: 18px;
    height: 18px;
    border-radius: 50%;
    background: var(--surface2);
    border: 3px solid var(--accent-green);
  }

  .setting-list {
    display: flex;
    flex-direction: column;
  }

  .setting-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 8px 0;
    border-bottom: 1px solid var(--border);
    font-size: 14px;
  }

  .setting-row:last-child {
    border-bottom: none;
  }

  .setting-row.hidden {
    opacity: 0.45;
  }

  .setting-label {
    display: inline-flex;
    align-items: center;
    gap: 8px;
  }

  .setting-label input[type='checkbox'] {
    width: 16px;
    height: 16px;
    accent-color: var(--accent-green);
  }

  .row-actions {
    display: inline-flex;
    gap: 4px;
  }

  .move-btn {
    width: 28px;
    height: 28px;
    border-radius: var(--radius-sm);
    border: 1px solid var(--border);
    background: var(--bg3);
    color: var(--text2);
    transition: all var(--transition);
  }

  .move-btn:hover:not(:disabled) {
    color: var(--accent-green);
    border-color: var(--accent-green);
  }

  .move-btn:disabled {
    opacity: 0.35;
    cursor: not-allowed;
  }

  .groups {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
  }

  @media (max-width: 900px) {
    .groups {
      grid-template-columns: 1fr;
    }
  }

  .preview {
    display: flex;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    min-height: 180px;
  }

  .preview-sidebar {
    width: 180px;
    flex-shrink: 0;
    background: var(--bg2);
    border-right: 1px solid var(--border);
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    font-size: 12px;
    color: var(--text2);
  }

  .preview-logo {
    font-weight: 700;
    color: var(--accent-green);
    margin-bottom: 8px;
  }

  .preview-nav-item {
    padding: 4px 6px;
    border-radius: var(--radius-sm);
  }

  .preview-content {
    flex: 1;
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .preview-group-title {
    font-size: 11px;
    color: var(--text3);
    margin-bottom: 4px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }

  .preview-tabs {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
  }

  .preview-tab {
    padding: 4px 8px;
    border-radius: var(--radius-sm);
    background: var(--surface);
    border: 1px solid var(--border);
    font-size: 11px;
    color: var(--text2);
  }

  .preview-empty {
    font-size: 11px;
    color: var(--text3);
  }

  @media (max-width: 640px) {
    .preview {
      flex-direction: column;
    }

    .preview-sidebar {
      width: 100%;
      border-right: none;
      border-bottom: 1px solid var(--border);
    }
  }
</style>
