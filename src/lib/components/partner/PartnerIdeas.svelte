<script lang="ts">
  import Toast from '$lib/components/Toast.svelte';
  import type { DateIdea } from '$lib/types';
  import { createRepository } from '$lib/services/repository';

  interface Props {
    userId: string;
  }

  let { userId }: Props = $props();
  const repo = $derived(createRepository(userId));

  let ideas = $state<DateIdea[]>([]);
  let partnerIdeas = $state<DateIdea[]>([]);
  let partnerProfile = $state<{ id: string; email: string } | null>(null);
  let initialized = $state(false);
  let showForm = $state(false);
  let newIdea = $state<DateIdea>({ idea_text: '', status: 'pending' });
  let randomPick = $state<DateIdea | null>(null);
  let showRandom = $state(false);
  let saving = $state(false);
  let copyToast = $state(false);
  let copyToastTimer: ReturnType<typeof setTimeout> | null = $state(null);

  const builtInIdeas = [
    'Dibujos Locos',
    'Vision Board',
    'Recreate whatsapp sticker',
    'Google Earth',
    'Cosas que nos gustan y cosas que no.',
    'Scaperoom Virtual',
    'Them bombs',
    'Trivia personalizada',
    'Reto plastilina',
    'Historias con Pinterest',
    'Termina mi rima',
    'Podcast debate',
    'Lista de pelis y series (con ruleta o selector aleatorio).'
  ];

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void initIdeas();
    }
  });

  function handleModalKeydown(e: KeyboardEvent, closeFn: () => void) {
    if (e.key === 'Escape') closeFn();
  }

  async function initIdeas() {
    await loadIdeas();
    await loadPartnerData();

    const { count } = await repo.dateIdeas.count();
    if (count === 0) {
      const toInsert = builtInIdeas.map(text => ({ idea_text: text, status: 'pending' as const }));
      await repo.dateIdeas.insertMany(toInsert);
      await loadIdeas();
    }
  }

  async function loadPartnerData() {
    const profile = await repo.partner.getProfile();
    if (profile) {
      if (profile.partner_id) {
        partnerProfile = await repo.partner.getPartnerProfile();
        if (partnerProfile) {
          const { data } = await repo.partner.getPartnerIdeas();
          partnerIdeas = data || [];
        }
      }
    }
  }

  async function loadIdeas() {
    if (!userId) return;
    const { data } = await repo.dateIdeas.list();
    ideas = data || [];
  }

  async function toggleStatus(idea: DateIdea) {
    const newStatus = idea.status === 'pending' ? 'done' : 'pending';
    await repo.dateIdeas.updateStatus(idea.id!, newStatus);
    await loadIdeas();
  }

  async function addIdea() {
    saving = true;
    await repo.dateIdeas.insert(newIdea);
    newIdea = { idea_text: '', status: 'pending' };
    showForm = false;
    await loadIdeas();
    saving = false;
  }

  async function deleteIdea(id: string) {
    if (!confirm('¿Eliminar idea de cita?')) return;
    await repo.dateIdeas.remove(id);
    await loadIdeas();
  }

  function pickRandom() {
    const pending = ideas.filter(i => i.status === 'pending');
    if (!pending.length) { alert('¡Todas las ideas están hechas! Agrega más 💕'); return; }
    randomPick = pending[Math.floor(Math.random() * pending.length)];
    showRandom = true;
  }

  async function copyPartnerCode(content: string) {
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

  const pendingCount = $derived(ideas.filter(i => i.status === 'pending').length);
  const doneCount = $derived(ideas.filter(i => i.status === 'done').length);
</script>

<Toast visible={copyToast} message="Copiado al portapapeles" />

<div class="ideas-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">💡 Date Ideas</h2>
      <div class="section-subtitle">Ideas para hacer juntos</div>
    </div>
    <div style="display:flex;justify-content:flex-end;gap:10px;flex-wrap:wrap;">
      <button class="btn btn-primary" onclick={pickRandom}>⊶ Sorpréndeme</button>
      <button class="btn btn-secondary" onclick={() => showForm = true}>+ Nueva idea</button>
    </div>
  </div>

  <div class="partner-stats">
    <div class="pstat">
      <span class="pstat-num">{ideas.length}</span>
      <span class="pstat-label">Ideas totales</span>
    </div>
    <div class="pstat">
      <span class="pstat-num" style="color:var(--accent-green)">{pendingCount}</span>
      <span class="pstat-label">Por hacer</span>
    </div>
    <div class="pstat">
      <span class="pstat-num" style="color:var(--accent-yellow)">{doneCount}</span>
      <span class="pstat-label">Hechas</span>
    </div>
    <div class="pstat">
      <div class="pstat-progress">
        <div class="progress-track" style="width:100%">
          <div class="progress-fill" style="width:{ideas.length ? (doneCount/ideas.length)*100 : 0}%;background:var(--accent-yellow);"></div>
        </div>
      </div>
      <span class="pstat-label">Progreso</span>
    </div>
  </div>

  <div class="ideas-section">
    {#if partnerProfile && partnerIdeas.length > 0}
      <h3 class="ideas-group-label partner-label">💑 Ideas de {partnerProfile.email.split('@')[0]}</h3>
      <div class="ideas-grid">
        {#each partnerIdeas.filter(i => i.status === 'pending') as idea}
          <div class="idea-card partner-idea">
            <div class="idea-main">
              <span class="check-circle" style="background:var(--accent-purple)"></span>
              <span class="idea-text">{idea.idea_text}</span>
            </div>
          </div>
        {/each}
        {#each partnerIdeas.filter(i => i.status === 'done') as idea}
          <div class="idea-card partner-idea done">
            <div class="idea-main">
              <span class="check-circle checked" style="background:var(--accent-purple)">✓</span>
              <span class="idea-text done-text">{idea.idea_text}</span>
            </div>
          </div>
        {/each}
      </div>
    {/if}

    <h3 class="ideas-group-label">Por hacer ✨</h3>
    <div class="ideas-grid">
      {#each ideas.filter(i => i.status === 'pending') as idea}
        <div class="idea-card" class:done={idea.status === 'done'}>
          <div class="idea-main">
            <button class="idea-check" onclick={() => toggleStatus(idea)} aria-label="Mark idea as {idea.status === 'done' ? 'pending' : 'done'}">
              <span class="check-circle" aria-hidden="true"></span>
            </button>
            <span class="idea-text">{idea.idea_text}</span>
          </div>
          {#if idea.link}
            <a href={idea.link} target="_blank" class="idea-link">🔗</a>
          {/if}
          <button class="idea-del btn btn-ghost" onclick={() => deleteIdea(idea.id!)}>✕</button>
        </div>
      {/each}
    </div>

    {#if doneCount > 0}
      <h3 class="ideas-group-label done-label">Hechas ✓</h3>
      <div class="ideas-grid">
        {#each ideas.filter(i => i.status === 'done') as idea}
          <div class="idea-card done">
            <div class="idea-main">
              <button class="idea-check checked" onclick={() => toggleStatus(idea)}>
                <span class="check-circle">✓</span>
              </button>
              <span class="idea-text done-text">{idea.idea_text}</span>
            </div>
            <button class="idea-del btn btn-ghost" onclick={() => deleteIdea(idea.id!)}>✕</button>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

{#if showRandom && randomPick}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) showRandom = false; }}
    onkeydown={(e) => handleModalKeydown(e, () => showRandom = false)}
    role="presentation"
  >
    <div class="random-modal" role="dialog" aria-modal="true" aria-labelledby="random-idea-text">
      <button type="button" class="random-close" onclick={() => showRandom = false} aria-label="Cerrar">✕</button>
      <div class="random-emoji">💕</div>
      <div class="random-label">¡Esta noche pueden hacer...</div>
      <div class="random-idea" id="random-idea-text">{randomPick.idea_text}</div>
      {#if randomPick.link}
        <a href={randomPick.link} target="_blank" class="btn btn-secondary" rel="noopener noreferrer">Ver enlace →</a>
      {/if}
      <div class="random-actions">
        <button type="button" class="btn btn-primary" onclick={() => { toggleStatus(randomPick!); showRandom = false; }}>¡Lo hicimos! ✓</button>
        <button type="button" class="btn btn-ghost" onclick={pickRandom}>Otra idea 🎲</button>
      </div>
    </div>
  </div>
{/if}

{#if showForm}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) showForm = false; }}
    onkeydown={(e) => handleModalKeydown(e, () => showForm = false)}
    role="presentation"
  >
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="idea-form-title">
      <h3 id="idea-form-title">Nueva idea de cita</h3>
      <form onsubmit={(e) => { e.preventDefault(); addIdea(); }}>
        <div class="form-group">
          <label for="idea-text">Idea</label>
          <input id="idea-text" bind:value={newIdea.idea_text} placeholder="¿Qué quieren hacer?" />
        </div>
        <div class="form-group">
          <label for="idea-link">Enlace (opcional)</label>
          <input id="idea-link" type="url" bind:value={newIdea.link} placeholder="https://..." />
        </div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick={() => showForm = false}>Cancelar</button>
          <button type="submit" class="btn btn-primary" disabled={saving}>{saving ? 'Agregrando...' : 'Agregar pelis'}</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .ideas-page { max-width: inherit; }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 24px;
    gap: 12px;
    flex-wrap: wrap;
  }

  .partner-stats {
    display: grid;
    grid-template-columns: auto auto auto 1fr;
    gap: 16px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 20px 24px;
    margin-bottom: 28px;
    align-items: center;
  }

  .pstat { display: flex; flex-direction: column; gap: 4px; }

  .pstat-num {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 800;
    color: var(--text);
    line-height: 1;
  }

  .pstat-label {
    font-size: 11px;
    color: var(--text2);
    font-family: var(--font-mono);
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }

  .pstat-progress { margin-bottom: 4px; }

  .ideas-group-label {
    font-size: 13px;
    font-weight: 700;
    color: var(--text2);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-family: var(--font-mono);
    margin-bottom: 12px;
    margin-top: 8px;
  }

  .done-label { color: var(--accent-green); margin-top: 32px; }

  .ideas-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 12px;
    margin-bottom: 8px;
  }

  .idea-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 14px 16px;
    display: flex;
    align-items: center;
    gap: 10px;
    transition: all var(--transition);
  }

  .idea-card:hover { border-color: var(--accent-green); transform: translateY(-1px); }
  .idea-card.done { background: var(--bg2); opacity: 0.6; }
  .idea-card.done:hover { opacity: 0.8; }

  .idea-card.partner-idea {
    border-left: 3px solid var(--accent-purple);
  }

  .partner-label {
    color: var(--accent-purple) !important;
  }

  .idea-main { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }

  .idea-check {
    flex-shrink: 0;
    cursor: pointer;
    transition: all var(--transition);
    background: transparent;
    border: none;
    padding: 0;
  }

  .check-circle {
    width: 22px;
    height: 22px;
    border-radius: 50%;
    border: 2px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    color: var(--accent-green);
    transition: all var(--transition);
    background: transparent;
  }

  .idea-check.checked .check-circle {
    background: var(--accent-green);
    border-color: var(--accent-green);
    color: #0a1a0f;
  }

  .idea-text {
    font-size: 14px;
    font-weight: 500;
    color: var(--text);
    line-height: 1.4;
  }

  .done-text { text-decoration: line-through; color: var(--text3); }

  .idea-link { font-size: 16px; flex-shrink: 0; }

  .idea-del {
    flex-shrink: 0;
    opacity: 0;
    transition: opacity var(--transition);
    font-size: 11px;
    padding: 2px 6px;
    color: var(--text3);
  }

  .idea-card:hover .idea-del { opacity: 1; }

  .random-modal {
    background: var(--bg2);
    border: 1px solid rgba(168,230,207,0.3);
    border-radius: var(--radius-lg);
    padding: 40px;
    text-align: center;
    max-width: 420px;
    width: 100%;
    position: relative;
    box-shadow: 0 0 60px rgba(168,230,207,0.1);
  }

  .random-close {
    position: absolute;
    top: 16px;
    right: 16px;
    color: var(--text3);
    font-size: 18px;
    cursor: pointer;
    transition: color var(--transition);
    background: none;
    border: none;
  }

  .random-close:hover { color: var(--text); }

  .random-emoji { font-size: 56px; margin-bottom: 16px; }

  .random-label {
    font-size: 13px;
    color: var(--text3);
    font-family: var(--font-mono);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    margin-bottom: 12px;
  }

  .random-idea {
    font-family: var(--font-display);
    font-size: 24px;
    font-weight: 800;
    color: var(--text);
    margin-bottom: 28px;
    line-height: 1.3;
  }

  .random-actions {
    display: flex;
    gap: 10px;
    justify-content: center;
    margin-top: 16px;
  }

  .modal-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.6);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 50;
    padding: 20px;
  }

  .modal {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 28px;
    max-width: 440px;
    width: 100%;
    position: relative;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin-bottom: 16px;
  }

  .form-group label {
    font-size: 12px;
    font-family: var(--font-mono);
    color: var(--text2);
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }

  .form-actions {
    display: flex;
    gap: 10px;
    justify-content: flex-end;
    margin-top: 16px;
  }

  @media (max-width: 700px) {
    .partner-stats { grid-template-columns: 1fr 1fr; }
    .ideas-grid { grid-template-columns: 1fr; }
  }
</style>