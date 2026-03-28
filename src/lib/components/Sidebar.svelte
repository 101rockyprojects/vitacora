<script lang="ts">
  import { page } from '$app/stores';
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import type { User } from '@supabase/supabase-js';

  let { user }: { user: User | null } = $props();

  const nav = [
    { href: '/dashboard', label: 'Dashboard', icon: '◈' },
    { href: '/goals', label: 'Visión & Metas', icon: '✦' },
    { href: '/work', label: 'Trabajo', icon: '⬡' },
    { href: '/partner', label: 'Partner', icon: '♡' },
    { href: '/profile', label: 'Perfil & XP', icon: '◎' }
  ];

  async function signOut() {
    await supabase.auth.signOut();
    goto('/auth');
  }

  const currentPath = $derived($page.url.pathname);
</script>

<aside class="sidebar">
  <div class="sidebar-logo">
    <span class="logo-icon">◈</span>
    <span class="logo-text">lumina</span>
  </div>

  <nav class="sidebar-nav">
    {#each nav as item}
      <a
        href={item.href}
        class="nav-item"
        class:active={currentPath === item.href || currentPath.startsWith(item.href + '/')}
      >
        <span class="nav-icon">{item.icon}</span>
        <span class="nav-label">{item.label}</span>
      </a>
    {/each}
  </nav>

  <div class="sidebar-bottom">
    {#if user}
      <div class="user-info">
        <div class="user-avatar">{user.email?.[0].toUpperCase()}</div>
        <div class="user-email">{user.email}</div>
      </div>
    {/if}
    <button class="sign-out-btn" onclick={signOut}>
      <span>↩</span> Salir
    </button>
  </div>
</aside>

<style>
  .sidebar {
    position: fixed;
    left: 0;
    top: 0;
    bottom: 0;
    width: var(--sidebar-width);
    background: var(--bg2);
    border-right: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    z-index: 50;
    padding: 24px 0;
  }

  .sidebar-logo {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 0 20px 24px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 16px;
  }

  .logo-icon {
    font-size: 22px;
    color: var(--accent-green);
  }

  .logo-text {
    font-family: var(--font-display);
    font-size: 20px;
    font-weight: 800;
    color: var(--text);
    letter-spacing: -0.03em;
  }

  .sidebar-nav {
    display: flex;
    flex-direction: column;
    gap: 2px;
    padding: 0 12px;
    flex: 1;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 12px;
    border-radius: var(--radius);
    color: var(--text2);
    font-size: 14px;
    font-weight: 500;
    transition: all var(--transition);
    position: relative;
  }

  .nav-item:hover {
    color: var(--text);
    background: var(--surface);
  }

  .nav-item.active {
    color: var(--accent-green);
    background: rgba(168, 230, 207, 0.1);
  }

  .nav-icon {
    font-size: 16px;
    width: 20px;
    text-align: center;
  }

  .sidebar-bottom {
    padding: 16px 12px 0;
    border-top: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .user-info {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px;
  }

  .user-avatar {
    width: 30px;
    height: 30px;
    border-radius: 50%;
    background: var(--accent-green);
    color: #0a1a0f;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 700;
  }

  .user-email {
    font-size: 12px;
    color: var(--text3);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .sign-out-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    border-radius: var(--radius);
    color: var(--text3);
    font-size: 13px;
    transition: all var(--transition);
    width: 100%;
    text-align: left;
  }

  .sign-out-btn:hover {
    color: var(--accent-red);
    background: rgba(255, 107, 107, 0.1);
  }
</style>
