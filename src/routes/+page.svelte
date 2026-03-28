<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  onMount(async () => {
    const { data: { session } } = await supabase.auth.getSession();
    console.log(session);
    if (session) goto('/dashboard');
    else goto('/auth');
  });
</script>

<div style="display:flex;align-items:center;justify-content:center;height:100vh;color:var(--text3);font-family:var(--font-mono);">
  Cargando...
</div>
