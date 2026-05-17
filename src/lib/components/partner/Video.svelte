<script lang="ts">
  import Video from '$lib/components/Video.svelte';

  export let videoId: string;
  export let videoTitle: string;
  export let quote: string | null = null;
  export let watchUrl: string | null = null;
</script>

<div class="meloday-video-quote">
  <section class="video-info">
    <h2 class="video-title">{videoTitle}</h2>

    <div class="video-quote">
      <Video videoId={videoId} {videoTitle} />
    </div>

    {#if quote}
      <div class="quote">“{quote}”</div>
    {/if}

    {#if watchUrl}
      <a class="video-link" href={watchUrl} target="_blank" rel="noreferrer">Abrir en Meloday</a>
    {/if}
  </section>
</div>

<style>
  .meloday-video-quote {
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 1.2em;
  }
  .video-info { display: flex; flex-direction: column; gap: 12px; width: 100%; }
  .video-quote {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    margin: 0 auto;
    grid-template-columns: 1fr auto;
    gap: 14px;
    padding: 12px 8px;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background-image: linear-gradient(150deg,#c71313,#1f3fcc);
  }
  .video-title { font-weight: 900; font-size: 1rem; color: var(--text); }
  .quote {
    width: 100%;
    font-size: 0.9rem;
    font-family: var(--font-mono);
    line-height: 1.2;
    letter-spacing: 0.02em;
    font-style: italic;
    text-align: center;
  }
  .video-link {
    width: 100%;
    text-align: center;
    font-family: var(--font-mono);
    font-weight: 600;
    background: var(--bg);
    color: var(--text);
    padding: 8px 14px;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    text-decoration: none;
  }
  .video-link:hover {
    background: #1f3fcc;
    color: var(--text);
    text-decoration: underline;
  }
</style>
