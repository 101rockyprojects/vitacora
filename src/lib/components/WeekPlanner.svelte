<script lang="ts">
  import { page } from '$app/state';
  import type { CalendarEvent } from '$lib/types';
  import { createRepository } from '$lib/services/repository';

  const userId = $derived(page.data.user?.id ?? '');
  const repo = $derived(createRepository(userId));

  let { events, title = 'Semana actual', showEventList = true }: {
    events: CalendarEvent[];
    title?: string;
    showEventList?: boolean;
  } = $props();

  function slugify(text: string): string {
    return text.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]+/g, '');
  }

  function toIsoDateLocal(d: Date): string {
    return d.toLocaleDateString('en-CA');
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
      const dayEvents = events.filter(e => e.event_date === iso);
      const specialTitles = dayEvents.filter(e => e.type === 'special_day').map(e => e.event_name);
      const dayItems = dayEvents.filter(e => e.type !== 'special_day');
      days.push({
        iso,
        date,
        weekday: date.toLocaleDateString('es-ES', { weekday: 'long' }),
        specialTitles,
        events: dayItems
      });
    }
    return days;
  })());

  let showPastEvents = $state(false);

  type EventGroup = {
    iso: string;
    date: Date;
    isToday: boolean;
    isPast: boolean;
    events: CalendarEvent[];
  };

  const eventGroups = $derived((() => {
    const byDate = new Map<string, CalendarEvent[]>();
    for (const ev of events) {
      const iso = ev.event_date;
      if (!byDate.has(iso)) byDate.set(iso, []);
      byDate.get(iso)!.push(ev);
    }

    const groups: EventGroup[] = [...byDate.entries()].map(([iso, dayEvents]) => {
      const d = new Date(iso);
      const isToday = iso === todayIso;
      const isPast = iso < todayIso && !isToday;
      // Keep special_day first inside each day, then events.
      const sorted = [...dayEvents].sort((a, b) => {
        if (a.type === b.type) return a.event_name.localeCompare(b.event_name, 'es', { sensitivity: 'base' });
        return a.type === 'special_day' ? -1 : 1;
      });
      return { iso, date: d, isToday, isPast, events: sorted };
    });

    return groups.sort((a, b) => {
      if (a.isToday && !b.isToday) return -1;
      if (!a.isToday && b.isToday) return 1;
      if (a.isPast !== b.isPast) return a.isPast ? 1 : -1; // past goes last
      if (a.isPast && b.isPast) return b.iso.localeCompare(a.iso); // recent past first
      return a.iso.localeCompare(b.iso); // upcoming chronological
    });
  })());

  const upcomingEventGroups = $derived(eventGroups.filter((g) => !g.isPast));
  const pastEventGroups = $derived(eventGroups.filter((g) => g.isPast));

  async function load() {
    if (!userId) return;
    const c = await repo.calendar.list();
    events = c.data || [];
  }

  async function deleteCal(id: string) {
    if (!confirm('¿Eliminar evento?')) return;
    await repo.calendar.remove(id);
    await load();
  }
</script>

<div class="week-title">{title}</div>
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

{#if showEventList}
  <hr style="border: none; border-top: 1px solid var(--border); margin: 16px 0;"/>

  <div class="week-section cal-list">
    <div class="week-title">Eventos y Fechas especiales</div>
    <div class="cal-groups">
      {#each upcomingEventGroups as g (g.iso)}
        <div class="cal-group" class:today-group={g.isToday}>
          <div class="cal-group-header">
            <div class="cal-group-date">
              {g.date.toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
            </div>
            <div class="cal-group-meta">
              {#if g.isToday}
                <span class="cal-pill">Hoy</span>
              {/if}
              <span class="cal-count">{g.events.length}</span>
            </div>
          </div>
          <div class="week-event-list">
            {#each g.events as ev (ev.id)}
              {@const evDate = new Date(ev.event_date)}
              {@const isToday = toIsoDateLocal(evDate) === todayIso}
              {@const expired = toIsoDateLocal(evDate) < todayIso}
              <div class="cal-card card" id="event-{slugify(ev.event_name)}" class:today={isToday} class:expired={expired}>
                <div class="cal-info">
                  <div class="cal-name">{ev.event_name}</div>
                  <div class="cal-date">{new Date(ev.event_date).toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</div>
                  {#if !expired}
                    <span class="tag" style="background:var(--bg);color:var(--text2)">{ev.type === 'special_day' ? 'Dia especial' : 'Evento'}</span>
                  {/if}
                </div>
                <button class="small-btn btn-ghost" onclick={() => deleteCal(ev.id!)}>✕</button>
              </div>
            {/each}
          </div>
        </div>
      {/each}

      {#if pastEventGroups.length > 0}
        <div class="cal-past">
          <button
            class="cal-past-toggle"
            type="button"
            aria-expanded={showPastEvents}
            onclick={() => (showPastEvents = !showPastEvents)}
          >
            <span>
              Eventos pasados <span class="cal-count">{pastEventGroups.reduce((n, g) => n + g.events.length, 0)}</span>
            </span>
            <span class="cal-chevron" class:open={showPastEvents}>▾</span>
          </button>

          {#if showPastEvents}
            <div class="cal-past-body">
              {#each pastEventGroups as g (g.iso)}
                <div class="cal-group expired-group">
                  <div class="cal-group-header">
                    <div class="cal-group-date">
                      {g.date.toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                    </div>
                    <div class="cal-group-meta">
                      <span class="cal-count">{g.events.length}</span>
                    </div>
                  </div>
                  <div class="week-event-list">
                    {#each g.events as ev (ev.id)}
                      {@const evDate = new Date(ev.event_date)}
                      {@const isToday = toIsoDateLocal(evDate) === todayIso}
                      {@const expired = toIsoDateLocal(evDate) < todayIso}
                      <div class="cal-card card" id="event-{slugify(ev.event_name)}" class:today={isToday} class:expired={expired}>
                        <div class="cal-info">
                          <div class="cal-name">{ev.event_name}</div>
                          <div class="cal-date">{new Date(ev.event_date).toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</div>
                          {#if !expired}
                            <span class="tag" style="background:var(--bg);color:var(--text2)">{ev.type === 'special_day' ? 'Dia especial' : 'Evento'}</span>
                          {/if}
                        </div>
                        <button class="small-btn btn-ghost" onclick={() => deleteCal(ev.id!)}>✕</button>
                      </div>
                    {/each}
                  </div>
                </div>
              {/each}
            </div>
          {/if}
        </div>
      {/if}
    </div>
    {#if events.length === 0}
      <div class="empty-state card">Agrega tus fechas importantes</div>
    {/if}
  </div>
{/if}

<style>
  .week-section { margin-top: 16px; }
  .cal-list { display: flex; flex-direction: column; gap: 10px; }

  .cal-groups {
    display: flex;
    flex-direction: column;
    gap: 14px;
  }

  .cal-group {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .cal-group-header {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 10px;
    padding: 6px 2px;
  }

  .cal-group-date {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--text2);
    text-transform: capitalize;
  }

  .cal-group-meta { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }

  .cal-count {
    font-size: 11px;
    color: var(--text3);
    background: var(--bg3);
    border-radius: 999px;
    padding: 1px 7px;
    font-family: var(--font-mono);
    border: 1px solid var(--border);
  }

  .cal-pill {
    font-size: 11px;
    font-family: var(--font-mono);
    padding: 2px 8px;
    border-radius: 999px;
    background: rgba(168,230,207,0.12);
    border: 1px solid rgba(168,230,207,0.45);
    color: var(--text);
  }

  .today-group .cal-group-date { color: var(--accent-green); }

  .cal-past { border-top: 1px dashed var(--border); padding-top: 12px; }

  .cal-past-toggle {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    padding: 10px 12px;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: var(--bg2);
    color: var(--text2);
    font-family: var(--font-mono);
    font-size: 12px;
    transition: all var(--transition);
  }

  .cal-past-toggle:hover { border-color: var(--text3); color: var(--text); }

  .cal-chevron { transition: transform var(--transition); }
  .cal-chevron.open { transform: rotate(180deg); }

  .cal-past-body { margin-top: 12px; display: flex; flex-direction: column; gap: 14px; }
  
  .cal-card {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 16px;
  }

  .cal-card.today { border: 2px solid var(--accent-green); }
  .cal-card.expired { opacity: 0.8; }

  .cal-card:target {
    outline: 2px solid var(--accent-green);
    outline-offset: 2px;
  }

  .cal-info { flex: 1; }
  .cal-name { font-weight: 700; font-size: 15px; line-height: 1.2; }
  .cal-date { font-size: 13px; color: var(--text2); text-transform: capitalize; margin: 3px 0; }

  .week-title {
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 600;
    color: var(--text);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin-bottom: 12px;
  }

  .week-grid {
    display: grid;
    grid-template-columns: repeat(7, minmax(0, 1fr));
    gap: 10px;
  }

  .week-col {
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    background: rgba(0, 0, 0, 0.15);
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
  
  .week-header.current .week-day { color: var(--bg3); }
  .week-header.current .week-date { color: var(--surface2); }
  
  .week-header.special {
    background: rgba(235, 213, 127, 0.14);
    border-bottom-color: rgba(235, 213, 127, 0.35);
  }
  
  .week-header-top {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    justify-content: space-between;
    gap: 2px;
  }

  .week-day {
    font-weight: 800;
    font-size: 12px;
    color: var(--text);
    min-width: 60px;
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
  
  .week-event-list {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-column-gap: 10px;
    grid-row-gap: 5px;
  }
  
  .week-event {
    font-size: 12px;
    color: var(--bg2);
    font-weight: 600;
    padding: 6px 8px;
    border-radius: 8px;
    border: 1px solid rgba(51, 61, 87, 0.7);
    background: var(--accent-blue);
  }

  .week-event:hover { background: var(--accent-green); }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 32px;
    font-family: var(--font-mono);
  }

  @media (max-width: 1000px) {
    .week-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .week-event-list { grid-template-columns: repeat(2, 1fr); }
  }
  
  @media (max-width: 560px) {
    .week-grid { grid-template-columns: 1fr; }
    .week-event-list { grid-template-columns: repeat(1, 1fr); }
  }
</style>
