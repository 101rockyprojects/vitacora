<script lang="ts">
  interface Props {
    videoTitle?: string;
    videoId: string;
  }

  let { videoTitle = '', videoId }: Props = $props();
</script>

<div class="video-container">
  <lite-youtube
    videoid={videoId}
    title={videoTitle}
    class="video-player"
  ></lite-youtube>
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