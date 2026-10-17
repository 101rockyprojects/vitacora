export interface XpToast {
  id: string;
  amount: number;
  message: string;
}

const MAX_TOASTS = 3;
const TOAST_DURATION_MS = 5000;

class XpToastStore {
  toasts = $state<XpToast[]>([]);

  show(amount: number, message: string) {
    if (typeof window === 'undefined') return;
    const id = crypto.randomUUID();
    this.toasts = [...this.toasts.slice(-(MAX_TOASTS - 1)), { id, amount, message }];
    setTimeout(() => this.dismiss(id), TOAST_DURATION_MS);
  }

  dismiss(id: string) {
    this.toasts = this.toasts.filter((t) => t.id !== id);
  }
}

export const xpToastStore = new XpToastStore();
