<script lang="ts">
  import '../app.css';
  import { page } from '$app/stores';
  import Sidebar from '$lib/components/Sidebar.svelte';
  
  let { data, children } = $props();
  
  $effect(() => {
    if (data.session) {
      // user logged in
    }
  });
  
  const isAuthPage = $derived($page.url.pathname.startsWith('/auth'));
</script>

<div class="app-layout">
  {#if data.session && !isAuthPage}
    <Sidebar user={data.user} />
  {/if}
  <main class="main-content" class:full-width={isAuthPage || !data.session}>
    {@render children()}
  </main>
</div>

<style>
  .full-width {
    margin-left: 0 !important;
    max-width: 100vw !important;
  }
</style>
