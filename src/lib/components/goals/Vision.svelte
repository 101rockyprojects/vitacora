<script lang="ts">
  import type { UsefulLink } from '$lib/types';

  interface Props {
    visionBoardLink?: UsefulLink | null;
    showVisionLinkForm?: boolean;
    visionLinkMode?: 'image' | 'canva';
    visionLinkInput?: string;
    onSave?: () => void;
    onRefresh?: () => void;
  }

  let { visionBoardLink = $bindable(null), showVisionLinkForm = $bindable(false), visionLinkMode = $bindable('image'), visionLinkInput = $bindable(''), onSave }: Props = $props();

  const motivationalPhrases = [
    "1% better every day",
    "YOU WILL NOT FAIL IF IT IS WORTH IT",
    "DO NOT WASTE YOUR POTENTIAL",
    "¡Commit yourself!",
    "No se trata de por qué peleo sino por quién",
    "¿Cuánto más podríamos avanzar si no tuviéramos que cargar con nuestros miedos a cuestas?",
    "Cuando miro a la cima de la montaña, en mi mente ya he fracasado... es entonces que comienzo a escalar",
  ];
</script>

<div class="vision-section fade-in">
  <div class="vision-board-placeholder card">
    <div class="vb-topbar">
      <div class="vb-label">Vision Board</div>
      <button class="btn btn-secondary" onclick={() => showVisionLinkForm = !showVisionLinkForm}>
        {showVisionLinkForm ? 'Cerrar' : 'Configurar enlace'}
      </button>
    </div>

    {#if showVisionLinkForm}
      <div class="vb-link-form">
        <div class="vb-link-types">
          <button type="button" class="toggle-pill" class:active={visionLinkMode === 'image'} onclick={() => visionLinkMode = 'image'}>
            Imagen
          </button>
          <button type="button" class="toggle-pill" class:active={visionLinkMode === 'canva'} onclick={() => visionLinkMode = 'canva'}>
            Canva embed
          </button>
        </div>
        <input
          class="vb-link-input"
          bind:value={visionLinkInput}
          placeholder={visionLinkMode === 'canva' ? 'https://www.canva.com/design/...' : 'https://...'}
        />
        <div class="vb-link-actions">
          <button class="btn btn-primary" onclick={onSave}>Guardar</button>
        </div>
      </div>
    {/if}

    {#if visionBoardLink?.url}
      {#if visionBoardLink.link_type === 'vision_board_canva'}
        <div class="vb-embed-shell">
          <iframe
            loading="lazy"
            style="position: absolute; width: 100%; height: 100%; top: 0; left: 0; border: none; padding: 0;margin: 0;"
            src={visionBoardLink.url + '?embed'}
            allowfullscreen={true}
            allow="fullscreen"
            title="Vision Board Canva"
          ></iframe>
        </div>
      {:else}
        <img class="vb-image" src={visionBoardLink.url} alt="Vision Board" />
      {/if}
    {:else}
      <div class="vb-inner">
        <span class="vb-icon">🖼️</span>
        <p>Tu Vision Board</p>
      </div>
    {/if}
  </div>

  <div class="phrases-grid">
    {#each motivationalPhrases as phrase, i}
      <div class="phrase-card" style="--i:{i}">
        <span class="phrase-glyph">«</span>
        <p class="phrase-text">{phrase}</p>
        <span class="phrase-glyph">»</span>
      </div>
    {/each}
  </div>
</div>

<style>
  .vision-board-placeholder {
    min-height: 220px;
    margin-bottom: 28px;
    border: 2px dashed var(--border);
    background: var(--bg3);
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .vb-topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
  }

  .vb-label {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--text3);
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }

  .vb-inner {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 200px;
    gap: 8px;
    color: var(--text3);
    font-family: var(--font-mono);
    font-size: 13px;
  }

  .vb-icon { font-size: 40px; }

  .vb-link-form {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .vb-link-types {
    display: inline-flex;
    gap: 6px;
    background: var(--bg3);
    border: 1px solid var(--border);
    border-radius: 999px;
    padding: 4px;
    width: fit-content;
  }

  .vb-link-input {
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--bg2);
    color: var(--text);
    padding: 10px 12px;
    font-size: 13px;
  }

  .vb-link-actions {
    display: flex;
    justify-content: flex-end;
  }

  .vb-image {
    width: 100%;
    height: 100%;
    min-height: 220px;
    border-radius: 10px;
    object-fit: cover;
  }

  .vb-embed-shell {
    position: relative;
    width: 100%;
    height: 0;
    padding-top: 100%;
    padding-bottom: 0;
    box-shadow: 0 2px 8px 0 rgba(63, 69, 81, 0.16);
    margin-top: 1.6em;
    margin-bottom: 0.9em;
    overflow: hidden;
  }

  .phrases-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 12px;
  }

  .phrase-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 14px 18px;
    display: flex;
    align-items: center;
    gap: 10px;
    grid-column: span 1;
    animation: phraseFadeIn 0.4s ease-out calc(var(--i) * 0.05s) both;
  }

  @keyframes phraseFadeIn {
    from {
      opacity: 0;
      transform: translateY(8px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .phrase-glyph {
    font-family: var(--font-display);
    font-size: 20px;
    color: var(--accent-green);
    line-height: 1;
  }

  .phrase-text {
    flex: 1;
    font-family: var(--font-display);
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
    line-height: 1.4;
  }

  @media (max-width: 600px) {
    .phrases-grid { grid-template-columns: 1fr; }
    .phrase-card { flex-direction: column; text-align: center; }
    .phrase-glyph { align-self: flex-start; }
  }
</style>