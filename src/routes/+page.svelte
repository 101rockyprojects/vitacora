<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';

  $effect(() => {
    if ($page.data.session) goto('/dashboard');
    else goto('/auth');
  });
</script>

<div style="display:flex;align-items:center;justify-content:center;height:100vh;color:var(--text3);font-family:var(--font-mono);">
  Cargando...
</div>
