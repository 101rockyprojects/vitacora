<script lang="ts">
  import { page } from '$app/state';
  import { createRepository } from '$lib/services/repository';
  import WeekPlanner from '$lib/components/WeekPlanner.svelte';
  import PieChart from '$lib/components/PieChart.svelte';
  import type { Book, CalendarEvent, Task, Expense, ExpenseCategory } from '$lib/types';
  import { levelFromXp, getAreaXP, AREAS } from '$lib/utils/xp';

  let tasks = $state<Task[]>([]);
  let books = $state<Book[]>([]);
  let calEvents = $state<CalendarEvent[]>([]);
  let expenses = $state<Expense[]>([]);
  let areaXP: Record<string, number> = $state({});
  let totalXP = $derived(Object.values(areaXP).reduce((a, b) => a + b, 0));
  let globalLevel = $derived(levelFromXp(totalXP));
  let recentBooks = $derived(books.slice(0, 3));
  let todayTasks = $derived(tasks.filter(t => t.status !== 'done').slice(0, 5));
  let loading = $state(true);
  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let userBadgesCount = $state(0);

  const now = new Date();
  const greeting = now.getHours() < 12 ? 'Buenos días' : now.getHours() < 18 ? 'Buenas tardes' : 'Buenas noches';
  const currentMonth = now.toISOString().substring(0, 7);

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadDashboard();
    }
  });

  async function loadDashboard() {
    const [tasksRes, booksRes, badgesRes, calRes, expRes] = await Promise.all([
      repo.tasks.list(),
      repo.books.list(),
      repo.userBadges.listIds(),
      repo.calendar.list(),
      repo.expenses.list()
    ]);

    tasks = tasksRes.data || [];
    books = booksRes.data || [];
    calEvents = calRes.data || [];
    expenses = expRes.data || [];
    userBadgesCount = badgesRes.data?.length || 0;
    areaXP = await getAreaXP(userId);
    loading = false;
  }

  function bookProgress(book: any) {
    if (!book.total_pages) return 0;
    return Math.round((book.current_page / book.total_pages) * 100);
  }

  const currentMonthExpenses = $derived(expenses.filter(e => e.expense_date.startsWith(currentMonth)));
  const currentMonthTotal = $derived(currentMonthExpenses.reduce((sum, e) => sum + (e.cost || 0), 0));
  const currentMonthByCategory = $derived(() => {
    const categories: Record<string, number> = {};
    for (const e of currentMonthExpenses) {
      const cat = e.category || 'Sin categoría';
      categories[cat] = (categories[cat] || 0) + (e.cost || 0);
    }
    const total = Object.values(categories).reduce((a, b) => a + b, 0);
    return Object.entries(categories)
      .map(([name, total]) => ({ name, total, percentage: total > 0 ? (total / total) * 100 : 0 }))
      .sort((a, b) => b.total - a.total);
  });

</script>

<div class="dashboard fade-in">
  <!-- Header -->
  <div class="dash-header">
    <div>
      <h1 class="dash-greeting">{greeting} ⊶</h1>
      <p class="dash-date">{now.toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
    </div>
    <div class="dash-global-xp">
      <div class="global-level">
        <span class="level-num">{globalLevel.level}</span>
        <span class="level-label">nivel</span>
      </div>
      <div class="xp-info">
        <div class="xp-nums">
          <span>{globalLevel.progress}</span>
          <span class="xp-sep">/</span>
          <span>{globalLevel.nextLevelXp} XP</span>
        </div>
        <div class="progress-track" style="width:160px;">
          <div class="progress-fill xp-bar-fill"
            style="width:{(globalLevel.progress / globalLevel.nextLevelXp) * 100}%;background:var(--accent-green);">
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Stats row -->
  <div class="stats-row">
    <div class="stat-card">
      <span class="stat-icon">⚡</span>
      <div>
        <div class="stat-num">{totalXP}</div>
        <div class="stat-label">XP Total</div>
      </div>
    </div>
    <div class="stat-card">
      <span class="stat-icon">📋</span>
      <div>
        <div class="stat-num">{todayTasks.length}</div>
        <div class="stat-label">Tareas activas</div>
      </div>
    </div>
    <div class="stat-card">
      <span class="stat-icon">📚</span>
      <div>
        <div class="stat-num">{books.length}</div>
        <div class="stat-label">Libros</div>
      </div>
    </div>
    <div class="stat-card">
      <span class="stat-icon">🏅</span>
      <div>
        <div class="stat-num">{userBadgesCount}</div>
        <div class="stat-label">Logros</div>
      </div>
    </div>
  </div>

  <div class="dash-grid">
    <!-- Area XP bars -->
    <div class="card">
      <h3 class="card-title">Áreas de vida</h3>
      <div class="area-bars">
        {#each AREAS as area}
          {@const aXP = areaXP[area.key] || 0}
          {@const lvl = levelFromXp(aXP)}
          <div class="area-bar-item">
            <div class="area-bar-header">
              <span>{area.icon} {area.label}</span>
              <span class="area-bar-lv" style="color:{area.color}">Lv.{lvl.level}</span>
            </div>
            <div class="progress-track">
              <div class="progress-fill"
                style="width:{(lvl.progress/lvl.nextLevelXp)*100}%;background:{area.color};">
              </div>
            </div>
            <div class="area-bar-xp">{aXP} XP</div>
          </div>
        {/each}
      </div>
    </div>

    <!-- Today's tasks -->
    <div class="card">
      <h3 class="card-title">Pendientes <a href="/work" class="card-link">Ver todos →</a></h3>
      {#if loading}
        <div class="placeholder-list">
          {#each [1,2,3] as _}
            <div class="placeholder-item pulse"></div>
          {/each}
        </div>
      {:else if todayTasks.length === 0}
        <div class="empty-state">Sin tareas pendientes 🎉</div>
      {:else}
        <div class="task-list">
          {#each todayTasks as task}
            <div class="task-item">
              <span class="task-sta-dot" style="background:{task.status === 'doing' ? 'var(--accent-yellow)' : 'var(--accent-blue)'}"></span>
              <div class="task-item-info">
                <div class="task-item-title">{task.title}</div>
                {#if task.due_date}
                  <div class="task-item-due">{new Date(task.due_date).toLocaleDateString('es-ES')}</div>
                {/if}
              </div>
              <span class="task-sta-tag">{task.status}</span>
            </div>
          {/each}
        </div>
      {/if}
    </div>

    <!-- Books in progress -->
    <div class="card">
      <h3 class="card-title">Lecturas <a href="/goals?tab=books" class="card-link">Ver todas →</a></h3>
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


    <div class="card expenses-card">
      <h3 class="card-title">Gastos del mes <a href="/goals?tab=expenses" class="card-link">Ver todos →</a></h3>
      {#if currentMonthByCategory().length > 0}
      <div class="expenses-chart">
        <PieChart data={currentMonthByCategory()} type="bar" />
      </div>
      <div class="month-expense-total">
        Total: <span>${currentMonthTotal.toFixed(2)}</span>
      </div>
      {:else}
      <div class="empty-state">Sin gastos este mes</div>
      {/if}
    </div>

    <!-- Quick motivational -->
    <div class="card motive-card">
      <div class="motive-glyph">⊶</div>
      <blockquote class="motive-quote">
        "1% better every day"
      </blockquote>
      <div class="motive-links">
        <a href="/goals" class="motive-link">Visión →</a>
        <a href="/work" class="motive-link">Kanban →</a>
        <a href="/goals?tab=calendar" class="motive-link">Calendario →</a>
      </div>
    </div>

    <div class="card week-card">
      <WeekPlanner events={calEvents} showEventList={false} />
    </div>
  </div>
</div>

<style>
  .dashboard { max-width: 1100px; }

  .dash-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 28px;
    flex-wrap: wrap;
    gap: 16px;
  }

  .dash-greeting {
    font-size: 28px;
    font-weight: 800;
    color: var(--text);
  }

  .dash-date {
    font-size: 13px;
    color: var(--text3);
    font-family: var(--font-mono);
    margin-top: 4px;
    text-transform: capitalize;
  }

  .dash-global-xp {
    display: flex;
    align-items: center;
    gap: 16px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 12px 20px;
  }

  .global-level {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .level-num {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 800;
    color: var(--accent-green);
    line-height: 1;
  }

  .level-label {
    font-size: 10px;
    color: var(--text3);
    font-family: var(--font-mono);
    text-transform: uppercase;
  }

  .xp-nums {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--text2);
    margin-bottom: 6px;
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .xp-sep { color: var(--text3); }

  .stats-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
    margin-bottom: 24px;
  }

  .stat-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .stat-icon { font-size: 22px; }

  .stat-num {
    font-family: var(--font-display);
    font-size: 22px;
    font-weight: 800;
    color: var(--text);
    line-height: 1;
  }

  .stat-label {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-top: 2px;
  }

  .dash-grid {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 16px;
  }

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

  .area-bars { display: flex; flex-direction: column; gap: 12px; }

  .area-bar-item { }

  .area-bar-header {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    color: var(--text2);
    margin-bottom: 5px;
  }

  .area-bar-lv { font-family: var(--font-mono); font-size: 11px; font-weight: 700; }

  .area-bar-xp {
    font-size: 10px;
    color: var(--text3);
    font-family: var(--font-mono);
    margin-top: 3px;
  }

  .task-list { display: flex; flex-direction: column; gap: 8px; }

  .task-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px;
    border-radius: 8px;
    background: var(--bg3);
  }

  .task-sta-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .task-item-info { flex: 1; min-width: 0; }

  .task-item-title {
    font-size: 13px;
    color: var(--text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .task-item-due {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .task-sta-tag {
    font-size: 10px;
    color: var(--text3);
    font-family: var(--font-mono);
    background: var(--bg2);
    padding: 2px 6px;
    border-radius: 4px;
    white-space: nowrap;
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

  .motive-card {
    background: linear-gradient(135deg, rgba(168,230,207,0.08), rgba(255,217,61,0.04));
    border-color: rgba(168,230,207,0.25);
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
    min-height: 180px;
  }

  .week-card {
    grid-column: span 3;
  }

  .motive-card {
    grid-column: span 1;
  }

  .expenses-card {
    grid-column: span 2;
    display: flex;
    flex-direction: column;
  }

  .expenses-chart {
    display: flex;
    justify-content: center;
    margin: 10px 0;
    min-height: 280px;
  }

  .month-expense-total {
    text-align: center;
    font-size: 13px;
    color: var(--text2);
    font-family: var(--font-mono);
  }

  .month-expense-total span {
    font-weight: 700;
    color: var(--accent-yellow);
    font-size: 16px;
  }

  .motive-glyph {
    font-size: 32px;
    color: var(--accent-green);
    margin-bottom: 12px;
  }

  .motive-quote {
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 700;
    color: var(--text);
    font-style: italic;
    margin-bottom: 16px;
    line-height: 1.4;
  }

  .motive-links {
    display: flex;
    gap: 12px;
  }

  .motive-link {
    font-size: 13px;
    color: var(--accent-green);
    font-family: var(--font-mono);
    transition: opacity var(--transition);
  }

  .motive-link:hover { opacity: 0.7; }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: center;
    padding: 24px 0;
  }

  .placeholder-list { display: flex; flex-direction: column; gap: 8px; }
  .placeholder-item {
    height: 40px;
    background: var(--bg3);
    border-radius: 8px;
  }

  @media (max-width: 700px) {
    .dash-header { flex-direction: column; align-items: flex-start; gap: 12px; }
    .dash-global-xp { width: 100%; justify-content: space-between; }
    .week-card { grid-column: span 1; }
  }

  @media (max-width: 900px) {
    .stats-row { grid-template-columns: 1fr 1fr; }
    .dash-grid { grid-template-columns: 1fr 1fr; }
    .week-card { grid-column: span 2; }
    .motive-card { grid-column: span 1; }
    .expenses-card { grid-column: span 1; }
  }
</style>
