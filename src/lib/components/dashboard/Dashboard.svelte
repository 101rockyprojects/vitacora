<script lang="ts">
  import { page } from '$app/state';
  import { browser } from '$app/environment';
  import { createRepository } from '$lib/services/repository';
  import WeekPlanner from '$lib/components/WeekPlanner.svelte';
  import type { Book, CalendarEvent, Task, Expense, CalendarTodo } from '$lib/types';
  import { levelFromXp, getAreaXP } from '$lib/utils/xp';
  import { checkAndCreateNotifications } from '$lib/utils/notifications';
  import Stats from './Stats.svelte';
  import AreaXP from './AreaXP.svelte';
  import TasksPanel from './TasksPanel.svelte';
  import BooksPanel from './BooksPanel.svelte';
  import ExpensesPanel from './ExpensesPanel.svelte';
  import Motivational from './Motivational.svelte';
  import { notificationStore } from '$lib/stores/notifications.svelte';

  let tasks = $state<Task[]>([]);
  let books = $state<Book[]>([]);
  let calEvents = $state<CalendarEvent[]>([]);
  let calendarTodos = $state<CalendarTodo[]>([]);
  let expenses = $state<Expense[]>([]);
  let areaXP: Record<string, number> = $state({});
  let totalXP = $derived(Object.values(areaXP).reduce((a, b) => a + b, 0));
  let globalLevel = $derived(levelFromXp(totalXP));
  let loading = $state(true);
  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let userBadgesCount = $state(0);

  const now = new Date();
  const greeting = now.getHours() < 12 ? 'Buenos días' : now.getHours() < 18 ? 'Buenas tardes' : 'Buenas noches';

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadDashboard();
    }
  });

  async function loadDashboard() {
    const [tasksRes, booksRes, badgesRes, calRes, expRes, calTodosRes] = await Promise.all([
      repo.tasks.list(),
      repo.books.list(),
      repo.userBadges.listIds(),
      repo.calendar.list(),
      repo.expenses.list(),
      repo.calendarTodos.list()
    ]);

    tasks = tasksRes.data || [];
    books = booksRes.data || [];
    calEvents = calRes.data || [];
    calendarTodos = calTodosRes.data || [];
    expenses = expRes.data || [];
    userBadgesCount = badgesRes.data?.length || 0;
    areaXP = await getAreaXP(userId);
    loading = false;

    checkAndCreateNotifications(tasks, calEvents, calendarTodos);

    if (browser && localStorage.getItem('vitacora_just_logged_in')) {
      localStorage.removeItem('vitacora_just_logged_in');
      notificationStore.addNotification({ type: 'info', title: '¡Bienvenido/a!', message: 'Has iniciado sesión correctamente.' });
    }
  }
</script>

<div class="dashboard fade-in">
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

  <Stats {totalXP} {tasks} {books} {userBadgesCount} />

  <div class="dash-grid">
    <TasksPanel {tasks} {loading} />
    <BooksPanel {books} />
    <Motivational />
    <ExpensesPanel {expenses} />
    <AreaXP bind:areaXP />
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

  .dash-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .week-card { grid-column: 1; }

  @media (min-width: 768px) and (max-width: 1150px) {
    .dash-grid { grid-template-columns: 1fr 1fr; }
    .dash-header { flex-direction: column; align-items: flex-start; gap: 12px; }
    .dash-global-xp { width: 100%; justify-content: space-between; }
    .week-card { grid-column: span 2; }
  }

  @media (min-width: 1151px) {
    .dash-grid { grid-template-columns: 1fr 1fr 1fr; }
    .week-card { grid-column: span 3; }
  }
</style>