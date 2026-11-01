<script lang="ts">
  import type {
    Book,
    BookCategoryRating,
    BookRatingCategory,
  } from "$lib/types";
  import { createRepository } from "$lib/services/repository";
  import { awardXP, XP_VALUES } from "$lib/utils/xp";
  import { renderMd, formatLinks } from "$lib/utils/markdown";
  import CardPreviewModal from "$lib/components/CardPreviewModal.svelte";

  interface Props {
    userId: string;
    books?: Book[];
    onRefresh?: () => void;
  }

  let { userId, books = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showBookModal = $state(false);
  let bookModalMode = $state<"view" | "edit">("view");
  let previewBookId = $state<string | null>(null);
  let editingBook = $state<Book | null>(null);
  let bookForm = $state<Book>({
    title: "",
    current_page: 0,
    total_pages: 0,
    rating_mode: "default",
  });
  let saving = $state(false);

  let ratingCategories = $state<BookRatingCategory[]>([]);
  let categoryRatings = $state<BookCategoryRating[]>([]);
  let newCategoryName = $state("");
  let showCategoryManager = $state(false);
  let detailedModeEnabled = $state(false);
  let detailedModeApplied = $state(false);
  let bookCategoryRatingsMap = $state<Record<string, BookCategoryRating[]>>({});

  const previewBook = $derived(
    books.find((book) => book.id === previewBookId) ?? null,
  );

  function calculateRating(ratings: BookCategoryRating[]): number {
    const validRatings = ratings.filter((r) => r.rating > 0);
    if (validRatings.length === 0) return 0;
    const sum = validRatings.reduce((acc, r) => acc + r.rating, 0);
    return sum / validRatings.length;
  }

  let calculatedRating = $derived.by(() => {
    if (!detailedModeEnabled) return 0;
    return calculateRating(categoryRatings);
  });

  function resetBookForm() {
    bookForm = {
      title: "",
      current_page: 0,
      total_pages: 0,
      rating_mode: "default",
    };
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
    const existing = categoryRatings.find((r) => r.category_id === categoryId);
    return existing?.rating || 0;
  }

  function setCategoryRating(categoryId: string, rating: number) {
    const existing = categoryRatings.find((r) => r.category_id === categoryId);
    if (existing) {
      categoryRatings = categoryRatings.map((r) =>
        r.category_id === categoryId ? { ...r, rating } : r,
      );
    } else {
      categoryRatings = [
        ...categoryRatings,
        {
          book_id: editingBook?.id || "",
          category_id: categoryId,
          rating,
          user_id: userId,
        },
      ];
    }
  }

  async function addCategory() {
    if (!newCategoryName.trim()) return;
    const { data } = await repo.bookRatingCategories.create(
      newCategoryName.trim(),
    );
    if (data) {
      ratingCategories = [...ratingCategories, data];
      newCategoryName = "";
    }
  }

  async function removeCategory(id: string) {
    if (!confirm("¿Eliminar categoría?")) return;
    await repo.bookRatingCategories.remove(id);
    ratingCategories = ratingCategories.filter((c) => c.id !== id);
    categoryRatings = categoryRatings.filter((r) => r.category_id !== id);
  }

  function applyDetailedMode() {
    if (bookForm.rating && bookForm.rating > 0) {
      if (
        !confirm(
          "Esto reemplazará tu calificación simple de " +
            bookForm.rating +
            " estrellas. ¿Continuar?",
        )
      ) {
        return;
      }
    }
    bookForm.rating_mode = "calculated";
    bookForm.rating = calculatedRating > 0 ? calculatedRating : undefined;
    detailedModeApplied = true;
  }

  function disableDetailedMode() {
    bookForm.rating_mode = "default";
    detailedModeEnabled = false;
    detailedModeApplied = false;
  }

  async function saveBook() {
    saving = true;
    let savedBookId = editingBook?.id;
    const isFinished =
      bookForm.current_page >= bookForm.total_pages && bookForm.total_pages > 0;

    const finalRating =
      bookForm.rating_mode === "calculated"
        ? calculatedRating > 0
          ? calculatedRating
          : undefined
        : bookForm.rating;

    const bookData = {
      ...bookForm,
      rating: finalRating,
    };

    if (editingBook?.id) {
      const wasFinished = editingBook.current_page >= editingBook.total_pages;
      bookData.notes = formatLinks(bookData.notes || "");
      await repo.books.update(editingBook.id, {
        ...bookData,
        updated_at: new Date().toISOString(),
      });

      if (bookForm.rating_mode === "calculated" && editingBook.id) {
        const ratingsToSave = categoryRatings.map((r) => ({
          category_id: r.category_id,
          rating: r.rating,
        }));
        await repo.bookCategoryRatings.upsertMany(
          editingBook.id,
          ratingsToSave,
        );
      }

      if (isFinished && !wasFinished)
        await awardXP(
          userId,
          "education",
          "book_finished",
          XP_VALUES.book_finished,
          editingBook.id,
          bookForm.title,
        );
      else
        await awardXP(
          userId,
          "education",
          "book_page_update",
          XP_VALUES.book_page_update,
          undefined,
          bookForm.title,
        );
    } else {
      const { data } = await repo.books.insert(bookData);
      if (data) {
        savedBookId = data.id;
        if (bookForm.rating_mode === "calculated") {
          const ratingsToSave = categoryRatings.map((r) => ({
            category_id: r.category_id,
            rating: r.rating,
          }));
          await repo.bookCategoryRatings.upsertMany(data.id, ratingsToSave);
        }
        if (isFinished)
          await awardXP(
            userId,
            "education",
            "book_finished",
            XP_VALUES.book_finished,
            data.id,
            bookForm.title,
          );
      }
    }

    const { data } = await repo.books.list();
    books = data || [];
    if (savedBookId) {
      const ratings = { ...bookCategoryRatingsMap };
      if (bookForm.rating_mode === "calculated") {
        ratings[savedBookId] = categoryRatings;
      } else {
        delete ratings[savedBookId];
      }
      bookCategoryRatingsMap = ratings;
      previewBookId = savedBookId;
      bookModalMode = "view";
      resetBookForm();
    }
    saving = false;
  }

  async function editBook(b: Book) {
    editingBook = b;
    categoryRatings = [];
    bookForm = { ...b, rating_mode: b.rating_mode || "default" };
    detailedModeEnabled = b.rating_mode === "calculated";
    detailedModeApplied = b.rating_mode === "calculated";
    bookModalMode = "edit";
    showBookModal = true;
    await loadCategoryRatings(b.id || "");
  }

  function openBookPreview(book: Book) {
    previewBookId = book.id ?? null;
    bookModalMode = "view";
    showBookModal = true;
  }

  function openNewBook() {
    previewBookId = null;
    resetBookForm();
    bookModalMode = "edit";
    showBookModal = true;
  }

  function cancelBookEdit() {
    resetBookForm();
  }

  function closeBookModal() {
    showBookModal = false;
    previewBookId = null;
    resetBookForm();
  }

  async function deleteBook(id: string) {
    if (!confirm("¿Eliminar libro?")) return;
    await repo.books.remove(id);
    const { data } = await repo.books.list();
    books = data || [];
  }

  function bookProgress(b: Book) {
    return b.total_pages
      ? Math.round((b.current_page / b.total_pages) * 100)
      : 0;
  }

  function getBookDisplayRating(book: Book): number {
    if (book.rating_mode === "default") {
      return book.rating || 0;
    }
    if (book.rating_mode === "calculated") {
      const ratings = bookCategoryRatingsMap[book.id || ""] || [];
      return calculateRating(ratings);
    }
    return book.rating || 0;
  }

  async function loadAllCalculatedBookRatings() {
    const calculatedBooks = books.filter(
      (b) => b.rating_mode === "calculated" && b.id,
    );
    const entries: [string, BookCategoryRating[]][] = await Promise.all(
      calculatedBooks.map(async (b) => {
        const { data } = await repo.bookCategoryRatings.listByBook(b.id!);
        return [b.id!, data || []];
      }),
    );
    bookCategoryRatingsMap = Object.fromEntries(entries);
  }

  $effect(() => {
    if (showBookModal) {
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
    <button class="btn btn-primary" onclick={openNewBook}
      >+ Agregar libro</button
    >
    <button
      class="btn btn-secondary"
      onclick={() => {
        showCategoryManager = !showCategoryManager;
        loadRatingCategories();
      }}
    >
      {showCategoryManager ? "Ocultar categorías" : "⚙ Categorías"}
    </button>
  </div>

  {#if showCategoryManager}
    <div class="category-manager card">
      <h4>Categorías de calificación</h4>
      <p class="category-manager-desc">
        Define las categorías que usarás para calificar libros
      </p>
      <div class="category-list">
        {#each ratingCategories as cat, i}
          <div class="category-item">
            <span class="category-name">{cat.name}</span>
            <button
              class="small-btn btn-ghost"
              onclick={() => removeCategory(cat.id!)}>✕</button
            >
          </div>
        {/each}
        {#if ratingCategories.length === 0}
          <p class="empty-categories">No hay categorías definidas</p>
        {/if}
      </div>
      <div class="add-category">
        <input
          bind:value={newCategoryName}
          placeholder="Nueva categoría (ej: Romántico)"
          onkeydown={(e) => {
            if (e.key === "Enter") addCategory();
          }}
        />
        <button
          type="button"
          class="btn btn-primary btn-sm"
          onclick={addCategory}>+</button
        >
      </div>
    </div>
  {/if}

  <div class="books-grid">
    {#each books as book}
      {@const pct = bookProgress(book)}
      {@const displayRating = getBookDisplayRating(book)}
      <article class="book-card item-card card" class:finished={pct >= 100}>
        <button
          class="book-preview-trigger"
          type="button"
          aria-label="Ver detalles de {book.title}"
          onclick={() => openBookPreview(book)}
        >
          <div class="book-cover-info">
            <div class="book-cover-rating">
              <div class="book-cover">
                {#if book.cover_url}
                  <img src={book.cover_url} alt="" />
                {:else}
                  <span aria-hidden="true">{book.title[0]}</span>
                {/if}
              </div>
            </div>
            <div class="book-info">
              <div class="book-header item-card-header">
                <h3 class="book-title">{book.title}</h3>
              </div>
              <div class="book-progress">
                <div class="book-progress-label">
                  {book.current_page} / {book.total_pages} págs
                </div>
                <div class="progress-track" style="margin:6px 0;">
                  <div
                    class="progress-fill"
                    style="width:{pct}%;background:{pct >= 100
                      ? 'var(--accent-yellow)'
                      : 'var(--accent-green)'};"
                  ></div>
                </div>
                <div class="book-pct">
                  {pct >= 100 ? "100%" : `${pct}%`}
                  {#if pct >= 100}
                    <span class="book-finished-badge">✓ Terminado</span>
                  {/if}
                </div>
              </div>
            </div>
          </div>
        </button>
        <div class="item-card-footer">
          {#if displayRating > 0}
            <div class="book-rating">
              <span class="star-icon" aria-hidden="true">★</span>
              <span class="rating-value">{displayRating.toFixed(1)}</span>
            </div>
          {:else}
            <span></span>
          {/if}
          <div class="item-card-actions">
            <button
              class="icon-action"
              type="button"
              aria-label="Editar libro"
              onclick={() => editBook(book)}>🖋</button
            >
            <button
              class="icon-action danger"
              type="button"
              aria-label="Eliminar libro"
              onclick={() => deleteBook(book.id!)}>✕</button
            >
          </div>
        </div>
      </article>
    {/each}
    {#if books.length === 0}
      <div class="empty-state card">Agrega tu primer libro 📖</div>
    {/if}
  </div>
</div>

{#if showBookModal}
  <CardPreviewModal
    title={bookModalMode === "view"
      ? (previewBook?.title ?? "Libro")
      : editingBook
        ? "Editar libro"
        : "Nuevo libro"}
    bind:mode={bookModalMode}
    viewAvailable={!!previewBook}
    {saving}
    onclose={closeBookModal}
    onedit={() => previewBook && editBook(previewBook)}
    oncancel={cancelBookEdit}
    onsave={saveBook}
  >
    {#snippet view()}
      {#if previewBook}
        {@const pct = bookProgress(previewBook)}
        {@const ratings = bookCategoryRatingsMap[previewBook.id || ""] || []}
        <div class="book-preview">
          <div class="book-preview-main">
            {#if previewBook.cover_url}
              <img
                class="book-preview-cover"
                src={previewBook.cover_url}
                alt=""
              />
            {/if}
            <div class="book-preview-summary">
              <h3>{previewBook.title}</h3>
              <div>
                {previewBook.current_page} / {previewBook.total_pages} páginas
              </div>
              <div class="progress-track">
                <div
                  class="progress-fill"
                  style="width:{pct}%;background:{pct >= 100
                    ? 'var(--accent-yellow)'
                    : 'var(--accent-green)'};"
                ></div>
              </div>
              <div class="book-pct">{pct}% completado</div>
            </div>
          </div>
          {#if previewBook.rating_mode === "calculated"}
            <section
              class="book-preview-ratings"
              aria-label="Calificación por categorías"
            >
              <h3>Calificación por categorías</h3>
              {#each ratingCategories as category}
                {@const rating =
                  ratings.find((item) => item.category_id === category.id)
                    ?.rating ?? 0}
                <div class="book-preview-rating-row">
                  <span>{category.name}</span>
                  <span>{rating > 0 ? `${rating}/5` : "Sin calificar"}</span>
                </div>
              {/each}
              <div class="book-preview-rating-row average">
                <strong>Promedio</strong>
                <strong
                  >{getBookDisplayRating(previewBook).toFixed(1)} / 5</strong
                >
              </div>
            </section>
          {:else if previewBook.rating}
            <div class="book-preview-ratings">
              Calificación: {previewBook.rating} / 5
            </div>
          {/if}
          <section class="book-preview-notes">
            <h3>Notas</h3>
            {#if previewBook.notes}
              <div class="book-notes">{@html renderMd(previewBook.notes)}</div>
            {:else}
              <p class="book-preview-empty">Sin notas</p>
            {/if}
          </section>
        </div>
      {/if}
    {/snippet}

    {#snippet form()}
      <div class="form-group">
        <label for="book-title">Título</label>
        <input
          id="book-title"
          bind:value={bookForm.title}
          placeholder="Nombre del libro"
        />
      </div>
      <div class="grid-2">
        <div class="form-group">
          <label for="book-current">Página actual</label>
          <input
            id="book-current"
            type="number"
            bind:value={bookForm.current_page}
            min="0"
          />
        </div>
        <div class="form-group">
          <label for="book-total">Total páginas</label>
          <input
            id="book-total"
            type="number"
            bind:value={bookForm.total_pages}
            min="0"
          />
        </div>
      </div>
      <div class="form-group">
        <label for="book-cover">URL portada (opcional)</label>
        <input
          id="book-cover"
          type="url"
          bind:value={bookForm.cover_url}
          placeholder="https://..."
        />
      </div>
      <div class="form-group">
        <label for="book-notes">Notas</label>
        <textarea
          id="book-notes"
          bind:value={bookForm.notes}
          rows="8"
          placeholder="Reflexiones..."></textarea>
      </div>

      <div class="rating-section">
        <div class="rating-header">
          <span class="rating-title">Calificación</span>
          <span class="rating-badge badge-simple"
            >Modo {detailedModeEnabled ? "detallado" : "simple"}</span
          >
        </div>

        <div
          class="rating-stars-container"
          class:disabled={detailedModeEnabled}
        >
          <div class="star-picker">
            {#each [1, 2, 3, 4, 5] as s}
              <button
                type="button"
                class="star-btn"
                class:filled={s <= (bookForm.rating || 0)}
                onclick={() => {
                  if (!detailedModeEnabled)
                    bookForm.rating = bookForm.rating === s ? 0 : s;
                }}
                disabled={detailedModeEnabled}
                aria-label={`${s} estrellas`}
              >
                ★
              </button>
            {/each}
            <span class="star-label"
              >{bookForm.rating
                ? `${bookForm.rating}/5`
                : "Sin calificar"}</span
            >
          </div>
          {#if detailedModeEnabled}
            <div class="disabled-overlay">
              <span>↓ Califica por categorías ↓</span>
            </div>
          {/if}
        </div>

        <div class="toggle-section">
          <label class="toggle-label">
            <span class="toggle-text"
              >Calificación detallada por categorías</span
            >
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
                <span
                  >No hay categorías definidas. Crea categorías primero con el
                  botón "⚙ Categorías".</span
                >
              </div>
            {:else}
              <div class="category-ratings-list">
                {#each ratingCategories as cat}
                  <div class="category-row">
                    <span class="cat-name">{cat.name}</span>
                    <div class="star-picker small">
                      {#each [1, 2, 3, 4, 5] as s}
                        <button
                          type="button"
                          class="star-btn"
                          class:filled={s <= getCategoryRating(cat.id || "")}
                          onclick={() =>
                            setCategoryRating(
                              cat.id || "",
                              getCategoryRating(cat.id || "") === s ? 0 : s,
                            )}
                          aria-label={`${s} estrellas para ${cat.name}`}
                        >
                          ★
                        </button>
                      {/each}
                      {#if getCategoryRating(cat.id || "") > 0}
                        <button
                          type="button"
                          class="clear-rating-btn"
                          onclick={() => setCategoryRating(cat.id || "", 0)}
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
                  <span
                    class="result-value"
                    class:has-value={calculatedRating > 0}
                  >
                    {calculatedRating > 0
                      ? `${calculatedRating.toFixed(1)} / 5`
                      : "—"}
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
                      ⚠ Esto reemplazará tu calificación simple de {bookForm.rating}
                      estrellas
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
    {/snippet}
  </CardPreviewModal>
{/if}

<style>
  .books-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    grid-auto-rows: 1fr;
    gap: 16px;
  }

  .book-card {
    display: flex;
    flex-direction: column;
    transition: transform var(--transition);
  }

  .book-card:hover {
    transform: translateY(-2px);
  }

  .book-card.finished {
    border: 3px solid var(--accent-yellow);
  }

  .book-finished-badge {
    background: var(--accent-yellow);
    color: var(--bg);
    font-family: var(--font-mono);
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.04em;
    padding: 3px 8px;
    border-radius: 999px;
    white-space: nowrap;
  }

  .book-header {
    min-width: 0;
  }

  .book-preview-trigger {
    display: flex;
    flex: 1;
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
    width: 100%;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    text-align: left;
    cursor: pointer;
  }

  .book-preview-trigger:focus-visible {
    outline: 2px solid var(--accent);
    outline-offset: 4px;
    border-radius: var(--radius-sm);
  }

  .book-cover-info {
    display: flex;
    gap: 14px;
    flex: 1;
    min-height: 0;
    margin-bottom: 4px;
  }

  .book-cover-rating {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
  }

  .book-cover {
    width: 72px;
    height: 108px;
    border-radius: 6px;
    background: var(--surface2);
    font-size: 24px;
    font-weight: 700;
    color: var(--accent);
    overflow: hidden;
  }

  .book-cover img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .book-info {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
  }

  .book-title {
    flex: 1;
    min-width: 0;
    font-weight: 700;
    font-size: 15px;
    line-height: 1.3;
    margin: 0;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .book-progress {
    margin-top: 8px;
  }

  .book-progress-label {
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
  }

  .book-pct {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 12px;
    color: var(--accent-green);
    font-family: var(--font-mono);
    margin-bottom: 4px;
  }

  .book-rating {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 0px 6px;
    border-radius: 4px;
    font-size: 14px;
    font-family: var(--font-mono);
    margin-bottom: 2px;
  }

  .star-icon {
    color: var(--accent-yellow);
    font-size: 14px;
  }

  .rating-value {
    color: var(--text2);
    font-weight: 500;
  }

  .book-notes-preview {
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    overflow: hidden;
    color: var(--text2);
    font-size: 12px;
    line-height: 1.45;
    white-space: pre-wrap;
  }

  .book-notes {
    font-size: 12px;
    color: var(--text2);
    margin-top: 8px;
    border-top: 1px solid var(--border);
    padding-top: 8px;
  }

  .book-preview {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .book-preview-main {
    display: flex;
    align-items: flex-start;
    gap: 16px;
  }

  .book-preview-cover {
    width: 96px;
    max-height: 144px;
    border-radius: 6px;
    object-fit: cover;
  }

  .book-preview-summary {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: 8px;
    min-width: 0;
  }

  .book-preview-ratings,
  .book-preview-notes {
    padding-top: 14px;
    border-top: 1px solid var(--border);
  }

  .book-preview-ratings h3,
  .book-preview-notes h3 {
    margin-bottom: 10px;
    font-size: 14px;
  }

  .book-preview-rating-row {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 6px 0;
    color: var(--text2);
    font-size: 13px;
  }

  .book-preview-rating-row.average {
    margin-top: 4px;
    padding-top: 10px;
    border-top: 1px solid var(--border);
    color: var(--text);
  }

  .book-preview-empty {
    color: var(--text3);
    font-style: italic;
  }

  @media (max-width: 480px) {
    .book-preview-main {
      flex-direction: column;
    }
  }

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
    font-weight: 400;
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
    background: var(--accent);
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
