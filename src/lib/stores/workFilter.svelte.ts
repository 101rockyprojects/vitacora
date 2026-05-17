import { browser } from '$app/environment';

function createWorkFilterStore() {
  let stored = browser ? localStorage.getItem('vitacora_work_filter_tag') ?? 'trabajo' : 'trabajo';
  let _value = $state(stored);

  return {
    get value() { return _value; },
    set(value: string) {
      if (browser) localStorage.setItem('vitacora_work_filter_tag', value);
      _value = value;
    },
    reset() {
      if (browser) localStorage.removeItem('vitacora_work_filter_tag');
      _value = 'trabajo';
    }
  };
}

export const workFilterTag = createWorkFilterStore();