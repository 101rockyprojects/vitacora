<script lang="ts">
  import type { Expense, Subscription } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import { awardXP, XP_VALUES } from '$lib/utils/xp';
  import PieChart from '$lib/components/PieChart.svelte';
  import { page } from '$app/state';

  let { userId = $derived(page.data.user?.id ?? page.data.session?.user?.id ?? '') } = $props();

  const repo = $derived(createRepository(userId));

  const CURRENCY_KEY = 'vitacora_currency';
  const CURRENCY_SYMBOLS: Record<string, { symbol: string; before: boolean }> = {
    dollar: { symbol: '$', before: true },
    euro: { symbol: '€', before: false }
  };

  let currency = $state<string>('dollar');
  let expenses = $state<Expense[]>([]);
  let subscriptions = $state<Subscription[]>([]);
  let loading = $state(true);

  let showExpenseForm = $state(false);
  let editingExpenseId = $state<string | null>(null);
  let expenseForm = $state<Expense>({ name: '', category: '', cost: 0, expense_date: new Date().toISOString().split('T')[0] });
  let isSubscription = $state(false);
  let subscriptionPeriod = $state(1);

  let expenseFilterCategory = $state('');
  let expenseFilterStartDate = $state('');
  let expenseFilterEndDate = $state('');
  let saving = $state(false);

  function formatCurrency(amount: number): string {
    const { symbol, before } = CURRENCY_SYMBOLS[currency] || CURRENCY_SYMBOLS.dollar;
    return before ? `${symbol}${amount.toFixed(2)}` : `${amount.toFixed(2)}${symbol}`;
  }

  function initDates() {
    const now = new Date();
    expenseFilterStartDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    expenseFilterEndDate = '';
  }

  function loadCurrency() {
    if (typeof window === 'undefined') return;
    const stored = localStorage.getItem(CURRENCY_KEY);
    if (stored) currency = stored;
  }

  function toggleCurrency() {
    currency = currency === 'dollar' ? 'euro' : 'dollar';
    localStorage.setItem(CURRENCY_KEY, currency);
  }

  $effect(() => {
    if (typeof window !== 'undefined' && !expenseFilterStartDate) {
      loadCurrency();
      initDates();
    }
  });

  $effect(() => {
    if (userId && loading) {
      loadData();
    }
  });

  async function loadData() {
    if (!userId) return;
    const [expRes, subRes] = await Promise.all([
      repo.expenses.list(),
      repo.subscriptions.list()
    ]);
    expenses = expRes.data || [];
    subscriptions = subRes.data || [];
    loading = false;
  }

  const usedCategories = $derived([...new Set(expenses.map(e => e.category))].filter(Boolean));

  const filteredExpenses = $derived(() => {
    let result = [...expenses];
    if (expenseFilterCategory) {
      result = result.filter(e => e.category === expenseFilterCategory);
    }
    if (expenseFilterStartDate) {
      result = result.filter(e => e.expense_date >= expenseFilterStartDate);
    }
    if (expenseFilterEndDate) {
      result = result.filter(e => e.expense_date <= expenseFilterEndDate);
    }
    return result;
  });

  const expensesTotal = $derived(filteredExpenses().reduce((sum, e) => sum + (e.cost || 0), 0));

  const expensesByCategory = $derived(() => {
    const categories: Record<string, number> = {};
    for (const e of filteredExpenses()) {
      const cat = e.category || 'Sin categoría';
      categories[cat] = (categories[cat] || 0) + (e.cost || 0);
    }
    const grandTotal = Object.values(categories).reduce((a, b) => a + b, 0);
    return Object.entries(categories)
      .map(([name, total]) => ({ name, total, percentage: grandTotal > 0 ? (total / grandTotal) * 100 : 0 }))
      .sort((a, b) => b.total - a.total);
  });

  const expensesByMonth = $derived(() => {
    const months: Record<string, Expense[]> = {};
    for (const e of filteredExpenses()) {
      const monthKey = e.expense_date.substring(0, 7);
      if (!months[monthKey]) months[monthKey] = [];
      months[monthKey].push(e);
    }
    return Object.entries(months)
      .sort(([a], [b]) => b.localeCompare(a))
      .map(([month, items]) => ({
        month,
        monthLabel: new Date(month + '-01').toLocaleDateString('es-ES', { year: 'numeric', month: 'long' }),
        items,
        total: items.reduce((sum, e) => sum + (e.cost || 0), 0)
      }));
  });

  function getNextPaymentDate(sub: Subscription): string {
    const base = sub.last_paid_date || sub.start_date;
    const next = new Date(base);
    next.setMonth(next.getMonth() + sub.period_months);
    return next.toISOString().split('T')[0];
  }

  function getDaysUntilPayment(sub: Subscription): number {
    const next = new Date(getNextPaymentDate(sub));
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    next.setHours(0, 0, 0, 0);
    return Math.ceil((next.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  }

  function resetExpenseForm() {
    expenseForm = { name: '', category: '', cost: 0, expense_date: new Date().toISOString().split('T')[0] };
    editingExpenseId = null;
    isSubscription = false;
    subscriptionPeriod = 1;
  }

  async function saveExpense() {
    if (!expenseForm.name.trim() || !expenseForm.category.trim() || expenseForm.cost <= 0) return;
    saving = true;
    if (editingExpenseId) {
      await repo.expenses.update(editingExpenseId, { ...expenseForm });
    } else {
      await repo.expenses.insert(expenseForm);
      await awardXP(userId, 'selfcare', 'expense_logged', XP_VALUES.expense_logged);
    }

    if (isSubscription && !editingExpenseId) {
      await repo.subscriptions.insert({
        name: expenseForm.name,
        category: expenseForm.category,
        cost: expenseForm.cost,
        start_date: expenseForm.expense_date,
        period_months: subscriptionPeriod,
        is_active: true,
        last_paid_date: expenseForm.expense_date
      });
    }

    showExpenseForm = false;
    resetExpenseForm();
    await loadData();
    saving = false;
  }

  function editExpense(e: Expense) {
    editingExpenseId = e.id || null;
    expenseForm = { ...e };
    isSubscription = false;
    showExpenseForm = true;
  }

  async function deleteExpense(id: string) {
    if (!confirm('¿Eliminar gasto?')) return;
    await repo.expenses.remove(id);
    await loadData();
  }

  function clearExpenseFilters() {
    expenseFilterCategory = '';
    initDates();
  }

  async function markSubscriptionPaid(sub: Subscription) {
    if (!sub.id) return;
    const today = new Date().toISOString().split('T')[0];
    await repo.subscriptions.update(sub.id, { last_paid_date: today });
    await repo.expenses.insert({
      name: sub.name,
      category: sub.category,
      cost: sub.cost,
      expense_date: today
    });
    await loadData();
  }

  async function toggleSubscriptionActive(sub: Subscription) {
    if (!sub.id) return;
    await repo.subscriptions.update(sub.id, { is_active: !sub.is_active });
    await loadData();
  }

  async function deleteSubscription(id: string) {
    if (!confirm('¿Eliminar suscripción?')) return;
    await repo.subscriptions.remove(id);
    await loadData();
  }
</script>

<div class="fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Gastos</h2>
      <div class="section-subtitle">Controla tus finanzas</div>
    </div>
  </div>

  <div class="expenses-toolbar">
    <button class="btn btn-primary" onclick={() => { resetExpenseForm(); showExpenseForm = true; }}>+ Agregar gasto</button>
    <button class="currency-toggle" onclick={toggleCurrency} title="Cambiar moneda">
      {currency === 'dollar' ? '$ Dólar' : '€ Euro'}
    </button>
  </div>

  <div class="expenses-filters">
    <label class="filter-label">
      <span>Categoría</span>
      <select bind:value={expenseFilterCategory} class="expense-filter-select">
        <option value="">Total</option>
        {#each usedCategories as cat}
          <option value={cat}>{cat}</option>
        {/each}
      </select>
    </label>
    <label class="filter-label">
      <span>Desde</span>
      <input type="date" bind:value={expenseFilterStartDate} class="expense-filter-date" />
    </label>
    <label class="filter-label">
      <span>Hasta</span>
      <input type="date" bind:value={expenseFilterEndDate} class="expense-filter-date" />
    </label>
    {#if expenseFilterCategory || expenseFilterEndDate}
      <button class="btn btn-ghost" onclick={clearExpenseFilters}>Limpiar</button>
    {/if}
  </div>

  {#if !expenseFilterCategory && expensesByCategory().length > 0}
    <div class="card expenses-chart-card">
      <PieChart data={expensesByCategory()} type="pie" title="Gastos Totales" />
      <div class="expenses-total">
        Total: <span class="total-amount">{formatCurrency(expensesTotal)}</span>
      </div>
    </div>
  {:else if expenseFilterCategory && expensesByMonth().length > 0}
    {@const monthData = expensesByMonth()}
    {@const grandTotal = monthData.reduce((sum, m) => sum + m.total, 0)}
    <div class="card expenses-total-card">
      <PieChart data={monthData.map(m => ({ name: m.monthLabel, total: m.total, percentage: grandTotal > 0 ? (m.total / grandTotal) * 100 : 0 }))} type="pie" title="Gastos en {expenseFilterCategory}" />
      <div class="expenses-total">
        Total: <span class="total-amount">{formatCurrency(expensesTotal)}</span>
      </div>
    </div>
  {/if}

  {#if expensesByMonth().length === 0}
    <div class="empty-state card">Agrega tus primeros gastos 💰</div>
  {:else}
    <div class="expenses-groups">
      {#each expensesByMonth() as monthGroup}
        <div class="expense-month-group">
          <div class="expense-month-header">
            <span class="month-label">{monthGroup.monthLabel}</span>
            <span class="month-total">{formatCurrency(monthGroup.total)}</span>
          </div>
          <div class="expense-items">
            {#each monthGroup.items as exp (exp.id)}
              <div class="expense-item card">
                <div class="expense-info">
                  <div class="expense-name">{exp.name}</div>
                  <div class="expense-category">{exp.category}</div>
                </div>
                <div class="expense-meta">
                  <div class="expense-cost">{formatCurrency(exp.cost)}</div>
                  <div class="expense-date">{new Date(exp.expense_date).toLocaleDateString('es-ES')}</div>
                </div>
                <div class="card-actions-inline">
                  <button class="small-btn btn-secondary" onclick={() => editExpense(exp)}>🖋</button>
                  <button class="small-btn btn-ghost" onclick={() => deleteExpense(exp.id!)}>✕</button>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/each}
    </div>
  {/if}

  {#if subscriptions.length > 0}
    <div class="subscriptions-section">
      <h3 class="subscriptions-title">Suscripciones</h3>
      <div class="subscriptions-list">
        {#each subscriptions as sub (sub.id)}
          {@const nextDate = getNextPaymentDate(sub)}
          {@const daysLeft = getDaysUntilPayment(sub)}
          <div class="subscription-item card" class:inactive={!sub.is_active}>
            <div class="sub-info">
              <div class="sub-name">{sub.name}</div>
              <div class="sub-category">{sub.category}</div>
            </div>
            <div class="sub-dates">
              <div class="sub-next" class:urgent={sub.is_active && daysLeft <= 5}>
                Próximo: {new Date(nextDate).toLocaleDateString('es-ES')}
                {#if sub.is_active && daysLeft <= 5}
                  <span class="sub-days-badge">({daysLeft}d)</span>
                {/if}
              </div>
              <div class="sub-start">Inicio: {new Date(sub.start_date).toLocaleDateString('es-ES')}</div>
            </div>
            <div class="sub-cost">{formatCurrency(sub.cost)}</div>
            <div class="sub-actions">
              {#if sub.is_active}
                <button class="small-btn btn-primary" onclick={() => markSubscriptionPaid(sub)}>Pagado</button>
              {/if}
              <button class="small-btn btn-secondary" onclick={() => toggleSubscriptionActive(sub)}>
                {sub.is_active ? 'Pausar' : 'Activar'}
              </button>
              <button class="small-btn btn-ghost" onclick={() => deleteSubscription(sub.id!)}>✕</button>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>

{#if showExpenseForm}
  <div class="modal-backdrop" role="presentation" onclick={(e) => {
    if (e.target === e.currentTarget) { showExpenseForm = false; resetExpenseForm(); }
  }} onkeydown={(e) => e.key === 'Escape' && (showExpenseForm = false, resetExpenseForm())}>
    <div class="modal" role="document">
      <h3>{editingExpenseId ? 'Editar gasto' : 'Nuevo gasto'}</h3>
      <div class="form-group"><label for="expense-name">Nombre</label><input id="expense-name" bind:value={expenseForm.name} placeholder="¿En qué gastaste?" /></div>
      <div class="form-group">
        <label for="expense-category">Categoría</label>
        <input id="expense-category" bind:value={expenseForm.category} placeholder="Ej: Comida, Transporte..." list="expense-categories" />
        <datalist id="expense-categories">
          {#each usedCategories as cat}
            <option value={cat}></option>
          {/each}
        </datalist>
      </div>
      <div class="form-group"><label for="expense-cost">Costo ({CURRENCY_SYMBOLS[currency].symbol})</label><input id="expense-cost" type="number" bind:value={expenseForm.cost} min="0" step="0.01" placeholder="0.00" /></div>
      <div class="form-group"><label for="expense-date">Fecha</label><input id="expense-date" type="date" bind:value={expenseForm.expense_date} /></div>
      {#if !editingExpenseId}
        <div class="form-group form-check">
          <label class="check-label">
            <input type="checkbox" bind:checked={isSubscription} />
            <span>Es suscripción</span>
          </label>
        </div>
        {#if isSubscription}
          <div class="form-group"><label for="sub-period">Cada cuántos meses</label><input id="sub-period" type="number" bind:value={subscriptionPeriod} min="1" max="24" /></div>
        {/if}
      {/if}
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => { showExpenseForm = false; resetExpenseForm(); }}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveExpense} disabled={saving || !expenseForm.name.trim() || !expenseForm.category.trim() || expenseForm.cost <= 0}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .expenses-toolbar {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
  }

  .currency-toggle {
    padding: 6px 14px;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: var(--bg2);
    color: var(--text2);
    font-size: 13px;
    font-family: var(--font-mono);
    cursor: pointer;
    transition: all var(--transition);
  }

  .currency-toggle:hover { border-color: var(--accent-green); color: var(--text); }

  .expenses-filters {
    display: flex;
    gap: 12px;
    flex-wrap: wrap;
    margin-bottom: 20px;
    align-items: flex-end;
  }

  .filter-label {
    display: flex;
    flex-direction: column;
    gap: 4px;
    font-size: 12px;
    color: var(--text3);
  }

  .expense-filter-select, .expense-filter-date {
    padding: 8px 10px;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--bg2);
    color: var(--text);
    font-size: 13px;
  }

  .expenses-total {
    text-align: center;
    font-size: 13px;
    color: var(--text2);
    font-family: var(--font-mono);
    margin-top: 8px;
  }

  .total-amount {
    font-weight: 700;
    color: var(--accent-yellow);
    font-size: 16px;
  }

  .expenses-groups {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .expense-month-group {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .expense-month-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 8px;
    border-bottom: 1px solid var(--border);
  }

  .month-label {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
  }

  .month-total {
    font-size: 14px;
    font-weight: 700;
    color: var(--accent-yellow);
    font-family: var(--font-mono);
  }

  .expense-items {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .expense-item {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .expense-info { flex: 1; min-width: 0; }

  .expense-name {
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
  }

  .expense-category {
    font-size: 11px;
    color: var(--text3);
    margin-top: 2px;
  }

  .expense-meta { text-align: right; }

  .expense-cost {
    font-size: 13px;
    font-weight: 700;
    color: var(--accent-yellow);
    font-family: var(--font-mono);
  }

  .expense-date {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
    margin-top: 2px;
  }

  .subscriptions-section {
    margin-top: 32px;
  }

  .subscriptions-title {
    font-size: 16px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 12px;
  }

  .subscriptions-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .subscription-item {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
  }

  .subscription-item.inactive {
    opacity: 0.5;
  }

  .sub-info { flex: 1; min-width: 120px; }

  .sub-name {
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
  }

  .sub-category {
    font-size: 11px;
    color: var(--text3);
    margin-top: 2px;
  }

  .sub-dates {
    font-size: 11px;
    color: var(--text2);
    font-family: var(--font-mono);
  }

  .sub-next { margin-bottom: 2px; }
  .sub-next.urgent { color: var(--accent-red); }
  .sub-start { color: var(--text3); }

  .sub-days-badge {
    font-weight: 700;
  }

  .sub-cost {
    font-size: 13px;
    font-weight: 700;
    color: var(--accent-yellow);
    font-family: var(--font-mono);
    min-width: 80px;
    text-align: right;
  }

  .sub-actions {
    display: flex;
    gap: 4px;
  }

  .form-check {
    margin-bottom: 8px;
  }

  .check-label {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 13px;
    color: var(--text2);
    cursor: pointer;
  }

  .check-label input[type="checkbox"] {
    accent-color: var(--accent-green);
  }
</style>
