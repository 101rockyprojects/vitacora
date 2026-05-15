<script lang="ts">
  import Toast from '$lib/components/Toast.svelte';
  import { createRepository } from '$lib/services/repository';

  interface Props {
    userId: string;
  }

  let { userId }: Props = $props();
  const repo = $derived(createRepository(userId));

  let partnerProfile = $state<{ id: string; email: string; partner_since?: string } | null>(null);

  const daysTogether = $derived(() => {
    if (!partnerProfile?.partner_since) return 0;
    const connected = new Date(partnerProfile.partner_since);
    const now = new Date();
    const diffTime = now.getTime() - connected.getTime();
    return Math.floor(diffTime / (1000 * 60 * 60 * 24));
  });
  let myPartnerCode = $state('');
  let partnerCodeInput = $state('');
  let showConnectForm = $state(false);
  let connecting = $state(false);
  let partnerError = $state('');
  let copyToast = $state(false);
  let copyToastTimer: ReturnType<typeof setTimeout> | null = $state(null);
  let initialized = $state(false);

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadPartnerData();
    }
  });

  async function loadPartnerData() {
    const profile = await repo.partner.getProfile();
    if (profile) {
      myPartnerCode = profile.partner_code || '';
      if (profile.partner_id) {
        partnerProfile = await repo.partner.getPartnerProfile();
      }
    }

    if (!myPartnerCode) {
      myPartnerCode = repo.partner.generateCode();
      try {
        await repo.partner.setPartnerCode(myPartnerCode);
      } catch (e) {
        console.error('Failed to set partner code:', e);
      }
    }
  }

  async function copyPartnerCode(content: string) {
    try {
      await navigator.clipboard.writeText(content);
      copyToast = true;
      if (copyToastTimer) clearTimeout(copyToastTimer);
      copyToastTimer = setTimeout(() => {
        copyToast = false;
        copyToastTimer = null;
      }, 2500);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }

  async function connectWithPartner() {
    if (!partnerCodeInput.trim()) return;
    connecting = true;
    partnerError = '';
    try {
      const found = await repo.partner.searchByCode(partnerCodeInput.trim());
      if (!found) {
        partnerError = 'Código no encontrado';
        connecting = false;
        return;
      }
      if (found.partner_id) {
        partnerError = 'Este usuario ya tiene pareja';
        connecting = false;
        return;
      }
      await repo.partner.connect(found.id);
      partnerProfile = { id: found.id, email: found.email || '' };
      showConnectForm = false;
      partnerCodeInput = '';
    } catch (e: any) {
      partnerError = e.message || 'Error al conectar';
    }
    connecting = false;
  }

  async function disconnectPartner() {
    if (!confirm('¿Desconectar de tu pareja?')) return;
    if (!confirm('¿Estás seguro/a?')) return;
    await repo.partner.disconnect();
    partnerProfile = null;
  }
</script>

<Toast visible={copyToast} message="Copiado al portapapeles" />

<div class="partner-connection">
  <div class="partner-connection-status card">
    {#if partnerProfile}
      <div class="connected-section">
        <div class="partner-info">
          <span class="partner-icon">💑</span>
          <div>
            <div class="partner-label">Conectado con</div>
            <div class="partner-email">{partnerProfile.email}</div>
            {#if partnerProfile.partner_since}
              <div class="days-together">Juntos hace {daysTogether()} días</div>
            {/if}
          </div>
        </div>
        <button class="btn btn-ghost" onclick={disconnectPartner}>Desconectar</button>
      </div>
    {:else}
      <div class="disconnected-section">
        <section class="first-step">
          <div class="my-code">
            <span class="code-label">Tu código</span>
            <div class="code-display">
              <span class="code">{myPartnerCode}</span>
              <button class="copy-btn" onclick={() => copyPartnerCode(myPartnerCode)} title="Copiar">❏</button>
            </div>
          </div>
          <div class="connect-action">
            <button class="btn btn-secondary" onclick={() => showConnectForm = !showConnectForm}>
              {showConnectForm ? 'Cancelar' : 'Conectar con pareja'}
            </button>
          </div>
        </section>
      </div>
    {/if}
  </div>
  
  {#if showConnectForm && !partnerProfile}
    <form class="connect-form card">
      <div class="my-code-form">
        <div class="my-code">
          <span class="code-label">Código de tu pareja</span>
          <input
            type="text"
            bind:value={partnerCodeInput}
            placeholder="123456"
            maxlength="6"
            class="code-input"
            onkeydown={(e) => e.key === 'Enter' && connectWithPartner()}
          />
        </div>
      </div>
      <button class="btn btn-primary" onclick={connectWithPartner} disabled={connecting}>
        {connecting ? '...' : 'Conectar'}
      </button>
    </form>
    {#if partnerError}
      <div class="error-msg">{partnerError}</div>
    {/if}
  {/if}
</div>

<style>
  .partner-connection {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    margin-bottom: 20px;
  }

  .partner-connection-status {
    flex: 1;
  }
  
  .connect-form {
    flex: 0 1 auto;
  }

  .first-step {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
    gap: 16px;
  }

  .connected-section {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
  }

  .partner-info {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .partner-icon {
    font-size: 28px;
  }

  .partner-label {
    font-size: 11px;
    color: var(--text2);
    font-family: var(--font-mono);
    text-transform: uppercase;
  }

  .partner-email {
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
  }

  .days-together {
    font-size: 11px;
    color: var(--accent-green);
    font-family: var(--font-mono);
    margin-top: 2px;
  }

  .disconnected-section {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .my-code-form {
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .my-code {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .code-label {
    font-size: 11px;
    color: var(--text2);
    font-family: var(--font-mono);
    text-transform: uppercase;
  }

  .code-display {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .code {
    font-family: var(--font-mono);
    font-size: 20px;
    font-weight: 700;
    color: var(--accent-green);
    letter-spacing: 0.1em;
    background: var(--bg3);
    padding: 8px 16px;
    border-radius: var(--radius);
  }

  .copy-btn {
    background: var(--surface);
    color: var(--text);
    font-size: 20px;
    padding: 8px 10px;
    border-radius: var(--radius);
    cursor: pointer;
    transition: all var(--transition);
    border: none;
  }

  .copy-btn:hover {
    background: var(--surface2);
    color: var(--accent-green);
  }

  .connect-action {
    display: flex;
    justify-content: end;
  }

  .connect-form {
    display: flex;
    gap: 8px;
    justify-content: center;
    flex-wrap: wrap;
  }

  .code-input {
    text-transform: uppercase;
    letter-spacing: 0.1em;
    font-family: var(--font-mono);
    font-size: 16px;
    text-align: center;
    width: 160px;
  }

  .error-msg {
    text-align: center;
    color: var(--accent-red);
    font-size: 12px;
    font-family: var(--font-mono);
  }
</style>