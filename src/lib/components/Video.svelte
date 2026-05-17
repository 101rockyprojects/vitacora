<script lang="ts">
  import { browser } from '$app/environment';
  import { onMount } from 'svelte';

  interface Props {
    videoTitle?: string;
    videoId: string;
  }

  let { videoTitle = '', videoId }: Props = $props();

  let mounted = $state(false);

  onMount(() => {
    mounted = true;
  });
</script>

<div class="video-container">
  {#if mounted}
    <lite-youtube
      videoid={videoId}
      title={videoTitle}
      class="video-player"
    ></lite-youtube>
  {/if}
</div>

<style>
  .video-container {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
  }
  
  .video-player {
    aspect-ratio: 16 / 9;
    width: 100%;
    max-width: 700px;
    height: 100%;
    border: none;
    border-radius: var(--radius-sm);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
  }
</style>