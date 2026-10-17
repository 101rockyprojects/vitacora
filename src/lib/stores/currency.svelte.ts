import { browser } from '$app/environment';

export type Currency = 'dollar' | 'euro';

const CURRENCY_KEY = 'vitacora_currency';

const CURRENCY_SYMBOLS: Record<Currency, { symbol: string; before: boolean }> = {
  dollar: { symbol: '$', before: true },
  euro: { symbol: '€', before: false }
};

function createCurrencyStore() {
  let stored = browser ? localStorage.getItem(CURRENCY_KEY) : null;
  let _value = $state<Currency>(stored === 'euro' ? 'euro' : 'dollar');

  return {
    get value(): Currency { return _value; },
    get symbol(): string { return CURRENCY_SYMBOLS[_value].symbol; },
    set(value: Currency) {
      if (browser) localStorage.setItem(CURRENCY_KEY, value);
      _value = value;
    },
    toggle() {
      this.set(_value === 'dollar' ? 'euro' : 'dollar');
    },
    format(amount: number): string {
      const { symbol, before } = CURRENCY_SYMBOLS[_value];
      return before ? `${symbol}${amount.toFixed(2)}` : `${amount.toFixed(2)}${symbol}`;
    }
  };
}

export const currencyStore = createCurrencyStore();
