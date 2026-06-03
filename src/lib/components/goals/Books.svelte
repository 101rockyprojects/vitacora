<script lang="ts">
  import type { Book, BookCategoryRating, BookRatingCategory } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import { renderMd, formatLinks } from '$lib/utils/markdown';

  interface Props {
    userId: string;
    books?: Book[];
    onRefresh?: () => void;
  }

  let { userId, books = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showBookForm = $state(false);
  let editingBook = $state<Book | null>(null);
  let bookForm = $state<Book>({ title: '', current_page: 0, total_pages: 0, rating_mode: 'default' });
  let expandedBookNotes = $state<string[]>([]);
  let saving = $state(false);

  let ratingCategories = $state<BookRatingCategory[]>([]);
  let categoryRatings = $state<BookCategoryRating[]>([]);
  let newCategoryName = $state('');
  let showCategoryManager = $state(false);
  let detailedModeEnabled = $state(false);
  let detailedModeApplied = $state(false);
  let bookCategoryRatingsMap = $state<Record<string, BookCategoryRating[]>>({});

  const expandedBookNotesSet = $derived(new Set(expandedBookNotes));

  function calculateRating(ratings: BookCategoryRating[]): number {
    const validRatings = ratings.filter(r => r.rating > 0);
    if (validRatings.length === 0) return 0;
    const sum = validRatings.reduce((acc, r) => acc + r.rating, 0);
    return sum / validRatings.length;
  }

  let calculatedRating = $derived.by(() => {
    if (!detailedModeEnabled) return 0;
    return calculateRating(categoryRatings);
  });

  let editingBookDisplayRating = $derived.by(() => {
    if (!editingBook) return 0;
    if (editingBook.rating_mode === 'default') {
      return editingBook.rating || 0;
    }
    return calculatedRating;
  });

  function toggleBookNotes(bookId: string) {
    if (expandedBookNotesSet.has(bookId)) {
      expandedBookNotes = expandedBookNotes.filter(id => id !== bookId);
    } else {
      expandedBookNotes = [...expandedBookNotes, bookId];
    }
  }

  function resetBookForm() {
    bookForm = { title: '', current_page: 0, total_pages: 0, rating_mode: 'default' };
    editingBook = null;
    categoryRatings = [];
    detailedModeEnabled = false;
    detailedModeApplied = false;
  }

  async function loadRatingCategories() {
    const { data } = await repo.bookRatingCategories.list();
    ratingCategories = data || [];
  }

  async function loadCategoryRatings(bookId: string) {
    const { data } = await repo.bookCategoryRatings.listByBook(bookId);
    categoryRatings = data || [];
  }

  function getCategoryRating(categoryId: string): number {
    const existing = categoryRatings.find(r => r.category_id === categoryId);
    return existing?.rating || 0;
  }

  function setCategoryRating(categoryId: string, rating: number) {
    const existing = categoryRatings.find(r => r.category_id === categoryId);
    if (existing) {
      categoryRatings = categoryRatings.map(r => 
        r.category_id === categoryId ? { ...r, rating } : r
      );
    } else {
      categoryRatings = [...categoryRatings, {
        book_id: editingBook?.id || '',
        category_id: categoryId,
        rating,
        user_id: userId
      }];
    }
  }

  async function addCategory() {
    if (!newCategoryName.trim()) return;
    const { data } = await repo.bookRatingCategories.create(newCategoryName.trim());
    if (data) {
      ratingCategories = [...ratingCategories, data];
      newCategoryName = '';
    }
  }

  async function removeCategory(id: string) {
    if (!confirm('¿Eliminar categoría?')) return;
    await repo.bookRatingCategories.remove(id);
    ratingCategories = ratingCategories.filter(c => c.id !== id);
    categoryRatings = categoryRatings.filter(r => r.category_id !== id);
  }

  function applyDetailedMode() {
    if (bookForm.rating && bookForm.rating > 0) {
      if (!confirm('Esto reemplazará tu calificación simple de ' + bookForm.rating + ' estrellas. ¿Continuar?')) {
        return;
      }
    }
    bookForm.rating_mode = 'calculated';
    bookForm.rating = calculatedRating > 0 ? calculatedRating : undefined;
    detailedModeApplied = true;
  }

  function disableDetailedMode() {
    bookForm.rating_mode = 'default';
    detailedModeEnabled = false;
    detailedModeApplied = false;
  }

  async function saveBook() {
    saving = true;
    const isFinished = bookForm.current_page >= bookForm.total_pages && bookForm.total_pages > 0;

    const finalRating = bookForm.rating_mode === 'calculated' 
      ? (calculatedRating > 0 ? calculatedRating : undefined)
      : bookForm.rating;

    const bookData = {
      ...bookForm,
      rating: finalRating
    };

    if (editingBook?.id) {
      const wasFinished = editingBook.current_page >= editingBook.total_pages;
      bookData.notes = formatLinks(bookData.notes || '');
      await repo.books.update(editingBook.id, { ...bookData, updated_at: new Date().toISOString() });

      if (bookForm.rating_mode === 'calculated' && editingBook.id) {
        const ratingsToSave = categoryRatings.map(r => ({
          category_id: r.category_id,
          rating: r.rating
        }));
        await repo.bookCategoryRatings.upsertMany(editingBook.id, ratingsToSave);
      }

      if (isFinished && !wasFinished) await awardXP(userId, 'education', 'book_finished', XP_VALUES.book_finished, editingBook.id);
      else await awardXP(userId, 'education', 'book_page_update', XP_VALUES.book_page_update);
    } else {
      const { data } = await repo.books.insert(bookData);
      if (data) {
        if (bookForm.rating_mode === 'calculated') {
          const ratingsToSave = categoryRatings.map(r => ({
            category_id: r.category_id,
            rating: r.rating
          }));
          await repo.bookCategoryRatings.upsertMany(data.id, ratingsToSave);
        }
        if (isFinished) await awardXP(userId, 'education', 'book_finished', XP_VALUES.book_finished, data.id);
      }
    }

    const { data } = await repo.books.list();
    books = data || [];
    showBookForm = false;
    resetBookForm();
    saving = false;
  }

  async function editBook(b: Book) {
    editingBook = b;
    bookForm = { ...b, rating_mode: b.rating_mode || 'default' };
    detailedModeEnabled = b.rating_mode === 'calculated';
    detailedModeApplied = b.rating_mode === 'calculated';
    await loadCategoryRatings(b.id || '');
    showBookForm = true;
  }

  async function deleteBook(id: string) {
    if (!confirm('¿Eliminar libro?')) return;
    await repo.books.remove(id);
    const { data } = await repo.books.list();
    books = data || [];
  }

  function bookProgress(b: Book) {
    return b.total_pages ? Math.round((b.current_page / b.total_pages) * 100) : 0;
  }

  function getBookDisplayRating(book: Book): number {
    if (book.rating_mode === 'default') {
      return book.rating || 0;
    }
    if (book.rating_mode === 'calculated') {
      const ratings = bookCategoryRatingsMap[book.id || ''] || [];
      return calculateRating(ratings);
    }
    return book.rating || 0;
  }

  async function loadAllCalculatedBookRatings() {
    const calculatedBooks = books.filter(b => b.rating_mode === 'calculated' && b.id);
    const entries: [string, BookCategoryRating[]][] = await Promise.all(
      calculatedBooks.map(async (b) => {
        const { data } = await repo.bookCategoryRatings.listByBook(b.id!);
        return [b.id!, data || []];
      })
    );
    bookCategoryRatingsMap = Object.fromEntries(entries);
  }

  $effect(() => {
    if (showBookForm) {
      loadRatingCategories();
    }
  });

  $effect(() => {
    if (books.length > 0) {
      loadAllCalculatedBookRatings();
    }
  });
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { resetBookForm(); showBookForm = true; }}>+ Agregar libro</button>
    <button class="btn btn-secondary" onclick={() => { showCategoryManager = !showCategoryManager; loadRatingCategories(); }}>
      {showCategoryManager ? 'Ocultar categorías' : '⚙ Categorías'}
    </button>
  </div>

  {#if showCategoryManager}
    <div class="category-manager card">
      <h4>Categorías de calificación</h4>
      <p class="category-manager-desc">Define las categorías que usarás para calificar libros</p>
      <div class="category-list">
        {#each ratingCategories as cat, i}
          <div class="category-item">
            <span class="category-name">{cat.name}</span>
            <button class="small-btn btn-ghost" onclick={() => removeCategory(cat.id!)}>✕</button>
          </div>
        {/each}
        {#if ratingCategories.length === 0}
          <p class="empty-categories">No hay categorías definidas</p>
        {/if}
      </div>
      <div class="add-category">
        <input bind:value={newCategoryName} placeholder="Nueva categoría (ej: Romántico)" onkeydown={(e) => { if (e.key === 'Enter') addCategory(); }} />
        <button class="btn btn-primary btn-sm" onclick={addCategory}>+</button>
      </div>
    </div>
  {/if}

  <div class="books-grid">
    {#each books as book}
      {@const pct = bookProgress(book)}
      {@const showNotes = expandedBookNotesSet.has(book.id || '')}
      {@const displayRating = getBookDisplayRating(book)}
      <div class="book-card card" class:finished={pct >= 100}>
        <div class="book-cover-info">
          <div class="book-cover-rating">
            <div class="book-cover">
              {#if book.cover_url}
                <img src={book.cover_url} alt={book.title} />
              {:else}
                <span>{book.title[0]}</span>
              {/if}
            </div>
            {#if displayRating > 0}
              <div class="book-rating">
                <span class="star-icon">★</span>
                <span class="rating-value">{displayRating.toFixed(1)}</span>
              </div>
            {/if}
          </div>
          <div class="book-info">
            <div class="book-title">{book.title}</div>
            <div class="book-progress-label">{book.current_page} / {book.total_pages} págs</div>
            <div class="progress-track" style="margin:6px 0;">
              <div class="progress-fill" style="width:{pct}%;background:{pct>=100?'var(--accent-yellow)':'var(--accent-green)'};"></div>
            </div>
            <div class="book-pct">{pct >= 100 ? 'Terminado' : `${pct}%`}</div>
          </div>
        </div>
        {#if book.notes}
          <button
            class="book-notes-toggle"
            type="button"
            onclick={() => toggleBookNotes(book.id || '')}
            aria-expanded={showNotes}
          >
            <span>Notas</span>
            <span class="toggle-icon" class:open={showNotes}>▾</span>
          </button>
          {#if showNotes}
            <div class="book-notes">{@html renderMd(book.notes)}</div>
          {/if}
        {/if}
        <div class="card-actions">
          <button class="small-btn btn-ghost" onclick={() => editBook(book)}>🖋</button>
          <button class="small-btn btn-ghost" onclick={() => deleteBook(book.id!)}>✕</button>
        </div>
      </div>
    {/each}
    {#if books.length === 0}
      <div class="empty-state card">Agrega tu primer libro 📖</div>
    {/if}
  </div>
</div>

{#if showBookForm}
  <div 
    class="modal-backdrop" 
    onclick={(e) => { if (e.target === e.currentTarget) { showBookForm = false; resetBookForm(); } }}
    onkeydown={(e) => { if (e.key === 'Escape') { showBookForm = false; resetBookForm(); } }}
    role="presentation"
  >
    <div class="modal modal-lg" role="dialog" aria-modal="true" aria-labelledby="book-form-title">
      <h3 id="book-form-title">{editingBook ? 'Editar libro' : 'Nuevo libro'}</h3>
      <form onsubmit={(e) => { e.preventDefault(); saveBook(); }}>
        <div class="form-group">
          <label for="book-title">Título</label>
          <input id="book-title" bind:value={bookForm.title} placeholder="Nombre del libro" />
        </div>
        <div class="grid-2">
          <div class="form-group">
            <label for="book-current">Página actual</label>
            <input id="book-current" type="number" bind:value={bookForm.current_page} min="0" />
          </div>
          <div class="form-group">
            <label for="book-total">Total páginas</label>
            <input id="book-total" type="number" bind:value={bookForm.total_pages} min="0" />
          </div>
        </div>
        <div class="form-group">
          <label for="book-cover">URL portada (opcional)</label>
          <input id="book-cover" type="url" bind:value={bookForm.cover_url} placeholder="https://..." />
        </div>
        <div class="form-group">
          <label for="book-notes">Notas</label>
          <textarea id="book-notes" bind:value={bookForm.notes} rows="8" placeholder="Reflexiones..."></textarea>
        </div>

        <div class="rating-section">
          <div class="rating-header">
            <span class="rating-title">Calificación</span>
              <span class="rating-badge badge-simple">Modo {detailedModeEnabled ? 'detallado' : 'simple'}</span>
          </div>

          <div class="rating-stars-container" class:disabled={detailedModeEnabled}>
            <div class="star-picker">
              {#each [1,2,3,4,5] as s}
                <button
                  type="button"
                  class="star-btn"
                  class:filled={s <= (bookForm.rating || 0)}
                  onclick={() => { if (!detailedModeEnabled) bookForm.rating = bookForm.rating === s ? 0 : s; }}
                  disabled={detailedModeEnabled}
                  aria-label={`${s} estrellas`}
                >
                  ★
                </button>
              {/each}
              <span class="star-label">{bookForm.rating ? `${bookForm.rating}/5` : 'Sin calificar'}</span>
            </div>
            {#if detailedModeEnabled}
              <div class="disabled-overlay">
                <span>↓ Califica por categorías ↓</span>
              </div>
            {/if}
          </div>

          <div class="toggle-section">
            <label class="toggle-label">
              <span class="toggle-text">Calificación detallada por categorías</span>
              <button
                type="button"
                class="toggle-switch"
                class:active={detailedModeEnabled}
                onclick={() => {
                  if (detailedModeEnabled) {
                    disableDetailedMode();
                  } else {
                    detailedModeEnabled = true;
                  }
                }}
                role="switch"
                aria-checked={detailedModeEnabled}
                aria-label="Activar calificación detallada"
              >
                <span class="toggle-knob"></span>
              </button>
            </label>
          </div>

          {#if detailedModeEnabled}
            <div class="category-ratings-section">
              {#if ratingCategories.length === 0}
                <div class="no-categories-msg">
                  <span class="no-categories-icon">📋</span>
                  <span>No hay categorías definidas. Crea categorías primero con el botón "⚙ Categorías".</span>
                </div>
              {:else}
                <div class="category-ratings-list">
                  {#each ratingCategories as cat}
                    <div class="category-row">
                      <span class="cat-name">{cat.name}</span>
                      <div class="star-picker small">
                        {#each [1,2,3,4,5] as s}
                          <button
                            type="button"
                            class="star-btn"
                            class:filled={s <= getCategoryRating(cat.id || '')}
                            onclick={() => setCategoryRating(cat.id || '', getCategoryRating(cat.id || '') === s ? 0 : s)}
                            aria-label={`${s} estrellas para ${cat.name}`}
                          >
                            ★
                          </button>
                        {/each}
                        {#if getCategoryRating(cat.id || '') > 0}
                          <button
                            type="button"
                            class="clear-rating-btn"
                            onclick={() => setCategoryRating(cat.id || '', 0)}
                            aria-label="Limpiar calificación de {cat.name}"
                          >
                            ✕
                          </button>
                        {/if}
                      </div>
                    </div>
                  {/each}
                </div>

                <div class="calculated-result">
                  <div class="result-row">
                    <span class="result-label">Promedio calculado:</span>
                    <span class="result-value" class:has-value={calculatedRating > 0}>
                      {calculatedRating > 0 ? `${calculatedRating.toFixed(1)} / 5` : '—'}
                    </span>
                  </div>

                  {#if !detailedModeApplied}
                    <button
                      type="button"
                      class="btn btn-apply"
                      onclick={applyDetailedMode}
                      disabled={calculatedRating === 0}
                    >
                      Aplicar calificación
                    </button>
                    <p class="apply-warning">
                      {#if bookForm.rating && bookForm.rating > 0}
                        ⚠ Esto reemplazará tu calificación simple de {bookForm.rating} estrellas
                      {:else}
                        Se guardará como la calificación del libro
                      {/if}
                    </p>
                  {:else}
                    <div class="applied-confirmation">
                      <span class="confirmation-icon">✓</span>
                      <span>Calificación detallada aplicada</span>
                    </div>
                  {/if}
                </div>
              {/if}
            </div>
          {/if}
        </div>

        <div class="form-actions">
          <button type="button" class="btn btn-secondary" onclick={() => { showBookForm = false; resetBookForm(); }}>Cancelar</button>
          <button type="submit" class="btn btn-primary" disabled={saving}>{saving ? '...' : 'Guardar'}</button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .books-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 16px;
  }

  .book-card {
    position: relative;
    transition: transform var(--transition);
  }

  .book-card:hover { transform: translateY(-2px); }

  .book-card.finished { border-color: var(--accent-yellow); }

  .book-cover-info {
    display: flex;
    gap: 14px;
  }

  .book-cover-rating {
    display: flex;
    flex-direction: column;
    align-items: center;
    height: 100%;
  }

  .book-cover {
    width: 48px;
    height: 72px;
    border-radius: 4px;
    background: var(--surface2);
    font-size: 20px;
    font-weight: 800;
    color: var(--accent-green);
    flex-shrink: 0;
    overflow: hidden;
  }

  .book-cover img { width: 100%; height: 100%; object-fit: cover; }

  .book-info { flex: 1; min-width: 0; }

  .book-title {
    font-weight: 700;
    font-size: 14px;
    margin-bottom: 4px;
  }

  .book-progress-label {
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
  }

  .book-pct {
    font-size: 11px;
    color: var(--accent-green);
    font-family: var(--font-mono);
  }

  .book-rating {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 0px 6px;
    border-radius: 4px;
    font-size: 12px;
    font-family: var(--font-mono);
  }

  .star-icon {
    color: var(--accent-yellow);
    font-size: 14px;
  }

  .rating-value {
    color: var(--text2);
    font-weight: 500;
  }

  .book-rating.detailed {
    flex-direction: column;
    align-items: flex-start;
    gap: 2px;
    margin-top: 6px;
    padding: 4px 8px;
    background: var(--bg3);
    border-radius: 4px;
    font-size: 11px;
  }

  .category-rating-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    width: 100%;
  }

  .category-rating-row.average {
    margin-top: 2px;
    padding-top: 2px;
    border-top: 1px solid var(--border);
  }

  .category-name-label {
    color: var(--text3);
    font-family: var(--font-mono);
    font-size: 10px;
  }

  .category-stars {
    display: flex;
    align-items: center;
    gap: 1px;
  }

  .mini-star {
    font-size: 10px;
    color: var(--border);
    line-height: 1;
  }

  .mini-star.filled {
    color: var(--accent-yellow);
  }

  .book-rating.detailed .star-icon {
    font-size: 11px;
  }

  .book-rating.detailed .rating-value {
    font-size: 11px;
  }

  .book-notes-toggle {
    display: inline-flex;
    width: 100%;
    align-items: center;
    justify-content: space-between;
    gap: 6px;
    font-size: 11px;
    font-family: var(--font-mono);
    color: var(--text2);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 4px 8px;
    margin-top: 8px;
    cursor: pointer;
    transition: all var(--transition);
  }

  .book-notes-toggle:hover {
    border-color: var(--text3);
    color: var(--text2);
  }

  .toggle-icon {
    display: inline-block;
    transition: transform var(--transition);
  }

  .toggle-icon.open {
    transform: rotate(180deg);
  }

  .book-notes { font-size: 12px; color: var(--text2); margin-top: 8px; border-top: 1px solid var(--border); padding-top: 8px; }

  .category-manager {
    margin-bottom: 16px;
    padding: 16px;
  }

  .category-manager h4 {
    margin: 0 0 4px 0;
    font-size: 14px;
    font-weight: 600;
  }

  .category-manager-desc {
    font-size: 12px;
    color: var(--text3);
    margin: 0 0 12px 0;
  }

  .category-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 12px;
  }

  .category-item {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 8px;
    background: var(--bg3);
    border: 1px solid var(--border);
    border-radius: 6px;
    font-size: 12px;
  }

  .category-name {
    color: var(--text2);
  }

  .empty-categories {
    font-size: 12px;
    color: var(--text3);
    margin: 0;
  }

  .add-category {
    display: flex;
    gap: 8px;
  }

  .add-category input {
    flex: 1;
    padding: 6px 10px;
    font-size: 12px;
    border: 1px solid var(--border);
    border-radius: 6px;
    background: var(--bg2);
    color: var(--text1);
  }

  .btn-sm {
    padding: 6px 12px;
    font-size: 12px;
  }

  .modal-lg {
    max-width: 520px;
  }

  .rating-section {
    margin: 16px 0;
    padding: 16px;
    background: var(--bg3);
    border-radius: 12px;
    border: 1px solid var(--border);
  }

  .rating-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
  }

  .rating-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text1);
  }

  .rating-badge {
    font-size: 11px;
    font-weight: 500;
    padding: 3px 8px;
    border-radius: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .badge-simple {
    background: rgba(76, 175, 80, 0.15);
    color: var(--accent-green);
  }

  .rating-stars-container {
    position: relative;
    padding: 12px;
    background: var(--bg2);
    border-radius: 8px;
    border: 1px solid var(--border);
    transition: all var(--transition);
  }

  .rating-stars-container.disabled {
    opacity: 0.6;
    pointer-events: none;
  }

  .disabled-overlay {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(0, 0, 0, 0.5);
    border-radius: 8px;
    font-size: 13px;
    color: var(--text);
    font-weight: 500;
  }

  .star-picker {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 4px;
  }

  .star-picker.small {
    gap: 2px;
  }

  .star-btn {
    background: none;
    border: none;
    font-size: 28px;
    color: var(--border);
    cursor: pointer;
    padding: 0;
    line-height: 1;
    transition: all var(--transition);
  }

  .star-btn:disabled {
    cursor: not-allowed;
  }

  .star-picker.small .star-btn {
    font-size: 18px;
  }

  .star-btn.filled {
    color: var(--accent-yellow);
    transform: scale(1.1);
  }

  .star-btn:hover:not(:disabled) {
    color: var(--accent-yellow);
    transform: scale(1.15);
  }

  .star-label {
    margin-left: 12px;
    font-size: 13px;
    color: var(--text3);
    font-family: var(--font-mono);
    font-weight: 500;
  }

  .toggle-section {
    margin-top: 16px;
    padding-top: 16px;
    border-top: 1px solid var(--border);
  }

  .toggle-label {
    display: flex;
    align-items: center;
    justify-content: space-between;
    cursor: pointer;
  }

  .toggle-text {
    font-size: 13px;
    color: var(--text2);
    font-weight: 500;
  }

  .toggle-switch {
    position: relative;
    width: 44px;
    height: 24px;
    background: var(--border);
    border: none;
    border-radius: 12px;
    cursor: pointer;
    transition: background var(--transition);
    padding: 0;
  }

  .toggle-switch.active {
    background: var(--accent-green);
  }

  .toggle-knob {
    position: absolute;
    top: 2px;
    left: 2px;
    width: 20px;
    height: 20px;
    background: white;
    border-radius: 50%;
    transition: transform var(--transition);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  }

  .toggle-switch.active .toggle-knob {
    transform: translateX(20px);
  }

  .category-ratings-section {
    margin-top: 16px;
    padding: 12px;
    background: var(--bg2);
    border-radius: 8px;
    border: 1px solid var(--border);
    animation: slideDown 0.2s ease-out;
  }

  @keyframes slideDown {
    from {
      opacity: 0;
      transform: translateY(-8px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .no-categories-msg {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    padding: 16px;
    text-align: center;
    font-size: 12px;
    color: var(--text3);
  }

  .no-categories-icon {
    font-size: 24px;
  }

  .category-ratings-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .category-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 8px;
    background: var(--bg3);
    border-radius: 6px;
  }

  .cat-name {
    font-size: 13px;
    color: var(--text2);
    min-width: 100px;
    font-weight: 500;
  }

  .clear-rating-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    margin-left: 4px;
    padding: 0;
    border: none;
    border-radius: 4px;
    color: var(--text3);
    font-size: 10px;
    cursor: pointer;
    transition: all var(--transition);
  }

  .calculated-result {
    margin-top: 16px;
    padding-top: 12px;
    border-top: 1px solid var(--border);
  }

  .result-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 12px;
  }

  .result-label {
    font-size: 13px;
    color: var(--text2);
  }

  .result-value {
    font-size: 16px;
    font-weight: 700;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .result-value.has-value {
    color: var(--accent-yellow);
  }

  .btn-apply {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 10px 16px;
    font-size: 13px;
    font-weight: 600;
    background: var(--accent-green);
    color: var(--text-dark);
    border: none;
    border-radius: 8px;
    cursor: pointer;
    transition: all var(--transition);
  }

  .btn-apply:hover:not(:disabled) {
    opacity: 0.9;
    transform: translateY(-1px);
  }

  .btn-apply:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .apply-warning {
    margin-top: 8px;
    font-size: 11px;
    color: var(--text3);
    text-align: center;
  }

  .applied-confirmation {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 10px;
    background: rgba(76, 175, 80, 0.1);
    border-radius: 8px;
    font-size: 13px;
    color: var(--accent-green);
    font-weight: 500;
  }

  .confirmation-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    background: var(--accent-green);
    color: var(--text-dark);
    border-radius: 50%;
    font-size: 12px;
    font-weight: bold;
  }

  .tab-actions {
    display: flex;
    gap: 8px;
    margin-bottom: 16px;
  }
</style>
