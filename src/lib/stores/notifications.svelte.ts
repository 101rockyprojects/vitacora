export interface Notification {
  id: string;
  type: 'urgent' | 'warning' | 'info';
  title: string;
  message: string;
  link: string;
  createdAt: number;
  read: boolean;
}

class NotificationStore {
  notifications = $state<Notification[]>([]);
  showMenu = $state(false);

  private timers = new Map<string, ReturnType<typeof setTimeout>>();

  addNotification(notification: Omit<Notification, 'id' | 'createdAt' | 'read'>) {
    const id = crypto.randomUUID();
    const newNotification: Notification = {
      ...notification,
      id,
      createdAt: Date.now(),
      read: false
    };

    this.notifications = [newNotification, ...this.notifications];

    const timer = setTimeout(() => {
      this.removeNotification(id);
    }, 30000);

    this.timers.set(id, timer);
  }

  removeNotification(id: string) {
    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }
    this.notifications = this.notifications.filter(n => n.id !== id);
  }

  markAsRead(id: string) {
    this.notifications = this.notifications.map(n =>
      n.id === id ? { ...n, read: true } : n
    );
  }

  markAllAsRead() {
    this.notifications = this.notifications.map(n => ({ ...n, read: true }));
  }

  toggleMenu() {
    this.showMenu = !this.showMenu;
  }

  closeMenu() {
    this.showMenu = false;
  }

  get unreadCount() {
    return this.notifications.filter(n => !n.read).length;
  }

  clearAll() {
    for (const timer of this.timers.values()) {
      clearTimeout(timer);
    }
    this.timers.clear();
    this.notifications = [];
  }
}

export const notificationStore = new NotificationStore();