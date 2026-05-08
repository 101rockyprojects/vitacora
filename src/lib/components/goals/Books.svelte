<script lang="ts">
  import type { Book } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';

  interface Props {
    userId: string;
    books?: Book[];
    onRefresh?: () => void;
  }

  let { userId, books = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showBookForm = $state(false);
  let editingBook = $state<Book | null>(null);
  let bookForm = $state<Book>({ title: '', current_page: 0, total_pages: 0 });
  let expandedBookNotes = $state<string[]>([]);
  let saving = $state(false);

  const expandedBookNotesSet = $derived(new Set(expandedBookNotes));

  function toggleBookNotes(bookId: string) {
    if (expandedBookNotesSet.has(bookId)) {
      expandedBookNotes = expandedBookNotes.filter(id => id !== bookId);
    } else {
      expandedBookNotes = [...expandedBookNotes, bookId];
    }
  }

  function resetBookForm() { bookForm = { title: '', current_page: 0, total_pages: 0 }; editingBook = null; }

  async function saveBook() {
    saving = true;
    const isFinished = bookForm.current_page >= bookForm.total_pages && bookForm.total_pages > 0;
    if (editingBook?.id) {
      const wasFinished = editingBook.current_page >= editingBook.total_pages;
      await repo.books.update(editingBook.id, { ...bookForm, updated_at: new Date().toISOString() });
      if (isFinished && !wasFinished) await awardXP(userId, 'education', 'book_finished', XP_VALUES.book_finished, editingBook.id);
      else await awardXP(userId, 'education', 'book_page_update', XP_VALUES.book_page_update);
    } else {
      const { data } = await repo.books.insert(bookForm);
      if (isFinished && data) await awardXP(userId, 'education', 'book_finished', XP_VALUES.book_finished, data.id);
    }
    const { data } = await repo.books.list();
    books = data || [];
    showBookForm = false;
    resetBookForm();
    saving = false;
  }

  function editBook(b: Book) { editingBook = b; bookForm = { ...b }; showBookForm = true; }

  async function deleteBook(id: string) {
    if (!confirm('¿Eliminar libro?')) return;
    await repo.books.remove(id);
    const { data } = await repo.books.list();
    books = data || [];
  }

  function bookProgress(b: Book) {
    return b.total_pages ? Math.round((b.current_page / b.total_pages) * 100) : 0;
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { resetBookForm(); showBookForm = true; }}>+ Agregar libro</button>
  </div>
  <div class="books-grid">
    {#each books as book}
      {@const pct = bookProgress(book)}
      {@const showNotes = expandedBookNotesSet.has(book.id || '')}
      <div class="book-card card" class:finished={pct >= 100}>
        <div class="book-cover-info">
          <div class="book-cover">
            {#if book.cover_url}
              <img src={book.cover_url} alt={book.title} />
            {:else}
              <span>{book.title[0]}</span>
            {/if}
          </div>
          <div class="book-info">
            <div class="book-title">{book.title}</div>
            <div class="book-progress-label">{book.current_page} / {book.total_pages} págs</div>
            <div class="progress-track" style="margin:6px 0;">
              <div class="progress-fill" style="width:{pct}%;background:{pct>=100?'var(--accent-yellow)':'var(--accent-green)'};"></div>
            </div>
            <div class="book-pct">{pct}% {pct >= 100 ? '✓ Terminado' : ''}</div>
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
            <div class="book-notes">{book.notes}</div>
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
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="book-form-title">
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
          <textarea id="book-notes" bind:value={bookForm.notes} rows="3" placeholder="Reflexiones..."></textarea>
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
    transition: transform var(--transition);
  }

  .book-card:hover { transform: translateY(-2px); }

  .book-card.finished { border-color: var(--accent-yellow); }

  .book-cover-info {
    display: flex;
    gap: 14px;
  }

  .book-cover {
    width: 48px;
    height: 64px;
    border-radius: 4px;
    background: var(--surface2);
    display: flex;
    align-items: center;
    justify-content: center;
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
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .book-pct {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .book-notes-toggle {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    font-family: var(--font-mono);
    color: var(--text3);
    background: var(--bg3);
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

  .book-notes-toggle {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: var(--text3);
    background: none;
    border: none;
    cursor: pointer;
    padding: 0;
    margin-top: 8px;
  }

  .book-notes-toggle:hover { color: var(--text2); }

  .toggle-icon { display: inline-block; transition: transform var(--transition); }
  .toggle-icon.open { transform: rotate(180deg); }

  .book-notes {
    font-size: 12px;
    color: var(--text2);
    margin-top: 8px;
    padding: 10px;
    background: var(--bg3);
    border-radius: 8px;
    line-height: 1.5;
  }
</style>