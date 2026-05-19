<script lang="ts">
  import type { Book } from '$lib/types';

  interface Props {
    books?: Book[];
  }

  let { books = [] }: Props = $props();

  const recentBooks = $derived(books.slice(0, 3));

  function bookProgress(book: Book) {
    if (!book.total_pages) return 0;
    return Math.round((book.current_page / book.total_pages) * 100);
  }
</script>

<div class="card">
  <h3 class="card-title">Lecturas <a href="/goals?tab=books" class="card-link">Ver libros →</a></h3>
  {#if recentBooks.length === 0}
    <div class="empty-state">Agrega libros en Visión & Metas</div>
  {:else}
    <div class="book-list">
      {#each recentBooks as book}
        {@const pct = bookProgress(book)}
        <div class="book-item">
          <div class="book-item-cover">
            {#if book.cover_url}
              <img src={book.cover_url} alt={book.title} />
            {:else}
              <span>{book.title[0]}</span>
            {/if}
          </div>
          <div class="book-item-info">
            <div class="book-item-title">{book.title}</div>
            <div class="progress-track" style="margin-top:6px;">
              <div class="progress-fill" style="width:{pct}%;background:var(--accent-green);"></div>
            </div>
            <div class="book-item-pages">{book.current_page}/{book.total_pages} págs — {pct}%</div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .card-title {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-family: var(--font-display);
  }

  .card-link {
    font-size: 12px;
    color: var(--accent-green);
    font-weight: 500;
    font-family: var(--font-body);
  }

  .book-list { display: flex; flex-direction: column; gap: 12px; }

  .book-item { display: flex; gap: 10px; align-items: center; }

  .book-item-cover {
    width: 36px;
    height: 48px;
    background: var(--surface2);
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 16px;
    font-weight: 700;
    color: var(--accent-green);
    flex-shrink: 0;
    overflow: hidden;
  }
  .book-item-cover img { width: 100%; height: 100%; object-fit: cover; }

  .book-item-info { flex: 1; min-width: 0; }

  .book-item-title {
    font-size: 13px;
    font-weight: 500;
    color: var(--text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .book-item-pages {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
    margin-top: 3px;
  }
</style>