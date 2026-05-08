<script lang="ts">
  import type { Expense } from '$lib/types';
  import { createRepository } from '$lib/services/repository';
  import PieChart from '$lib/components/PieChart.svelte';

  interface Props {
    userId: string;
    expenses?: Expense[];
    onRefresh?: () => void;
  }

  let { userId, expenses = $bindable([]), onRefresh }: Props = $props();

  const repo = $derived(createRepository(userId));

  let showExpenseForm = $state(false);
  let editingExpenseId = $state<string | null>(null);
  let expenseForm = $state<Expense>({ name: '', category: '', cost: 0, expense_date: new Date().toISOString().split('T')[0] });
  let expenseFilterCategory = $state('');
  let expenseFilterStartDate = $state('');
  let expenseFilterEndDate = $state('');
  let saving = $state(false);

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

  function resetExpenseForm() {
    expenseForm = { name: '', category: '', cost: 0, expense_date: new Date().toISOString().split('T')[0] };
    editingExpenseId = null;
  }

  async function saveExpense() {
    if (!expenseForm.name.trim() || !expenseForm.category.trim() || expenseForm.cost <= 0) return;
    saving = true;
    if (editingExpenseId) {
      await repo.expenses.update(editingExpenseId, { ...expenseForm });
    } else {
      await repo.expenses.insert(expenseForm);
    }
    showExpenseForm = false;
    resetExpenseForm();
    const { data } = await repo.expenses.list();
    expenses = data || [];
    saving = false;
  }

  function editExpense(e: Expense) {
    editingExpenseId = e.id || null;
    expenseForm = { ...e };
    showExpenseForm = true;
  }

  async function deleteExpense(id: string) {
    if (!confirm('¿Eliminar gasto?')) return;
    await repo.expenses.remove(id);
    const { data } = await repo.expenses.list();
    expenses = data || [];
  }

  function clearExpenseFilters() {
    expenseFilterCategory = '';
    expenseFilterStartDate = '';
    expenseFilterEndDate = '';
  }
</script>

<div class="fade-in">
  <div class="tab-actions">
    <button class="btn btn-primary" onclick={() => { resetExpenseForm(); showExpenseForm = true; }}>+ Agregar gasto</button>
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
      <input
        type="date"
        bind:value={expenseFilterStartDate}
        class="expense-filter-date"
      />
    </label>
    <label class="filter-label">
      <span>Hasta</span>
      <input
        type="date"
        bind:value={expenseFilterEndDate}
        class="expense-filter-date"
      />
    </label>
    {#if expenseFilterCategory || expenseFilterStartDate || expenseFilterEndDate}
      <button class="btn btn-ghost" onclick={clearExpenseFilters}>Limpiar</button>
    {/if}
  </div>

  {#if !expenseFilterCategory && expensesByCategory().length > 0}
    <div class="card expenses-chart-card">
      <PieChart data={expensesByCategory()} type="pie" title="Gastos Totales" />
      <div class="expenses-total">
        Total: <span class="total-amount">${expensesTotal.toFixed(2)}</span>
      </div>
    </div>
  {:else if expenseFilterCategory && expensesByMonth().length > 0}
    {@const monthData = expensesByMonth()}
    {@const grandTotal = monthData.reduce((sum, m) => sum + m.total, 0)}
    <div class="card expenses-total-card">
      <PieChart data={monthData.map(m => ({ name: m.monthLabel, total: m.total, percentage: grandTotal > 0 ? (m.total / grandTotal) * 100 : 0 }))} type="pie" title="Gastos en {expenseFilterCategory}" />
      <div class="expenses-total">
        Total: <span class="total-amount">${expensesTotal.toFixed(2)}</span>
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
            <span class="month-total">${monthGroup.total.toFixed(2)}</span>
          </div>
          <div class="expense-items">
            {#each monthGroup.items as exp (exp.id)}
              <div class="expense-item card">
                <div class="expense-info">
                  <div class="expense-name">{exp.name}</div>
                  <div class="expense-category">{exp.category}</div>
                </div>
                <div class="expense-meta">
                  <div class="expense-cost">${exp.cost.toFixed(2)}</div>
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
</div>

{#if showExpenseForm}
  <div class="modal-backdrop" onclick={(e) => {
        if (e.target === e.currentTarget) {
          showExpenseForm = false; resetExpenseForm();
        }
      }}>
    <div class="modal">
      <h3>{editingExpenseId ? 'Editar gasto' : 'Nuevo gasto'}</h3>
      <div class="form-group"><label>Nombre</label><input bind:value={expenseForm.name} placeholder="¿En qué gastaste?" /></div>
      <div class="form-group">
        <label>Categoría</label>
        <input
          bind:value={expenseForm.category}
          placeholder="Ej: Comida, Transporte..."
          list="expense-categories"
        />
        <datalist id="expense-categories">
          {#each usedCategories as cat}
            <option value={cat} />
          {/each}
        </datalist>
      </div>
      <div class="form-group"><label>Costo</label><input type="number" bind:value={expenseForm.cost} min="0" step="0.01" placeholder="0.00" /></div>
      <div class="form-group"><label>Fecha</label><input type="date" bind:value={expenseForm.expense_date} /></div>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick={() => { showExpenseForm = false; resetExpenseForm(); }}>Cancelar</button>
        <button class="btn btn-primary" onclick={saveExpense} disabled={saving || !expenseForm.name.trim() || !expenseForm.category.trim() || expenseForm.cost <= 0}>{saving ? '...' : 'Guardar'}</button>
      </div>
    </div>
  </div>
{/if}

<style>
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

  .expense-meta {
    text-align: right;
  }

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

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: center;
    padding: 24px 0;
  }
</style>