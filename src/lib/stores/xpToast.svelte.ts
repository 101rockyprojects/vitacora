export interface XpToast {
  id: string;
  icon: string;
  label: string;
  xp?: number;
}

export const TOAST_DURATION_MS = 3000;
const MAX_TOASTS = 3;

class XpToastStore {
  toasts = $state<XpToast[]>([]);

  show(toast: Omit<XpToast, 'id'>) {
    if (typeof window === 'undefined') return;
    const id = crypto.randomUUID();
    this.toasts = [...this.toasts.slice(-(MAX_TOASTS - 1)), { id, ...toast }];
    setTimeout(() => this.dismiss(id), TOAST_DURATION_MS);
  }

  dismiss(id: string) {
    this.toasts = this.toasts.filter((t) => t.id !== id);
  }
}

export const xpToastStore = new XpToastStore();
