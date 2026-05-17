<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';

  let status = $state('Verificando...');

  onMount(async () => {
    if (!browser) return;

    const hashParams = new URLSearchParams(window.location.hash.substring(1));
    const accessToken = hashParams.get('access_token');
    const refreshToken = hashParams.get('refresh_token');
    const type = hashParams.get('type');

    if (accessToken && refreshToken) {
      status = 'Creando sesión...';
      try {
        const { createClient } = await import('@supabase/supabase-js');
        const supabase = createClient(
          import.meta.env.PUBLIC_SUPABASE_URL,
          import.meta.env.PUBLIC_SUPABASE_ANON_KEY
        );

        const { error } = await supabase.auth.setSession({
          access_token: accessToken,
          refresh_token: refreshToken
        });

        if (error) {
          status = 'Error: ' + error.message;
          setTimeout(() => goto('/auth'), 2000);
          return;
        }

        if (type === 'recovery') {
          goto('/profile?reset=true', { invalidateAll: true });
        } else {
          localStorage.setItem('vitacora_just_logged_in', 'true');
          goto('/dashboard', { invalidateAll: true });
        }
      } catch (e) {
        status = 'Error de conexión';
        setTimeout(() => goto('/auth'), 2000);
      }
    } else {
      status = 'Token no encontrado';
      setTimeout(() => goto('/auth'), 2000);
    }
  });
</script>

<div class="callback-page">
  <div class="spinner"></div>
  <p>{status}</p>
</div>

<style>
  .callback-page {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 16px;
    background: var(--bg);
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid var(--border);
    border-top-color: var(--accent-green);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  p {
    color: var(--text2);
    font-family: var(--font-mono);
  }
</style>