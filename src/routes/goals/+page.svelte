<script lang="ts">
  import { page } from '$app/state';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import { onDestroy, tick } from 'svelte';
  import 'gridstack/dist/gridstack.min.css';
  import type { Book, LearningItem, SuccessExperience, Reward, MemoryPhoto, CalendarEvent } from '$lib/types';

  // --- State ---
  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let activeTab = $state<'vision' | 'books' | 'learning' | 'memories' | 'calendar' | 'successes' | 'rewards'>('vision');

  // Books
  let books = $state<Book[]>([]);
  let showBookForm = $state(false);
  let editingBook = $state<Book | null>(null);
  let bookForm = $state<Book>({ title: '', current_page: 0, total_pages: 0 });

  // Learning
  let learning = $state<LearningItem[]>([]);
  let showLearnForm = $state(false);
  let learnForm = $state<LearningItem>({ topic: '' });

  // Memories
  const memory_size_limit_kb = 999;
  let memories = $state<MemoryPhoto[]>([]);
  let showMemForm = $state(false);
  let memForm = $state<MemoryPhoto>({ date: '', description: '' });
  let memFile = $state<File | null>(null);
  let memImageMode = $state<'file' | 'link'>('file');
  let memImageLink = $state('');
  let memGridEl = $state<HTMLElement | null>(null);
  let memGrid = $state<any>(null);

  // Calendar
  let calEvents = $state<CalendarEvent[]>([]);
  let showCalForm = $state(false);
  let calForm = $state<CalendarEvent>({ event_name: '', event_date: '', type: 'event' });

  // Successes
  let successes = $state<SuccessExperience[]>([]);
  let showSuccessForm = $state(false);
  let successForm = $state<SuccessExperience>({ goal_description: '', done: false });
  let editingSuccessId = $state<string | null>(null);
  const editingSuccess = $derived(editingSuccessId ? successes.find(s => s.id === editingSuccessId) ?? null : null);

  $effect(() => {
    if (editingSuccess?.done) {
      successForm.done = true;
    }
  });

  // Rewards
  let rewards = $state<Reward[]>([]);
  let showRewardForm = $state(false);
  let rewardForm = $state<Reward>({ achievement_name: '', reward_given: '', date_awarded: new Date().toISOString().split('T')[0] });

  let saving = $state(false);

  const motivationalPhrases = [
    "¿cuánto más podríamos avanzar si no tuviéramos que cargar con nuestros miedos a cuestas?",
    "No se trata de por qué peleo sino por quién",
    "DO not waste your potential",
    "¡commit yourself!",
    "YOU WILL NOT FAIL IF IT IS WORTH IT",
    "Cuando miro a la cima de la montaña, en mi mente ya he fracasado es entonces que comienzo a escalar",
    "1% better every day"
  ];

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadAll();
    }
  });

  async function loadAll() {
    if (!userId) return;
    const [b, l, m, c, s, r] = await Promise.all([
      repo.books.list(),
      repo.learning.list(),
      repo.memories.list(),
      repo.calendar.list(),
      repo.successes.list(),
      repo.rewards.list()
    ]);
    books = b.data || [];
    learning = l.data || [];
    memories = m.data || [];
    calEvents = c.data || [];
    successes = s.data || [];
    rewards = r.data || [];
  }

  $effect(() => {
    if (activeTab !== 'memories') {
      if (memGrid) {
        memGrid.destroy(false);
        memGrid = null;
      }
      return;
    }
    if (typeof window === 'undefined' || !memGridEl) return;
    memories.length;
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
    // Auto-size based on aspect ratio, but keep it reasonable.
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

  function slugify(text: string): string {
    return text.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]+/g, '');
  }

  function toIsoDateLocal(d: Date): string {
    return d.toLocaleDateString('en-CA'); // YYYY-MM-DD local
  }

  function startOfWeekSunday(d: Date): Date {
    const start = new Date(d);
    start.setHours(0, 0, 0, 0);
    start.setDate(start.getDate() - start.getDay());
    return start;
  }

  const todayIso = $derived(toIsoDateLocal(new Date()));

  const weekDays = $derived((() => {
    const start = startOfWeekSunday(new Date());
    const days: Array<{
      iso: string;
      date: Date;
      weekday: string;
      specialTitles: string[];
      events: CalendarEvent[];
    }> = [];

    for (let i = 0; i < 7; i++) {
      const date = new Date(start);
      date.setDate(start.getDate() + i);
      const iso = toIsoDateLocal(date);
      const dayEvents = calEvents.filter(e => e.event_date === iso);
      const specialTitles = dayEvents.filter(e => e.type === 'special_day').map(e => e.event_name);
      const events = dayEvents.filter(e => e.type !== 'special_day');
      days.push({
        iso,
        date,
        weekday: date.toLocaleDateString('es-ES', { weekday: 'long' }),
        specialTitles,
        events
      });
    }
    return days;
  })());

  function bookProgress(b: Book) {
    return b.total_pages ? Math.round((b.current_page / b.total_pages) * 100) : 0;
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
    await loadAll();
    showBookForm = false;
    resetBookForm();
    saving = false;
  }

  function editBook(b: Book) { editingBook = b; bookForm = { ...b }; showBookForm = true; }

  async function deleteBook(id: string) {
    if (!confirm('¿Eliminar libro?')) return;
    await repo.books.remove(id);
    await loadAll();
  }

  async function saveLearn() {
    saving = true;
    await repo.learning.insert(learnForm);
    await awardXP(userId, 'education', 'learning_added', XP_VALUES.learning_added);
    learnForm = { topic: '' };
    showLearnForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteLearn(id: string) {
    if (!confirm('¿Eliminar tema?')) return;
    await repo.learning.remove(id);
    await loadAll();
  }

  async function saveMem() {
    saving = true;
    let photo_path = '';
    const link = memImageLink.trim();
    if (memImageMode === 'link' && link) {
      photo_path = link; // URL directa
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

    await loadAll();
    saving = false;
  }

  async function deleteMem(id: string) {
    if (!confirm('¿Eliminar recuerdo?')) return;
    await repo.memories.remove(id);
    await repo.storage.getMemorySignedUrl(`${userId}/${id}`).then(url => {
      if (url) repo.storage.deleteMemory(`${userId}/${id}`);
    });
    await loadAll();
  }

  async function saveCal() {
    saving = true;
    await repo.calendar.insert(calForm);
    calForm = { event_name: '', event_date: '', type: 'event' };
    showCalForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteCal(id: string) {
    if (!confirm('¿Eliminar evento?')) return;
    await repo.calendar.remove(id);
    await loadAll();
  }

  async function saveSuccess() {
    saving = true;
    const wasDone = editingSuccess?.done ?? false;
    const wantsDone = !!successForm.done;

    if (wantsDone && !wasDone) {
      const ok = confirm('¿Marcar como completado? Esto no se podrá deshacer.');
      if (!ok) { saving = false; return; }
    }

    if (editingSuccessId) {
      await repo.successes.update(editingSuccessId, {
        goal_description: successForm.goal_description,
        reflection: successForm.reflection,
        done: wasDone ? true : wantsDone,
        completed_date: wasDone ? editingSuccess?.completed_date ?? new Date().toISOString() : (wantsDone ? new Date().toISOString() : null)
      });
      if (wantsDone && !wasDone) await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, editingSuccessId);
    } else {
      const { data } = await repo.successes.insert({
        ...successForm,
        done: wantsDone,
        completed_date: wantsDone ? new Date().toISOString() : null
      });
      if (wantsDone && data) await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, data.id);
    }
    successForm = { goal_description: '', done: false };
    editingSuccessId = null;
    showSuccessForm = false;
    await loadAll();
    saving = false;
  }

  async function toggleSuccess(s: SuccessExperience) {
    if (s.done) return;
    const ok = confirm('¿Marcar como completado? Esto no se podrá deshacer.');
    if (!ok) return;
    await repo.successes.update(s.id!, { done: true, completed_date: new Date().toISOString() });
    await awardXP(userId, 'selfcare', 'success_experience', XP_VALUES.success_experience, s.id);
    await loadAll();
  }

  function openNewSuccess() {
    editingSuccessId = null;
    successForm = { goal_description: '', done: false };
    showSuccessForm = true;
  }

  function openEditSuccess(s: SuccessExperience) {
    editingSuccessId = s.id || null;
    successForm = { ...s, done: !!s.done };
    showSuccessForm = true;
  }

  function closeSuccessForm() {
    showSuccessForm = false;
    editingSuccessId = null;
    successForm = { goal_description: '', done: false };
  }

  async function deleteSuccess(id: string) {
    if (!confirm('¿Eliminar logro?')) return;
    await repo.successes.remove(id);
    await loadAll();
  }

  async function saveReward() {
    saving = true;
    await repo.rewards.insert(rewardForm);
    await awardXP(userId, 'selfcare', 'reward_earned', XP_VALUES.reward_earned);
    rewardForm = { achievement_name: '', reward_given: '', date_awarded: new Date().toISOString().split('T')[0] };
    showRewardForm = false;
    await loadAll();
    saving = false;
  }

  async function deleteReward(id: string) {
    if (!confirm('¿Eliminar recompensa?')) return;
    await repo.rewards.remove(id);
    await loadAll();
  }

  const tabs = [
    { id: 'vision', label: 'Visión', icon: '✦' },
    { id: 'books', label: 'Libros', icon: '📚' },
    { id: 'learning', label: 'Aprendizaje', icon: '🧠' },
    { id: 'memories', label: 'Memorias', icon: '📸' },
    { id: 'calendar', label: 'Calendario', icon: '📅' },
    { id: 'successes', label: 'Logros', icon: '🏆' },
    { id: 'rewards', label: 'Recompensas', icon: '🎁' }
  ] as const;
</script>

<div class="goals-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Visión & Metas</h2>
      <div class="section-subtitle">Tu espacio de crecimiento</div>
    </div>
  </div>

  <!-- Tabs -->
  <div class="tabs-bar">
    {#each tabs as tab}
      <button class="tab-btn" class:active={activeTab === tab.id} onclick={() => activeTab = tab.id as typeof activeTab}>
        <span>{tab.icon}</span> {tab.label}
      </button>
    {/each}
  </div>

  <!-- VISION BOARD -->
  {#if activeTab === 'vision'}
    <div class="vision-section fade-in">
      <div class="vision-board-placeholder card">
        <div class="vb-inner">
          <span class="vb-icon">🖼️</span>
          <p>Tu Vision Board</p>
        </div>
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

  <!-- BOOKS -->
  {:else if activeTab === 'books'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { resetBookForm(); showBookForm = true; }}>+ Agregar libro</button>
      </div>
      <div class="books-grid">
        {#each books as book}
          {@const pct = bookProgress(book)}
          <div class="book-card card" class:finished={pct >= 100}>
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
              {#if book.notes}
                <div class="book-notes">{book.notes}</div>
              {/if}
            </div>
            <div class="card-actions">
              <button class="btn btn-ghost" onclick={() => editBook(book)}>✎</button>
              <button class="btn btn-ghost" onclick={() => deleteBook(book.id!)}>✕</button>
            </div>
          </div>
        {/each}
        {#if books.length === 0}
          <div class="empty-state card">Agrega tu primer libro 📖</div>
        {/if}
      </div>
    </div>

  <!-- LEARNING -->
  {:else if activeTab === 'learning'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { learnForm = { topic: '' }; showLearnForm = true; }}>+ Agregar tema</button>
      </div>
      <div class="learn-list">
        {#each learning as item}
          <div class="learn-card card">
            <div class="learn-main">
              <div class="learn-topic">{item.topic}</div>
              {#if item.resource_link}
                <a href={item.resource_link} target="_blank" class="learn-link">🔗 Recurso</a>
              {/if}
              {#if item.notes}
                <div class="learn-notes">{item.notes}</div>
              {/if}
            </div>
            {#if item.image_url}
              <img src={item.image_url} alt="screenshot" class="learn-thumb" />
            {/if}
            <button class="btn btn-ghost" onclick={() => deleteLearn(item.id!)}>✕</button>
          </div>
        {/each}
        {#if learning.length === 0}
          <div class="empty-state card">Empieza a registrar lo que aprendes 🧠</div>
        {/if}
      </div>
    </div>

  <!-- MEMORIES -->
  {:else if activeTab === 'memories'}
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
              class="grid-stack-item"
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
                  <button type="button" class="mem-drag" aria-label="Drag">::</button>
                  {#if mem.photo_url}
                    <img src={mem.photo_url} alt={mem.description} class="mem-photo" onload={(e) => onMemoryImageLoad(mem.id!, e)} />
                  {:else}
                    <div class="mem-placeholder">📷</div>
                  {/if}
                  <div class="mem-info">
                    <div class="mem-date">{new Date(mem.date).toLocaleDateString('es-ES')}</div>
                    <div class="mem-desc">{mem.description}</div>
                  </div>
                  {#if mem.photo_url}
                    <a class="mem-open" href={mem.photo_url} target="_blank" rel="noreferrer">ver</a>
                  {/if}
                  <button class="mem-delete btn btn-ghost" onclick={() => deleteMem(mem.id!)}>✕</button>
                </div>
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </div>

  <!-- CALENDAR -->
  {:else if activeTab === 'calendar'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { calForm = { event_name: '', event_date: '', type: 'event' }; showCalForm = true; }}>+ Agregar evento</button>
      </div>
      <!-- WEEK PLANNER -->
      <div class="week-title">Semana actual</div>
      <div class="week-section week-grid">
        {#each weekDays as d (d.iso)}
          {@const isToday = d.iso === todayIso}
          {@const isSpecial = d.specialTitles.length > 0}
          <div class="week-col">
            <div class="week-header" class:current={isToday} class:special={!isToday && isSpecial}>
              <div class="week-header-top">
                <div class="week-day">{d.weekday}</div>
                <div class="week-date">{d.date.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' })}</div>
              </div>
              {#if isSpecial}
                <div class="week-special">{d.specialTitles.join(' · ')}</div>
              {/if}
            </div>

            <div class="week-body">
              {#if d.events.length === 0}
                <div class="week-empty">{isSpecial ? 'Sin eventos' : '—'}</div>
              {:else}
                <div class="week-list">
                  {#each d.events as ev (ev.id)}
                    <a class="week-event" href={`#event-${slugify(ev.event_name)}`}>{ev.event_name}</a>
                  {/each}
                </div>
              {/if}
            </div>
          </div>
        {/each}
      </div>

      <!-- LIST OF EVENTS -->
      <div class="week-section cal-list">
        <div class="week-title">Eventos</div>
        {#each calEvents as ev}
          <div class="cal-card card" id="event-{slugify(ev.event_name)}">
            <div class="cal-dot" style="background:{ev.type === 'special_day' ? 'var(--accent-yellow)' : 'var(--accent-green)'}"></div>
            <div class="cal-info">
              <div class="cal-name">{ev.event_name}</div>
              <div class="cal-date">{new Date(ev.event_date).toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</div>
              <span class="tag" style="background:var(--bg3);color:var(--text3)">{ev.type === 'special_day' ? '⭐ Día especial' : '📅 Evento'}</span>
            </div>
            <button class="btn btn-ghost" onclick={() => deleteCal(ev.id!)}>✕</button>
          </div>
        {/each}
        {#if calEvents.length === 0}
          <div class="empty-state card">Agrega tus fechas importantes 📅</div>
        {/if}
      </div>
    </div>

  <!-- SUCCESSES -->
  {:else if activeTab === 'successes'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={openNewSuccess}>+ Nueva meta</button>
      </div>
      <div class="success-list">
        {#each successes as s}
          <div class="success-card card" class:done={s.done}>
            <button class="success-check" class:checked={s.done} onclick={() => toggleSuccess(s)} disabled={s.done} aria-label="Marcar como completado">
              {s.done ? '✓' : ''}
            </button>
            <div class="success-info">
              <div class="success-goal">{s.goal_description}</div>
              {#if s.reflection}
                <div class="success-reflection">"{s.reflection}"</div>
              {/if}
              {#if s.completed_date}
                <div class="success-date">Completado: {new Date(s.completed_date).toLocaleDateString('es-ES')}</div>
              {/if}
            </div>
            <button class="btn btn-secondary" onclick={() => openEditSuccess(s)}>Editar</button>
            <button class="btn btn-ghost" onclick={() => deleteSuccess(s.id!)}>✕</button>
          </div>
        {/each}
        {#if successes.length === 0}
          <div class="empty-state card">Registra tus experiencias de éxito 🏆</div>
        {/if}
      </div>
    </div>

  <!-- REWARDS -->
  {:else if activeTab === 'rewards'}
    <div class="fade-in">
      <div class="tab-actions">
        <button class="btn btn-primary" onclick={() => { rewardForm = { achievement_name: '', reward_given: '', date_awarded: new Date().toISOString().split('T')[0] }; showRewardForm = true; }}>+ Agregar recompensa</button>
      </div>
      <div class="rewards-grid">
        {#each rewards as r}
          <div class="reward-card card">
            <div class="reward-icon">🎁</div>
            <div class="reward-info">
              <div class="reward-name">{r.achievement_name}</div>
              <div class="reward-given">{r.reward_given}</div>
              <div class="reward-date">{new Date(r.date_awarded).toLocaleDateString('es-ES')}</div>
            </div>
            <button class="btn btn-ghost" onclick={() => deleteReward(r.id!)}>✕</button>
          </div>
        {/each}
        {#if rewards.length === 0}
          <div class="empty-state card" style="grid-column:1/-1">Celebra tus logros con recompensas 🎁</div>
        {/if}
      </div>
    </div>
  {/if}
</div>

<!-- MODALS -->
{#if showBookForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showBookForm = false; resetBookForm();
        }
      }}>
    <div class="modal">
      <h3>{editingBook ? 'Editar libro' : 'Nuevo libro'}</h3>
      <div class="form-group"><label>Título</label><input bind:value={bookForm.title} placeholder="Nombre del libro" /></div>
      <div class="grid-2">
        <div class="form-group"><label>Página actual</label><input type="number" bind:value={bookForm.current_page} min="0" /></div>
        <div class="form-group"><label>Total páginas</label><input type="number" bind:value={bookForm.total_pages} min="0" /></div>
      </div>
      <div class="form-group"><label>URL portada (opcional)</label><input bind:value={bookForm.cover_url} placeholder="https://..." /></div>
      <div class="form-group"><label>Notas</label><textarea bind:value={bookForm.notes} rows="3" placeholder="Reflexiones..."></textarea></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => { showBookForm = false; resetBookForm(); }}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveBook} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

{#if showLearnForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showLearnForm = false
        }
      }}>
    <div class="modal">
      <h3>Nuevo tema de aprendizaje</h3>
      <div class="form-group"><label>Tema</label><input bind:value={learnForm.topic} placeholder="Ej: Diseño de APIs REST" /></div>
      <div class="form-group"><label>Enlace de recurso</label><input bind:value={learnForm.resource_link} placeholder="https://..." /></div>
      <div class="form-group"><label>URL imagen/captura</label><input bind:value={learnForm.image_url} placeholder="https://..." /></div>
      <div class="form-group"><label>Notas</label><textarea bind:value={learnForm.notes} rows="3"></textarea></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showLearnForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveLearn} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

{#if showMemForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showMemForm = false
        }
      }}>
    <div class="modal">
      <h3>Nuevo recuerdo</h3>
      <div class="form-group"><label>Fecha</label><input type="date" bind:value={memForm.date} /></div>
      <div class="form-group"><label>Descripción</label><textarea bind:value={memForm.description} rows="2"></textarea></div>
      <div class="form-group">
        <label>Imagen</label>
        <div class="mem-upload-toggle">
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

{#if showCalForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showCalForm = false
        }
      }}>
    <div class="modal">
      <h3>Nuevo evento</h3>
      <div class="form-group"><label>Nombre</label><input bind:value={calForm.event_name} placeholder="Cumpleaños, viaje..." /></div>
      <div class="form-group"><label>Fecha</label><input type="date" bind:value={calForm.event_date} /></div>
      <div class="form-group">
        <label>Tipo</label>
        <select bind:value={calForm.type}>
          <option value="event">Evento</option>
          <option value="special_day">Día especial</option>
        </select>
      </div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showCalForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveCal} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

{#if showSuccessForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          closeSuccessForm()
        }
      }}>
    <div class="modal">
      <h3>{editingSuccessId ? 'Editar meta / logro' : 'Nueva meta / logro'}</h3>
      <div class="form-group"><label>Descripción de la meta</label><textarea bind:value={successForm.goal_description} rows="2" placeholder="¿Qué quieres lograr?"></textarea></div>
      <div class="form-group"><label>Reflexión</label><textarea bind:value={successForm.reflection} rows="8" placeholder="¿Qué aprendiste?"></textarea></div>
      <div class="form-group" style="display:flex;align-items:center;gap:8px;">
        <input type="checkbox" bind:checked={successForm.done} id="done-check" style="width:auto;" disabled={!!editingSuccess?.done} />
        <label for="done-check" style="text-transform:none;font-size:14px;color:var(--text);">Marcar como completada</label>
      </div>
      {#if editingSuccess?.done}
        <div style="color:var(--text3);font-size:12px;font-family:var(--font-mono);margin-top:-15px;">
          Ya esta completada y no se puede desmarcar.
        </div>
      {/if}
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={closeSuccessForm}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveSuccess} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

{#if showRewardForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showRewardForm = false
        }
      }}>
    <div class="modal">
      <h3>Nueva recompensa</h3>
      <div class="form-group"><label>Logro</label><input bind:value={rewardForm.achievement_name} placeholder="¿Qué lograste?" /></div>
      <div class="form-group"><label>Recompensa</label><input bind:value={rewardForm.reward_given} placeholder="¿Cómo te premiaste?" /></div>
      <div class="form-group"><label>Fecha</label><input type="date" bind:value={rewardForm.date_awarded} /></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => showRewardForm = false}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveReward} disabled={saving}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .goals-page { max-width: 1100px; }

  .tabs-bar {
    display: flex;
    gap: 4px;
    flex-wrap: wrap;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 6px;
    margin-bottom: 24px;
  }

  .tab-btn {
    padding: 8px 14px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    color: var(--text3);
    transition: all var(--transition);
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .tab-btn.active {
    background: var(--surface2);
    color: var(--text);
  }

  .tab-btn:hover:not(.active) { background: var(--surface); color: var(--text2); }

  .tab-actions { margin-bottom: 20px; }

  /* Vision */
  .vision-board-placeholder {
    min-height: 220px;
    margin-bottom: 28px;
    border: 2px dashed var(--border);
    background: var(--bg3);
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

  .phrases-grid {
    display: flex;
    flex-direction: column;
    flex-wrap: wrap-reverse;
    gap: 10px;
  }

  .phrase-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 20px;
    display: flex;
    gap: 5px;
    align-items: center;
    justify-content: flex-start;
    transition: transform var(--transition);
  }

  .phrase-card:hover { transform: translateY(-2px); }

  .phrase-glyph {
    color: var(--accent-green);
    font-size: 25px;
    flex-shrink: 0;
    margin-bottom: 2px;
  }

  .phrase-text {
    font-family: var(--font-display);
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
    line-height: 1.5;
    font-style: italic;
  }

  /* Books */
  .books-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 16px;
  }

  .book-card {
    position: relative;
    display: flex;
    gap: 14px;
    transition: transform var(--transition);
  }

  .book-card:hover { transform: translateY(-2px); }
  .book-card.finished { border-color: rgba(255,217,61,0.3); }

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
  .book-title { font-weight: 700; font-size: 14px; margin-bottom: 4px; }
  .book-progress-label { font-size: 12px; color: var(--text3); font-family: var(--font-mono); }
  .book-pct { font-size: 11px; color: var(--text3); font-family: var(--font-mono); }
  .book-notes { font-size: 12px; color: var(--text2); margin-top: 6px; border-top: 1px solid var(--border); padding-top: 6px; }

  .card-actions {
    position: absolute;
    top: 10px;
    right: 10px;
    display: flex;
    gap: 4px;
    opacity: 0;
    transition: opacity var(--transition);
  }

  .book-card:hover .card-actions { opacity: 1; }

  /* Learning */
  .learn-list { display: flex; flex-direction: column; gap: 12px; }

  .learn-card {
    display: flex;
    align-items: flex-start;
    gap: 14px;
  }

  .learn-main { flex: 1; }
  .learn-topic { font-weight: 700; font-size: 15px; margin-bottom: 4px; }
  .learn-link { font-size: 13px; color: var(--accent-green); display: inline-block; margin-bottom: 4px; }
  .learn-notes { font-size: 13px; color: var(--text2); }
  .learn-thumb { width: 80px; height: 60px; object-fit: cover; border-radius: 6px; flex-shrink: 0; }

  /* Memories */
  .memory-grid {
    width: 100%;
  }

  .mem-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    overflow: hidden;
    cursor: default;
    position: relative;
    transition: transform var(--transition);
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .mem-card:hover { transform: scale(1.02); }

  .mem-open {
    position: absolute;
    left: 6px;
    bottom: 6px;
    z-index: 20;
    font-family: var(--font-mono);
    font-size: 11px;
    color: white;
    background: rgba(0,0,0,0.55);
    border: 1px solid rgba(51,61,87,0.85);
    border-radius: 8px;
    padding: 4px 8px;
    line-height: 1;
    opacity: 0;
    transition: opacity var(--transition), transform var(--transition);
  }

  .mem-card:hover .mem-open { opacity: 1; transform: translateY(-1px); }

  :global(.memory-grid .grid-stack-item-content) {
    overflow: visible;
    position: relative;
  }

  :global(.memory-grid .grid-stack-item > .ui-resizable-handle) {
    z-index: 30;
    opacity: 0;
    transition: opacity var(--transition);
  }

  :global(.memory-grid .grid-stack-item:hover > .ui-resizable-handle) {
    opacity: 1;
  }

  :global(.memory-grid .grid-stack-item > .ui-resizable-se) {
    right: 6px;
    bottom: 6px;
    width: 22px;
    height: 22px;
    border-radius: 8px;
    background-color: rgba(0,0,0,0.55);
    border: 1px solid rgba(115,231,189,0.35);
    background-size: 14px 14px;
  }

  .mem-photo { width: 100%; flex: 1; min-height: 140px; object-fit: cover; display: block; }
  .mem-placeholder {
    width: 100%;
    flex: 1;
    min-height: 140px;
    background: var(--bg3);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 40px;
  }

  .mem-info { padding: 10px; }
  .mem-date { font-size: 11px; color: var(--text3); font-family: var(--font-mono); margin-bottom: 3px; }
  .mem-desc { font-size: 13px; color: var(--text); }

  .mem-upload-toggle {
    display: inline-flex;
    gap: 6px;
    background: var(--bg3);
    border: 1px solid var(--border);
    border-radius: 999px;
    padding: 4px;
    margin-bottom: 10px;
  }

  .toggle-pill {
    padding: 6px 10px;
    border-radius: 999px;
    font-size: 12px;
    font-weight: 700;
    color: var(--text3);
    transition: all var(--transition);
    font-family: var(--font-mono);
  }

  .toggle-pill.active {
    background: rgba(115,231,189,0.18);
    color: var(--text);
    border: 1px solid rgba(115,231,189,0.35);
  }

  .file-input {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    border: 0;
  }

  .file-row {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
  }

  .file-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 8px 12px;
    border-radius: 12px;
    border: 1px solid rgba(115,231,189,0.35);
    background: rgba(115,231,189,0.12);
    color: var(--text);
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 700;
    transition: all var(--transition);
    cursor: pointer;
  }

  .file-btn:hover { transform: translateY(-1px); background: rgba(115,231,189,0.18); }

  .file-name {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--text3);
    flex: 1;
    min-width: 180px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .mem-delete {
    position: absolute;
    top: 6px;
    right: 6px;
    background: rgba(0,0,0,0.6) !important;
    color: white !important;
    border-radius: 50%;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    opacity: 0;
    transition: opacity var(--transition);
    padding: 0;
  }

  .mem-drag {
    position: absolute;
    top: 6px;
    left: 6px;
    background: rgba(0,0,0,0.55);
    color: white;
    border-radius: 8px;
    padding: 2px 6px;
    font-family: var(--font-mono);
    font-size: 12px;
    line-height: 1;
    opacity: 0;
    transition: opacity var(--transition);
    cursor: grab;
    user-select: none;
  }

  .mem-drag:active { cursor: grabbing; }
  .mem-card:hover .mem-drag { opacity: 1; }

  .mem-card:hover .mem-delete { opacity: 1; }
  
  /* Calendar */
  .week-section { margin-top: 16px; }

  .cal-list { display: flex; flex-direction: column; gap: 10px; }

  .cal-card {
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .cal-card:target {
    outline: 2px solid var(--accent-green);
    outline-offset: 2px;
  }

  .cal-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
  .cal-info { flex: 1; }
  .cal-name { font-weight: 700; font-size: 15px; }
  .cal-date { font-size: 13px; color: var(--text2); text-transform: capitalize; margin: 3px 0; }

  .week-title {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--text3);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin-bottom: 12px;
  }

  .week-grid {
    display: grid;
    grid-template-columns: repeat(7, minmax(0, 1fr));
    gap: 10px;
  }

  @media (max-width: 1000px) {
    .week-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  }

  @media (max-width: 560px) {
    .week-grid { grid-template-columns: 1fr; }
  }

  .week-col {
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    background: rgba(0,0,0,0.15);
  }

  .week-header {
    padding: 10px 10px 8px;
    background: var(--bg3);
    border-bottom: 1px solid var(--border);
  }

  .week-header.current {
    background: var(--accent-green);
    border-bottom-color: var(--accent-green);
  }

  .week-header.current .week-day {
    color: var(--bg3);
  }

  .week-header.current .week-date {
    color: var(--surface2);
  }

  .week-header.special {
    background: rgba(235,213,127,0.14);
    border-bottom-color: rgba(235,213,127,0.35);
  }

  .week-header-top {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 8px;
  }

  .week-day {
    font-weight: 800;
    font-size: 12px;
    color: var(--text);
    text-transform: capitalize;
  }

  .week-date {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--text3);
    white-space: nowrap;
  }

  .week-special {
    margin-top: 6px;
    font-size: 12px;
    color: var(--text2);
    font-style: italic;
    line-height: 1.4;
  }

  .week-body { padding: 10px; }
  .week-empty { color: var(--text3); font-size: 12px; font-family: var(--font-mono); }
  .week-list { display: flex; flex-direction: column; gap: 6px; }
  .week-event {
    font-size: 12px;
    color: var(--bg2);
    font-weight: 600;
    padding: 6px 8px;
    border-radius: 8px;
    border: 1px solid rgba(51,61,87,0.7);
    background: var(--accent-blue);
  }
  .week-event:hover {
    font-size: 12px;
    background: var(--accent-green);
  }

  /* Successes */
  .success-list { display: flex; flex-direction: column; gap: 12px; }

  .success-card {
    display: flex;
    align-items: flex-start;
    gap: 14px;
    transition: border-color var(--transition);
  }

  .success-card.done { border-color: rgba(168,230,207,0.3); }

  .success-check {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    border: 2px solid var(--border);
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    color: var(--accent-green);
    transition: all var(--transition);
    cursor: pointer;
    margin-top: 2px;
  }

  .success-check.checked {
    background: var(--accent-green);
    border-color: var(--accent-green);
    color: #0a1a0f;
  }
  .success-check:disabled {
    cursor: default;
    background: var(--surface);
    border-color: var(--accent-green);
    color: var(--accent-green);
  }

  .success-info { flex: 1; }
  .success-goal { font-weight: 600; font-size: 20px; line-height: normal; }
  .success-reflection { font-size: 13px; color: var(--text2); max-width: 80%; margin-top: 4px; }
  .success-date { font-size: 11px; color: var(--text3); font-family: var(--font-mono); margin-top: 4px; }

  /* Rewards */
  .rewards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 14px;
  }

  .reward-card {
    display: flex;
    gap: 14px;
    align-items: flex-start;
  }

  .reward-icon { font-size: 28px; flex-shrink: 0; }
  .reward-info { flex: 1; }
  .reward-name { font-weight: 700; font-size: 15px; }
  .reward-given { font-size: 13px; color: var(--text2); margin: 4px 0; }
  .reward-date { font-size: 11px; color: var(--text3); font-family: var(--font-mono); }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 32px;
    font-family: var(--font-mono);
  }
</style>
