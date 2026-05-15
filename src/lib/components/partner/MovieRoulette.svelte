<script lang="ts">
  import { page } from '$app/state';
  import { createRepository } from '$lib/services/repository';
  import Toast from '$lib/components/Toast.svelte';
  import type { MovieWithRatings } from '$lib/types';

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));

  let initialized = $state(false);
  let movies = $state<MovieWithRatings[]>([]);
  let moviesWithoutRatings = $derived(movies.filter(m => !m.user_rating));

  let addText = $state('');
  let addSaving = $state(false);
  let addToast = $state(false);
  let addToastMsg = $state('');
  let addToastTimer: ReturnType<typeof setTimeout> | null = $state(null);

  let spinning = $state(false);
  let wheelAngle = $state(0);

  let modalMovie = $state<MovieWithRatings | null>(null);
  let modalTitle = $state('');
  let modalPoster = $state('');
  let modalResources = $state('');
  let modalUserRating = $state(0);
  let modalSaving = $state(false);
  let modalTextarea: HTMLTextAreaElement | null = $state(null);
  let wheelCanvas: HTMLCanvasElement | null = $state(null);

  const wheelColorVars = ['--accent-green', '--accent-yellow', '--accent-orange', '--accent-blue', '--accent-purple', '--accent-red'];

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void init();
    }
  });

  $effect(() => {
    if (!modalTextarea) return;
    modalTextarea.style.height = 'auto';
    modalTextarea.style.height = `${modalTextarea.scrollHeight}px`;
  });

  $effect(() => {
    if (!wheelCanvas) return;
    void moviesWithoutRatings.length;
    drawWheel();
  });

  async function init() {
    await loadData();
  }

  async function loadData() {
    const { data } = await repo.movieRatings.listFused();
    movies = (data as MovieWithRatings[]) || [];
  }

  function showToast(msg: string) {
    addToastMsg = msg;
    addToast = true;
    if (addToastTimer) clearTimeout(addToastTimer);
    addToastTimer = setTimeout(() => {
      addToast = false;
      addToastTimer = null;
    }, 2500);
  }

  async function addMovies() {
    const lines = addText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    if (!lines.length) return;

    const existing = new Set(movies.map(m => m.title.toLowerCase().trim()));
    const toAdd = lines.filter(l => !existing.has(l.toLowerCase().trim()));
    const skipped = lines.length - toAdd.length;

    if (!toAdd.length) {
      showToast('Todas las películas ya están en la lista');
      return;
    }

    addSaving = true;
    const { data, error } = await repo.movieWatchlist.insertMany(toAdd);
    if (error) {
      showToast('Error al agregar películas');
    } else {
      const newItems = Array.isArray(data) ? data : [data];
      if (skipped > 0) showToast(`${skipped} película(s) omitida(s) por duplicado`);
      else showToast(`${toAdd.length} película(s) agregada(s)`);
      addText = '';
    }
    addSaving = false;
    await loadData();
  }

  async function deleteMovie(id: string) {
    if (!confirm('¿Eliminar esta película?')) return;
    await repo.movieWatchlist.remove(id);
    await loadData();
  }

  function spin() {
    if (spinning || moviesWithoutRatings.length === 0) return;
    spinning = true;

    const spinDegrees = 3600 + Math.random() * 7200;
    wheelAngle += spinDegrees;

    const rotationRad = (wheelAngle * Math.PI / 180) % (2 * Math.PI);
    let originalAngle = - rotationRad;
    originalAngle = ((originalAngle % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);

    const arcRad = (2 * Math.PI) / moviesWithoutRatings.length;
    const targetIndex = Math.floor(originalAngle / arcRad) % moviesWithoutRatings.length;

    setTimeout(() => {
      openMovieModal(moviesWithoutRatings[targetIndex]);
      spinning = false;
    }, 5000);
  }

  function openMovieModal(movie: MovieWithRatings) {
    modalMovie = movie;
    modalTitle = movie.title;
    modalPoster = movie.poster_url || '';
    modalResources = movie.resources || '';
    modalUserRating = movie.user_rating || 0;
    modalSaving = false;
  }

  function closeMovieModal() {
    modalMovie = null;
    modalTextarea = null;
  }

  async function saveMovieUpdates() {
    if (!modalMovie?.id) return;
    modalSaving = true;

    const movieId = modalMovie.id;
    const prevTitle = modalMovie.title;
    const prevPoster = modalMovie.poster_url || '';
    const prevResources = modalMovie.resources || '';
    const prevUserRating = modalMovie.user_rating || 0;

    if (modalTitle !== prevTitle) {
      await repo.movieWatchlist.updateTitle(movieId, modalTitle.trim());
    }

    if (modalPoster !== prevPoster) {
      await repo.movieWatchlist.updatePoster(movieId, modalPoster.trim());
    }

    if (modalResources !== prevResources) {
      await repo.movieWatchlist.updateResources(movieId, modalResources.trim());
    }

    if (modalUserRating > 0 && modalUserRating !== prevUserRating) {
      await repo.movieRatings.upsert(movieId, modalUserRating);
    }

    modalSaving = false;
    closeMovieModal();
    await loadData();
  }

  function renderMd(md: string): string {
    if (!md) return '';
    return md
      .replace(/^### (.+)$/gm, '<h3>$1</h3>')
      .replace(/^## (.+)$/gm, '<h2>$1</h2>')
      .replace(/^# (.+)$/gm, '<h1>$1</h1>')
      .replace(/^---$/gm, '<hr/>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      .replace(/`(.+?)`/g, '<code>$1</code>')
      .replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>')
      .replace(/^(\s*)-\s+(.+)$/gm, '<li>$2</li>')
      .replace(/(<li>.*<\/li>(?:\n<li>.*<\/li>)*)/g, '<ul>$1</ul>')
      .replace(/\n\n/g, '')
      .replace(/\n/g, '<br/>');
  }

  function drawWheel() {
    if (!wheelCanvas) return;
    if (moviesWithoutRatings.length === 0) return;

    const rect = wheelCanvas.getBoundingClientRect();
    const size = Math.max(1, Math.floor(Math.min(rect.width, rect.height)));
    const dpr = window.devicePixelRatio || 1;

    wheelCanvas.width = Math.floor(size * dpr);
    wheelCanvas.height = Math.floor(size * dpr);

    const ctx = wheelCanvas.getContext('2d');
    if (!ctx) return;

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, size, size);

    const rootStyles = getComputedStyle(document.documentElement);
    const colors = wheelColorVars.map(v => rootStyles.getPropertyValue(v).trim()).filter(Boolean);
    const bg1 = rootStyles.getPropertyValue('--bg1').trim() || '#0b1114';
    const textColor = rootStyles.getPropertyValue('--bg1').trim() || '#0b1114';
    const monoFont = rootStyles.getPropertyValue('--font-mono').trim() || 'ui-monospace, SFMono-Regular, Menlo, monospace';

    const cx = size / 2;
    const cy = size / 2;
    const radius = size / 2;
    const segAngle = (Math.PI * 2) / moviesWithoutRatings.length;

    for (let i = 0; i < moviesWithoutRatings.length; i++) {
      const start = -Math.PI / 2 + i * segAngle;
      const end = start + segAngle;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, radius, start, end);
      ctx.closePath();
      ctx.fillStyle = colors[i % colors.length] || '#73e7bd';
      ctx.fill();
      ctx.strokeStyle = bg1;
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    ctx.fillStyle = textColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = `800 11px ${monoFont}`;

    const labelRadius = radius * 0.45;
    for (let i = 0; i < moviesWithoutRatings.length; i++) {
      const movie = moviesWithoutRatings[i];
      const mid = -Math.PI / 2 + i * segAngle + segAngle / 2;

      const x = cx + Math.cos(mid) * labelRadius;
      const y = cy + Math.sin(mid) * labelRadius;

      const title = movie.title.length > 18 ? `${movie.title.slice(0, 16)}…` : movie.title;

      ctx.save();
      ctx.translate(x, y);
      ctx.rotate(mid);
      ctx.fillText(title, 0, 0);
      ctx.restore();
    }
  }
</script>

<Toast visible={addToast} message={addToastMsg} />

<section class="movie-roulette fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">🎬 Movie Roulette</h2>
      <span class="section-subtitle">Gira la ruleta y elijan qué ver</span>
    </div>
  </div>

  <div class="roulette-layout">
    <div class="wheel-area">
      <div class="wheel-container">
        <span class="wheel-pointer">▼</span>
        {#if moviesWithoutRatings.length > 0}
          <canvas
            class="wheel"
            bind:this={wheelCanvas}
            style="transform: rotate({wheelAngle}deg); transition: transform 4s cubic-bezier(0.17, 0.67, 0.12, 0.99);"
            aria-label="Ruleta de películas"
          ></canvas>
        {:else}
          <div class="wheel-empty">Agrega películas para girar</div>
        {/if}
      </div>

      <button
        class="btn btn-secondary spin-btn"
        onclick={spin}
        disabled={spinning || moviesWithoutRatings.length === 0}
      >
        {spinning ? 'Girando…' : '🎡 Girar'}
      </button>
    </div>

    <div class="roulette-sidebar">
      <div class="add-panel card">
        <h4>Agregar pelis</h4>
        <textarea
          class="md-editor"
          bind:value={addText}
          placeholder="Película 1
Película 2
Película 3
..."
          rows="5"
        ></textarea>
        <button class="btn btn-primary" onclick={addMovies} disabled={addSaving || !addText.trim()}>
          {addSaving ? '…' : '+ Agregar'}
        </button>
      </div>
    </div>
  </div>

  {#if movies.length > 0}
    <div class="ratings-section">
      <h3 class="ideas-group-label">Lista de Pelis ({movies.length})</h3>
      <div class="ratings-grid">
        {#each movies as movie (movie.id)}
          {@const avg = movie.avg_rating || 0}
          {@const isRated = movie.total_ratings && movie.total_ratings > 0}
          <button type="button" class="rating-card card" onclick={() => openMovieModal(movie)}>
            {#if movie.poster_url}
              <img src={movie.poster_url} alt={movie.title} class="rating-poster" />
            {:else}
              <div class="rating-poster-placeholder">🎬</div>
            {/if}
            <div class="rating-info">
              <div class="rating-title">{movie.title}</div>
              <div class="rating-stars">
                {#if isRated}
                  <span class="rating-avg">{avg}/5</span>
                {:else}
                  <span class="rating-avg">—</span>
                {/if}
                {#each [1,2,3,4,5] as s}
                  <span class="star">
                    {#if s <= avg}
                      <span class="filled">★</span>
                    {:else}
                      <span>☆</span>
                    {/if}
                  </span>
                {/each}
              </div>
              <div class="rating-partner-stars">
                {#if movie.user_rating}
                  <span class="rating-you">Tú: {movie.user_rating}/5 ⭐</span>
                {/if}
                {#if movie.partner_rating}
                  <span class="rating-partner">Pareja: {movie.partner_rating}/5 ⭐</span>
                {/if}
              </div>
              {#if movie.resources}
                <div class="md-preview rating-resources">
                  {@html renderMd(movie.resources)}
                </div>
              {/if}
            </div>
          </button>
        {/each}
      </div>
    </div>
  {/if}
</section>

{#if modalMovie}
  <div
    class="modal-backdrop"
    onclick={(e) => { if (e.target === e.currentTarget) closeMovieModal(); }}
    role="presentation"
  >
    <div class="modal movie-modal" role="dialog" aria-modal="true" aria-label="Editar película">

      <input
        id="movie-title"
        type="text"
        class="title-input movie-modal-title"
        bind:value={modalTitle}
        placeholder="Título de la película"
      />
      
      {#if modalPoster}
        <img src={modalPoster} alt={modalMovie.title} class="rating-modal-poster" />
      {:else}
        <div class="rating-poster-placeholder" style="height:150px;">🎬</div>
      {/if}

      <div class="form-group">
        <label for="movie-resources">Recursos</label>
        <textarea
          id="movie-resources"
          class="md-editor"
          bind:this={modalTextarea}
          bind:value={modalResources}
          placeholder="## Recursos&#10;&#10;- enlace1&#10;- enlace2"
          rows="4"
        ></textarea>
      </div>

      <div class="form-group">
        <label for="movie-poster-url">Póster (URL)</label>
        <input
          id="movie-poster-url"
          type="url"
          class="poster-input poster-input-full"
          bind:value={modalPoster}
          placeholder="https://..."
        />
      </div>

      <div class="movie-modal-rating">
        <div class="star-picker">
          {#each [1,2,3,4,5] as s}
            <button
              type="button"
              class="star-btn"
              class:filled={s <= modalUserRating}
              onclick={() => modalUserRating = s}
              aria-label={`${s} estrellas`}
            >
              ★
            </button>
          {/each}
          <span class="star-label">{modalUserRating > 0 ? `${modalUserRating}/5` : 'Sin calificar'}</span>
        </div>

        <div class="rating-partner-stars">
          {#if modalMovie.total_ratings && modalMovie.total_ratings > 0}
            <span class="rating-avg">Media: {modalMovie.avg_rating}/5</span>
          {/if}
          {#if modalMovie.partner_rating}
            <span class="rating-partner">Pareja: {modalMovie.partner_rating}⭐</span>
          {/if}
        </div>
      </div>

      <div class="form-actions">
        <button type="button" class="btn btn-danger" onclick={() => { void deleteMovie(modalMovie!.id!); closeMovieModal(); }} disabled={modalSaving}>
          Eliminar
        </button>
        <div style="flex:1"></div>
        <button type="button" class="btn btn-secondary" onclick={closeMovieModal} disabled={modalSaving}>Cancelar</button>
        <button type="button" class="btn btn-primary" onclick={saveMovieUpdates} disabled={modalSaving}>
          {modalSaving ? '…' : 'Guardar'}
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .movie-roulette { max-width: inherit; }

  .roulette-layout {
    display: grid;
    grid-template-columns: 1fr 280px;
    gap: 24px;
    align-items: start;
    max-width: 1000px;
    margin-bottom: 28px;
  }

  .wheel-area {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
  }

  .wheel-container {
    position: relative;
    width: 320px;
    height: 320px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .wheel-pointer {
    position: absolute;
    top: -8px;
    left: 50%;
    transform: translateX(-50%);
    font-size: 28px;
    color: var(--bg);
    z-index: 2;
    text-shadow: 0 5px 15px rgba(255, 255, 255, 0.5);
  }

  .wheel {
    width: 300px;
    height: 300px;
    border-radius: 50%;
    box-shadow: 0 4px 24px rgba(168,230,207,0.2), inset 0 0 0 4px var(--bg1);
    position: relative;
    overflow: hidden;
    display: block;
    background: transparent;
  }

  .wheel-empty {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 300px;
    height: 300px;
    border-radius: 50%;
    background: var(--surface);
    border: 2px dashed var(--border);
    font-size: 13px;
    color: var(--text3);
    font-family: var(--font-mono);
    text-align: center;
    padding: 20px;
  }

  .spin-btn {
    font-size: 18px;
    padding: 12px 32px;
    border-radius: 999px;
  }

  .roulette-sidebar { display: flex; flex-direction: column; gap: 12px; }

  .add-panel {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .add-panel h4 {
    font-size: 13px;
    font-weight: 700;
    font-family: var(--font-mono);
    color: var(--text2);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    margin: 0;
  }

  .title-input {
    width: min-content;
    padding: 0px 8px;
    border: none;
    border-width: 0;
    box-shadow: none;
  }

  .poster-input {
    font-size: 12px;
    padding: 4px 8px;
  }

  .poster-input-full { width: 100%; }

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

  .ratings-section { margin-top: 32px; }

  .ratings-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 14px;
  }

  .rating-card {
    display: flex;
    flex-direction: column;
    gap: 10px;
    cursor: pointer;
    text-align: left;
    transition: all var(--transition);
    border: 1px solid var(--border);
    padding: 0;
  }

  .rating-card:hover { border-color: var(--accent-yellow); transform: translateY(-2px); }

  .rating-poster {
    width: 100%;
    height: 315px;
    object-fit: cover;
    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  }

  .rating-poster-placeholder {
    width: 100%;
    height: 315px;
    background: var(--bg2);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 40px;
    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  }

  .rating-info {
    padding: 10px 12px 12px;
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .rating-title {
    font-size: 13px;
    font-weight: 700;
    color: var(--text);
    font-family: var(--font-display);
  }

  .rating-stars {
    display: flex;
    align-items: center;
    justify-content: end;
    gap: 10px;
  }

  .star {
    font-size: 25px;
    color: var(--accent-purple);
  }

  .star .filled { color: var(--accent-yellow); }

  .rating-avg {
    font-size: 12px;
    font-weight: 800;
    color: var(--text);
    font-family: var(--font-mono);
    margin-left: 6px;
  }

  .rating-partner-stars {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    font-size: 12px;
    font-weight: 600;
    font-family: var(--font-mono);
  }

  .rating-you { color: var(--text2); }
  .rating-partner { color: var(--accent-orange); }

  .rating-resources {
    font-size: 12px;
    max-height: 20px;
    overflow: hidden;
    margin-top: 4px;
  }

  .star-picker {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 20px;
  }

  .star-btn {
    font-size: 32px;
    background: none;
    border: none;
    cursor: pointer;
    color: var(--border);
    transition: color var(--transition);
    padding: 0;
    line-height: 1;
  }

  .star-btn.filled { color: var(--accent-yellow); }
  .star-btn:hover { color: var(--accent-yellow); }
  @media (hover: hover) and (pointer: fine) {
    .star-btn:hover { color: var(--accent-yellow); }
  }

  .star-label {
    font-size: 14px;
    font-family: var(--font-mono);
    color: var(--text3);
    margin-left: 8px;
  }

  .rating-modal-poster {
    width: 100px;
    height: 150px;
    object-fit: cover;
    border-radius: var(--radius);
    margin: 0 auto 16px;
    display: block;
  }

  .md-editor {
    width: 100%;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    color: var(--text);
    padding: 12px;
    font-family: var(--font-mono);
    font-size: 12px;
    line-height: 1.6;
    resize: vertical;
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

  .movie-modal { max-width: 520px; }

  .movie-modal-title {
    margin: 0 0 14px;
    font-size: 18px;
    font-weight: 800;
    font-family: var(--font-display);
    color: var(--text);
    width: inherit;
  }

  .movie-modal-rating { margin-top: 6px; }
  .movie-modal-rating .star-picker { margin-bottom: 10px; }

  .form-actions {
    display: flex;
    gap: 10px;
    justify-content: flex-end;
    margin-top: 16px;
  }

  @media (max-width: 700px) {
    .roulette-layout { grid-template-columns: 1fr; }
    .ratings-grid { grid-template-columns: 1fr; }
    .wheel { width: 260px; height: 260px; }
    .wheel-container { width: 280px; height: 280px; }
  }
</style>
