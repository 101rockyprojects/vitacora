<script lang="ts">
	import { text } from '@sveltejs/kit';
  import type { CalendarEvent } from '$lib/types';

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
    {#each events as ev (ev.id)}
      <div class="cal-card card" id="event-{slugify(ev.event_name)}">
        <div class="cal-dot" style="background:{ev.type === 'special_day' ? 'var(--accent-yellow)' : 'var(--accent-green)'}"></div>
        <div class="cal-info">
          <div class="cal-name">{ev.event_name}</div>
          <div class="cal-date">{new Date(ev.event_date).toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</div>
          <span class="tag" style="background:var(--bg3);color:var(--text3)">{ev.type === 'special_day' ? 'Dia especial' : 'Evento'}</span>
        </div>
      </div>
    {/each}
    {#if events.length === 0}
      <div class="empty-state card">Agrega tus fechas importantes</div>
    {/if}
  </div>
{/if}

<style>
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
  }

  @media (max-width: 560px) {
    .week-grid { grid-template-columns: 1fr; }
  }
</style>
