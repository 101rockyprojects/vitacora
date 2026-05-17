<script lang="ts">
  import { enhance } from '$app/forms';
  import { goto } from '$app/navigation';
  import Toast from '$lib/components/Toast.svelte';

  let isLogin = $state(true);
  let error = $state('');
  let loading = $state(false);
  let showPassword = $state(false);
  let toastVisible = $state(false);
  let toastMessage = $state('');
  let toastTimer: ReturnType<typeof setTimeout> | null = null;

  function showToast(msg: string) {
    toastMessage = msg;
    toastVisible = true;
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toastVisible = false;
      toastTimer = null;
    }, 3000);
  }

  function handleSubmit({ result }: { result: { type: string; data?: { success?: boolean; action?: string; error?: string } } }) {
    loading = false;
    if (result.type === 'success' && result.data) {
      if (result.data.success) {
        if (result.data.action === 'login') {
          if (typeof window !== 'undefined') localStorage.setItem('vitacora_just_logged_in', 'true');
          showToast('Iniciando sesión, redireccionando...');
          setTimeout(() => goto('/dashboard'), 800);
        } else if (result.data.action === 'signup') {
          showToast('Se ha enviado un enlace de confirmación a tu correo');
        }
      } else if (result.data.error) {
        error = result.data.error;
      }
    } else if (result.type === 'failure' && result.data?.error) {
      error = result.data.error;
    }
  }
</script>

<div class="auth-page" class:loading>
  <div class="auth-bg">
    <div class="bg-orb orb1"></div>
    <div class="bg-orb orb2"></div>
    <div class="bg-orb orb3"></div>
  </div>

  {#if loading}
    <div class="loading-overlay">
      <div class="spinner"></div>
      <p>Iniciando sesión...</p>
    </div>
  {/if}

  <div class="auth-card fade-in">
    <Toast visible={toastVisible} message={toastMessage} />
    <div class="auth-logo">
      <span class="logo-glyph">◈</span>
      <h1>VitaCora</h1>
    </div>
    <p class="auth-tagline">Tu espacio de crecimiento personal</p>

    <div class="auth-tabs">
      <button class:active={isLogin} onclick={() => isLogin = true}>Entrar</button>
      <button class:active={!isLogin} onclick={() => isLogin = false}>Registrarse</button>
    </div>


    <form method="POST" action={isLogin ? '?/login' : '?/signup'} use:enhance={() => { loading = true; error = ''; return handleSubmit; }}>
      <div class="form-group">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" placeholder="tu@email.com" required disabled={loading} />
      </div>
      <div class="form-group password-group">
        <label for="password">Contraseña</label>
        <div class="password-input-wrap">
          <input 
            id="password" 
            name="password" 
            type={showPassword ? 'text' : 'password'} 
            placeholder="••••••••" 
            required 
            disabled={loading} 
          />
          <button type="button" class="toggle-password" onclick={() => showPassword = !showPassword} aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}>
            {showPassword ? '🙈' : '👁️'}
          </button>
        </div>
      </div>

      {#if error}
        <div class="auth-error">{error}</div>
      {/if}

      <button type="submit" class="btn btn-primary auth-submit" disabled={loading}>
        {loading ? '...' : isLogin ? 'Entrar' : 'Crear cuenta'}
      </button>
    </form>

    <div class="auth-quote">"1% better every day"</div>
  </div>
</div>

<style>
  .auth-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
  }

  .auth-bg { position: absolute; inset: 0; pointer-events: none; }

  .bg-orb {
    position: absolute;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.12;
  }
  .orb1 { width: 400px; height: 400px; background: var(--accent-green); top: -100px; left: -100px; }
  .orb2 { width: 300px; height: 300px; background: var(--accent-yellow); bottom: -50px; right: 100px; }
  .orb3 { width: 250px; height: 250px; background: var(--accent-orange); top: 50%; right: -50px; }

  .auth-card {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 40px;
    width: 100%;
    max-width: 400px;
    position: relative;
    z-index: 1;
    box-shadow: var(--shadow);
  }

  .auth-logo {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 8px;
  }

  .logo-glyph {
    font-size: 32px;
    color: var(--accent-green);
  }

  h1 {
    font-family: var(--font-display);
    font-size: 32px;
    font-weight: 800;
    letter-spacing: -0.04em;
  }

  .auth-tagline {
    color: var(--text3);
    font-size: 13px;
    margin-bottom: 28px;
    font-family: var(--font-mono);
  }

  .auth-tabs {
    display: flex;
    gap: 4px;
    background: var(--bg3);
    border-radius: var(--radius);
    padding: 4px;
    margin-bottom: 24px;
  }

  .auth-tabs button {
    flex: 1;
    padding: 8px;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 600;
    color: var(--text3);
    transition: all var(--transition);
  }

  .auth-tabs button.active {
    background: var(--surface2);
    color: var(--text);
  }

  .auth-error {
    background: rgba(255, 107, 107, 0.12);
    border: 1px solid rgba(255, 107, 107, 0.3);
    border-radius: var(--radius);
    padding: 10px 14px;
    font-size: 13px;
    color: var(--accent-red);
    margin-bottom: 16px;
  }

  .password-group { position: relative; }

  .password-input-wrap {
    position: relative;
    display: flex;
    align-items: center;
  }

  .password-input-wrap input {
    flex: 1;
    padding-right: 40px;
  }

  .toggle-password {
    position: absolute;
    right: 8px;
    background: none;
    border: none;
    cursor: pointer;
    font-size: 16px;
    padding: 4px;
    opacity: 0.7;
    transition: opacity var(--transition);
  }

  .toggle-password:hover { opacity: 1; }

  .auth-submit {
    width: 100%;
    justify-content: center;
    padding: 12px;
    font-size: 15px;
    margin-top: 8px;
  }

  .auth-quote {
    text-align: center;
    margin-top: 24px;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--text3);
    font-style: italic;
  }

  .auth-page.loading { pointer-events: none; }
  .auth-page.loading .auth-card { opacity: 0.5; }

  .loading-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    z-index: 100;
    gap: 16px;
  }

  .loading-overlay p {
    color: var(--text);
    font-size: 16px;
    font-family: var(--font-mono);
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
</style>
