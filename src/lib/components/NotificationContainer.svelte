<script lang="ts">
  import { notificationStore, type Notification } from '$lib/stores/notifications.svelte';
  import { goto } from '$app/navigation';

  const { notifications, showMenu, unreadCount } = $derived(notificationStore);

  function handleClick(notification: Notification) {
    notificationStore.markAsRead(notification.id);
    notificationStore.removeNotification(notification.id);
    goto(notification.link);
  }

  function formatTime(timestamp: number): string {
    const seconds = Math.floor((Date.now() - timestamp) / 1000);
    if (seconds < 60) return 'Ahora';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m`;
    return `${Math.floor(minutes / 60)}h`;
  }

  function getTypeStyles(type: Notification['type']) {
    switch (type) {
      case 'urgent':
        return 'border-l-4 border-red-500 bg-red-500/10';
      case 'warning':
        return 'border-l-4 border-yellow-500 bg-yellow-500/10';
      default:
        return 'border-l-4 border-blue-500 bg-blue-500/10';
    }
  }

  function getTypeIcon(type: Notification['type']) {
    switch (type) {
      case 'urgent': return '🔴';
      case 'warning': return '🟡';
      default: return '🔵';
    }
  }
</script>

<div class="notification-container">
  {#each notifications.slice(0, 3) as notification (notification.id)}
    <div
      class="toast-notification {getTypeStyles(notification.type)}"
      onclick={() => handleClick(notification)}
      onkeydown={(e) => e.key === 'Enter' && handleClick(notification)}
      role="button"
      tabindex="0"
    >
      <span class="toast-icon">{getTypeIcon(notification.type)}</span>
      <div class="toast-content">
        <div class="toast-title">{notification.title}</div>
        <div class="toast-message">{notification.message}</div>
      </div>
      <button
        class="toast-close"
        onclick={(e) => { e.stopPropagation(); notificationStore.removeNotification(notification.id); }}
        type="button"
        aria-label="Cerrar"
      >
        ✕
      </button>
    </div>
  {/each}

  <div class="notification-bell">
    <button
      class="bell-btn"
      onclick={() => notificationStore.toggleMenu()}
      type="button"
      aria-label="Notificaciones"
      aria-expanded={showMenu}
    >
      🔔
      {#if unreadCount > 0}
        <span class="bell-badge">{unreadCount > 9 ? '9+' : unreadCount}</span>
      {/if}
    </button>

    {#if showMenu}
      <div class="notification-menu" role="menu">
        <div class="menu-header">
          <span>Notificaciones</span>
          {#if unreadCount > 0}
            <button type="button" class="mark-read-btn" onclick={() => notificationStore.markAllAsRead()}>
              Marcar todo leido
            </button>
          {/if}
        </div>

        {#if notifications.length === 0}
          <div class="menu-empty">Sin notificaciones</div>
        {:else}
          <div class="menu-list">
            {#each notifications as notification (notification.id)}
              <button
                class="menu-item {getTypeStyles(notification.type)}"
                class:unread={!notification.read}
                onclick={() => handleClick(notification)}
                type="button"
              >
                <div class="menu-item-content">
                  <div class="menu-item-title">{notification.title}</div>
                  <div class="menu-item-message">{notification.message}</div>
                  <div class="menu-item-time">{formatTime(notification.createdAt)}</div>
                </div>
              </button>
            {/each}
          </div>
        {/if}
      </div>
    {/if}
  </div>
</div>

<style>
  .notification-container {
    position: fixed;
    top: 80px;
    right: 20px;
    z-index: 100;
    display: flex;
    flex-direction: column;
    gap: 10px;
    align-items: flex-end;
  }

  .toast-notification {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    padding: 12px 16px;
    background: var(--bg2);
    border-radius: var(--radius);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.4);
    max-width: 360px;
    cursor: pointer;
    transition: transform 0.2s ease, opacity 0.2s ease;
    text-align: left;
  }

  .toast-notification:hover {
    transform: translateY(-2px);
  }

  .toast-icon {
    font-size: 14px;
    flex-shrink: 0;
  }

  .toast-content {
    flex: 1;
    min-width: 0;
  }

  .toast-title {
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
    margin-bottom: 2px;
  }

  .toast-message {
    font-size: 12px;
    color: var(--text2);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .toast-close {
    font-size: 12px;
    color: var(--text3);
    padding: 2px;
    background: none;
    border: none;
    cursor: pointer;
    flex-shrink: 0;
  }

  .toast-close:hover {
    color: var(--text);
  }

  .notification-bell {
    position: relative;
  }

  .bell-btn {
    position: fixed;
    top: 20px;
    right: 20px;
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: var(--surface);
    border: 1px solid var(--border);
    font-size: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all var(--transition);
    z-index: 101;
  }

  .bell-btn:hover {
    background: var(--surface2);
    transform: scale(1.05);
  }

  .bell-badge {
    position: absolute;
    top: -4px;
    right: -4px;
    background: var(--accent-red);
    color: white;
    font-size: 10px;
    font-weight: 700;
    min-width: 18px;
    height: 18px;
    border-radius: 99px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0 4px;
    animation: pulse 2s infinite;
  }

  .notification-menu {
    position: fixed;
    top: 70px;
    right: 20px;
    width: 340px;
    max-height: 400px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5);
    overflow: hidden;
    z-index: 102;
  }

  .menu-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 14px 16px;
    border-bottom: 1px solid var(--border);
    background: var(--bg3);
  }

  .menu-header span {
    font-weight: 700;
    font-size: 14px;
    color: var(--text);
  }

  .mark-read-btn {
    font-size: 11px;
    color: var(--accent-green);
    background: none;
    border: none;
    cursor: pointer;
    font-family: var(--font-mono);
  }

  .mark-read-btn:hover {
    text-decoration: underline;
  }

  .menu-empty {
    padding: 30px;
    text-align: center;
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
  }

  .menu-list {
    max-height: 320px;
    overflow-y: auto;
  }

  .menu-item {
    display: block;
    width: 100%;
    padding: 12px 16px;
    text-align: left;
    background: none;
    border: none;
    border-bottom: 1px solid var(--border);
    cursor: pointer;
    transition: background var(--transition);
  }

  .menu-item:hover {
    background: var(--bg3);
  }

  .menu-item.unread {
    background: rgba(168, 230, 207, 0.05);
  }

  .menu-item-title {
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
    margin-bottom: 2px;
  }

  .menu-item-message {
    font-size: 12px;
    color: var(--text2);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .menu-item-time {
    font-size: 10px;
    color: var(--text3);
    font-family: var(--font-mono);
    margin-top: 4px;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
  }
</style>