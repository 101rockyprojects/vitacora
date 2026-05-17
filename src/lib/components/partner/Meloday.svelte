<script lang="ts">
  import { onMount } from 'svelte';
  import Video from '$lib/components/partner/Video.svelte';
  import Oops from '$lib/components/Oops.svelte';

  type MelodayResponse = {
    name: string;
    videoId: string;
    embed: string;
    defaultLink: string;
    links: Record<string, string | null>;
    date: {
      raw: string | null;
      parsed: string;
      dayOfYear: number;
      leapYear: boolean;
    };
    quote: string;
    isSpecialDate: boolean;
  };

  const apiUrl = '/api/meloday';
  const baseUrl = 'https://meloday.rockybarrios10.workers.dev';

  let meloday = $state<MelodayResponse | null>(null);
  let loading = $state(true);
  let error = $state<string | null>(null);

  const watchUrl = $derived(meloday ? new URL(meloday.defaultLink, baseUrl).toString() : null);
  const showVideo = $derived(meloday?.videoId && meloday.videoId.length > 0);

  onMount(async () => {
    await import('@justinribeiro/lite-youtube');
  });

  onMount(async () => {
    try {
      const res = await fetch(apiUrl, { headers: { accept: 'application/json' } });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      meloday = (await res.json()) as MelodayResponse;
    } catch (e) {
      error = e instanceof Error ? e.message : 'Error';
    } finally {
      loading = false;
    }
  });
</script>

<section class="meloday-wrap">
  <div class="card meloday-info">
    <div class="meloday-header">
      <div>
        <h1 class="meloday-title">Meloday</h1>
        <span class="section-subtitle">Canción y quote del día</span>
      </div>
      {#if meloday?.date?.parsed}
        <div class="meloday-date">{meloday.date.parsed}</div>
      {/if}
    </div>

    {#if loading}
      <div class="loading" aria-label="Cargando">
        {#each Array(4) as _}
          <span></span>
        {/each}
      </div>
    {:else if showVideo && !loading}
      <Video videoId={meloday?.videoId ?? ''} videoTitle={meloday?.name ?? ''} quote={meloday?.quote ?? ''} {watchUrl} />
    {:else}
      <Oops
        title="Oops,"
        msg={error ? `No se pudo cargar: ${error}` : 'No se encontro el video, pudo haber sido borrado o se encuentra privado.'}
      />
    {/if}
  </div>
</section>

<style>
  .meloday-wrap {
    display: grid;
    gap: 14px;
    align-items: start;
  }

  .meloday-info {
    width: 100%;
    padding: 18px;
  }

  .meloday-header {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 12px;
  }
  .meloday-title {
    font-weight: 900;
    font-size: 1.25rem;
    letter-spacing: 0.02em;
    color: var(--text);
  }
  .meloday-date { font-size: 12px; color: var(--text2); font-family: var(--font-mono); text-transform: capitalize; }

  .loading {
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 10px 2px;
  }

  .loading span {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    width: 100%;
    height: 25px;
    border-radius: var(--radius-sm);
    border: 1px solid var(--border);
    background: linear-gradient(90deg, var(--bg3), var(--surface2), var(--bg3));
    background-size: 200% 100%;
    animation: shimmer 1.15s linear infinite;
  }

  .loading span:nth-child(2) { height: 250px; }

  :global(.meloday-video) {
    width: 100%;
    height: 100%;
    max-width: 700px;
    border-radius: var(--radius-lg);
    border: 1px solid var(--border);
    overflow: hidden;
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5);
  }

  @keyframes shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }
</style>
