<script lang="ts">
  import { page } from "$app/state";
  import { createRepository } from "$lib/services/repository";
  import {
    PALETTES,
    SECTIONS,
    TABS,
    orderedTabs,
    readSettings,
    tabKey,
    type SectionId,
    type TabGroup,
    type VitacoraSettings,
  } from "$lib/settings";

  const GROUPS: { id: TabGroup; label: string }[] = [
    { id: "goals", label: "Visión & Metas" },
    { id: "projects", label: "Proyectos" },
    { id: "partner", label: "Partner" },
  ];

  const user = $derived(page.data.user);
  const saved = readSettings(page.data.user);

  let draft = $state<VitacoraSettings>(structuredClone(saved));
  let email = $state(page.data.user?.email ?? "");
  let saving = $state(false);
  let error = $state("");
  let confirmDialog: HTMLDialogElement | null = $state(null);
  let deleteDialog: HTMLDialogElement | null = $state(null);
  let currentPassword = $state("");
  let newPassword = $state("");
  let confirmPassword = $state("");
  let pwSaving = $state(false);
  let pwError = $state("");
  let pwMessage = $state("");
  let deleting = $state(false);
  let deleteError = $state("");

  const emailChanged = $derived(
    email.trim() !== "" && email.trim() !== user?.email,
  );

  const passwordChecks = $derived([
    { label: "Mínimo 6 caracteres", ok: newPassword.length >= 6 },
    {
      label: "Distinta a la contraseña actual",
      ok: newPassword !== "" && newPassword !== currentPassword,
    },
    {
      label: "La confirmación coincide",
      ok: confirmPassword !== "" && confirmPassword === newPassword,
    },
  ]);

  const passwordValid = $derived(
    currentPassword !== "" && passwordChecks.every((check) => check.ok),
  );

  async function changePassword() {
    if (!user?.email || !passwordValid) return;
    pwSaving = true;
    pwError = "";
    pwMessage = "";

    const repo = createRepository(user.id);
    const { error: authError } = await repo.auth.signInWithPassword(
      user.email,
      currentPassword,
    );
    if (authError) {
      pwError = "La contraseña actual no es correcta.";
      pwSaving = false;
      return;
    }

    const { error: updateError } = await repo.auth.updatePassword(newPassword);
    pwSaving = false;
    if (updateError) {
      pwError = updateError.message;
      return;
    }
    currentPassword = "";
    newPassword = "";
    confirmPassword = "";
    pwMessage = "Contraseña actualizada.";
  }

  async function deleteAccount() {
    if (!user) return;
    deleting = true;
    deleteError = "";

    const repo = createRepository(user.id);
    const { error: rpcError } = await repo.auth.deleteAccount();
    if (rpcError) {
      deleteError = rpcError.message;
      deleting = false;
      return;
    }
    await repo.auth.signOut();
    location.href = "/auth";
  }

  function discard() {
    draft = structuredClone(saved);
    email = user?.email ?? "";
  }

  function toggleSection(id: SectionId) {
    draft.sections[id] = !draft.sections[id];
  }

  function toggleTab(group: TabGroup, id: string) {
    const key = tabKey(group, id);
    draft.hidden_tabs = draft.hidden_tabs.includes(key)
      ? draft.hidden_tabs.filter((hidden) => hidden !== key)
      : [...draft.hidden_tabs, key];
  }

  function moveTab(group: TabGroup, id: string, dir: -1 | 1) {
    const order = draft.tab_order[group];
    const index = order.indexOf(id);
    const target = index + dir;
    if (index < 0 || target < 0 || target >= order.length) return;
    [order[index], order[target]] = [order[target], order[index]];
  }

  async function apply() {
    if (!user) return;
    saving = true;
    error = "";

    const repo = createRepository(user.id);
    const { error: metaError } = await repo.auth.updateUser({
      vitacora: { ...draft, display_name: draft.display_name.trim() },
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
    location.reload();
  }
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
          <input
            id="display-name"
            bind:value={draft.display_name}
            placeholder="Tu nombre"
            autocomplete="nickname"
          />
        </div>
        <div class="form-group">
          <label for="email">Email</label>
          <input
            id="email"
            type="email"
            bind:value={email}
            autocomplete="email"
          />
        </div>
      </div>
      {#if emailChanged}
        <p class="hint">
          Te enviaremos un correo para confirmar el nuevo email.
        </p>
      {/if}
    </section>

    <section class="card settings-card" aria-labelledby="theme-title">
      <h3 id="theme-title">Tema</h3>
      <div class="palette-list" role="radiogroup" aria-labelledby="theme-title">
        {#each PALETTES as palette}
          <label
            class="palette-option"
            class:active={draft.palette === palette.id}
            data-palette={palette.id}
          >
            <input
              class="sr-only"
              type="radio"
              name="palette"
              value={palette.id}
              bind:group={draft.palette}
            />
            <span class="palette-swatch" aria-hidden="true"></span>
            {palette.label}
          </label>
        {/each}
      </div>
      <br />
      <h3 id="preview-title">Vista previa</h3>
      <div class="preview" data-palette={draft.palette}>
        <nav class="preview-sidebar" aria-label="Vista previa del menú">
          <div class="preview-logo">
            <span class="logo-icon" aria-hidden="true">◈</span>
            <span class="logo-text">VitaCora</span>
          </div>
          <br class="separator" />
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

    <section class="card settings-card" aria-labelledby="sections-title">
      <h3 id="sections-title">Secciones</h3>
      <div class="toggle-list">
        {#each SECTIONS as section}
          {@const enabled = draft.sections[section.id]}
          <button
            type="button"
            role="switch"
            aria-checked={enabled}
            class="toggle-row"
            class:off={!enabled}
            onclick={() => toggleSection(section.id)}
          >
            <span class="toggle-label">{section.icon} {section.label}</span>
            <span class="toggle-mark" aria-hidden="true"
              >{enabled ? "✓" : "✕"}</span
            >
          </button>
        {/each}
      </div>
    </section>

    <section class="card settings-card" aria-labelledby="tabs-title">
      <h3 id="tabs-title">Pestañas</h3>
      <div class="groups">
        {#each GROUPS as group}
          <div class="tab-group">
            <h4>{group.label}</h4>
            <div class="toggle-list">
              {#each draft.tab_order[group.id] as id, index (id)}
                {@const tab = TABS[group.id].find((t) => t.id === id)}
                {#if tab}
                  {@const enabled = !draft.hidden_tabs.includes(
                    tabKey(group.id, id),
                  )}
                  <div class="tab-row">
                    <button
                      type="button"
                      role="switch"
                      aria-checked={enabled}
                      class="toggle-row"
                      class:off={!enabled}
                      onclick={() => toggleTab(group.id, id)}
                    >
                      <span class="toggle-label">{tab.icon} {tab.label}</span>
                      <span class="toggle-mark" aria-hidden="true"
                        >{enabled ? "✓" : "✕"}</span
                      >
                    </button>
                    <div class="row-actions">
                      <button
                        type="button"
                        class="move-btn"
                        onclick={() => moveTab(group.id, id, -1)}
                        disabled={index === 0}
                        aria-label={`Subir ${tab.label}`}>↑</button
                      >
                      <button
                        type="button"
                        class="move-btn"
                        onclick={() => moveTab(group.id, id, 1)}
                        disabled={index ===
                          draft.tab_order[group.id].length - 1}
                        aria-label={`Bajar ${tab.label}`}>↓</button
                      >
                    </div>
                  </div>
                {/if}
              {/each}
            </div>
          </div>
        {/each}
      </div>
    </section>

    {#if error}
      <p class="error" role="alert">{error}</p>
    {/if}

    <div class="form-actions apply">
      <button type="button" class="btn btn-secondary" onclick={discard}
        >Descartar</button
      >
      <button
        type="button"
        class="btn btn-primary"
        onclick={() => confirmDialog?.showModal()}
      >
        Aplicar cambios
      </button>
    </div>

    <section class="card settings-card" aria-labelledby="security-title">
      <h3 id="security-title">Seguridad</h3>
      <form
        class="password-form"
        onsubmit={(event) => {
          event.preventDefault();
          changePassword();
        }}
      >
        <div class="form-group">
          <label for="current-password">Contraseña actual</label>
          <input
            id="current-password"
            type="password"
            bind:value={currentPassword}
            autocomplete="current-password"
          />
        </div>
        <div class="grid-2">
          <div class="form-group">
            <label for="new-password">Nueva contraseña</label>
            <input
              id="new-password"
              type="password"
              bind:value={newPassword}
              autocomplete="new-password"
            />
          </div>
          <div class="form-group">
            <label for="confirm-password">Confirmar nueva contraseña</label>
            <input
              id="confirm-password"
              type="password"
              bind:value={confirmPassword}
              autocomplete="new-password"
            />
          </div>
        </div>
        <ul class="checklist" aria-label="Requisitos de la contraseña">
          {#each passwordChecks as check}
            <li class:ok={check.ok}>
              <span class="check-mark" aria-hidden="true"
                >{check.ok ? "✓" : "✕"}</span
              >
              {check.label}
            </li>
          {/each}
        </ul>
        {#if pwError}
          <p class="error" role="alert">{pwError}</p>
        {/if}
        {#if pwMessage}
          <p class="success" role="status">{pwMessage}</p>
        {/if}
        <div class="form-actions">
          <button
            type="submit"
            class="btn btn-primary"
            disabled={!passwordValid || pwSaving}
          >
            {pwSaving ? "Actualizando…" : "Cambiar contraseña"}
          </button>
        </div>
      </form>
    </section>

    <fieldset class="danger-zone">
      <legend class="font-extrabold">Zona sensible</legend>
      <p class="text-lg font-semibold">
        Eliminar tu cuenta borra de forma permanente tu perfil y todos tus
        datos. No se puede recuperar nada y tendrás que registrarte de nuevo.
      </p>
      <button
        type="button"
        class="btn btn-danger"
        onclick={() => deleteDialog?.showModal()}
      >
        ELIMINAR CUENTA
      </button>
    </fieldset>
  {/if}
</div>

<dialog
  bind:this={confirmDialog}
  class="modal confirm-dialog"
  aria-labelledby="confirm-title"
>
  <h3 id="confirm-title">¿Aplicar cambios?</h3>
  <p>Se guardará tu configuración y la página se recargará.</p>
  {#if emailChanged}
    <p class="hint">Se enviará un correo de confirmación a {email.trim()}.</p>
  {/if}
  {#if error}
    <p class="error" role="alert">{error}</p>
  {/if}
  <div class="form-actions">
    <button
      type="button"
      class="btn btn-secondary"
      onclick={() => confirmDialog?.close()}>Cancelar</button
    >
    <button
      type="button"
      class="btn btn-primary"
      onclick={apply}
      disabled={saving}
    >
      {saving ? "Guardando…" : "Confirmar"}
    </button>
  </div>
</dialog>

<dialog
  bind:this={deleteDialog}
  class="modal confirm-dialog danger-dialog"
  aria-labelledby="delete-title"
>
  <h3 id="delete-title">¿Eliminar tu cuenta?</h3>
  <p>
    Se borrarán tu perfil, metas, libros, tareas, gastos, recuerdos y tu
    conexión con tu partner. No se puede recuperar ninguna información y tendrás
    que registrarte de nuevo.
  </p>
  {#if deleteError}
    <p class="error" role="alert">{deleteError}</p>
  {/if}
  <div class="form-actions">
    <button
      type="button"
      class="btn btn-secondary"
      onclick={() => deleteDialog?.close()}>Cancelar</button
    >
    <button
      type="button"
      class="btn btn-danger"
      onclick={deleteAccount}
      disabled={deleting}
    >
      {deleting ? "Eliminando…" : "Eliminar definitivamente"}
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
    cursor: pointer;
    transition: all var(--transition);
  }

  .palette-option:hover {
    border-color: var(--surface2);
    color: var(--text);
  }

  .palette-option.active {
    border-color: var(--accent-green);
    color: var(--text);
    box-shadow: inset 0 0 0 1px var(--accent-green);
  }

  .palette-option:focus-within {
    outline: 2px solid var(--accent);
    outline-offset: 2px;
  }

  .palette-swatch {
    width: 18px;
    height: 18px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--bg2) 50%, var(--accent) 50%);
    border: 3px solid var(--border);
  }

  .toggle-list {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .toggle-row {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 14px;
    border-radius: var(--radius-sm);
    border: 1px solid var(--border);
    background: var(--bg2);
    color: var(--text);
    font-size: 14px;
    text-align: left;
    cursor: pointer;
    transition: all var(--transition);
  }

  .toggle-row:hover {
    border-color: var(--surface2);
  }

  .toggle-row:focus-visible {
    outline: 2px solid var(--accent-green);
    outline-offset: 2px;
  }

  .toggle-row.off {
    border-style: dashed;
  }

  .toggle-label {
    transition: opacity var(--transition);
  }

  .toggle-row.off .toggle-label {
    opacity: 0.45;
  }

  .toggle-mark {
    width: 22px;
    height: 22px;
    flex-shrink: 0;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    font-size: 12px;
    font-weight: 700;
    color: var(--text-dark);
    background: color-mix(in srgb, var(--accent-green) 80%, transparent);
  }

  .toggle-row.off .toggle-mark {
    color: var(--accent-red);
    background: color-mix(in srgb, var(--accent-red) 18%, transparent);
  }

  .tab-row {
    display: flex;
    align-items: center;
    gap: 8px;
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
    color: var(--accent);
    border-color: var(--accent);
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
    background: var(--bg);
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
    display: flex;
    align-items: center;
    gap: 4px;
    font-weight: 700;
    color: var(--accent);
  }

  .logo-icon {
    font-size: 15px;
    color: var(--accent);
  }

  .logo-text {
    font-family: var(--font-display);
    font-size: 15px;
    font-weight: 800;
    color: var(--text);
    letter-spacing: -0.03em;
  }

  .separator {
    background: 1px solid var(--border);
    margin-bottom: 6px;
  }

  .preview-nav-item {
    padding: 6px;
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

  .confirm-dialog {
    margin: auto;
  }

  .confirm-dialog .form-actions {
    justify-content: center;
  }

  .success {
    color: var(--accent-green);
    font-size: 13px;
    margin-bottom: 12px;
  }

  .checklist {
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 4px;
    margin: 4px 0 8px;
    font-size: 13px;
    color: var(--text2);
  }

  .check-mark {
    display: inline-block;
    width: 16px;
    font-weight: 700;
    color: var(--accent-red);
  }

  .checklist li.ok .check-mark {
    color: var(--accent-green);
  }

  .apply {
    margin-bottom: 20px;
  }

  .danger-zone {
    border: 1px solid var(--accent-red);
    border-radius: var(--radius-lg);
    padding: 20px;
    margin-bottom: 16px;
    color: var(--accent-red);
  }

  .danger-zone legend {
    padding: 0 8px;
    font-family: var(--font-mono);
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--accent-red);
  }

  .danger-zone p {
    font-size: 13px;
    margin-bottom: 12px;
  }

  .danger-zone .btn-danger {
    color: var(--text-dark);
  }

  .danger-dialog {
    border-color: var(--accent-red);
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
