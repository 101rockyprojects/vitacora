<script lang="ts">
  import type { Expense } from '$lib/types';
  import PieChart from '$lib/components/PieChart.svelte';

  interface Props {
    expenses?: Expense[];
  }

  let { expenses = [] }: Props = $props();

  const now = new Date();
  const currentMonth = now.toISOString().substring(0, 7);

  const currentMonthExpenses = $derived(expenses.filter(e => e.expense_date.startsWith(currentMonth)));
  const currentMonthTotal = $derived(currentMonthExpenses.reduce((sum, e) => sum + (e.cost || 0), 0));

  const currentMonthByCategory = $derived(() => {
    const categories: Record<string, number> = {};
    for (const e of currentMonthExpenses) {
      const cat = e.category || 'Sin categoría';
      categories[cat] = (categories[cat] || 0) + (e.cost || 0);
    }
    const total = Object.values(categories).reduce((a, b) => a + b, 0);
    return Object.entries(categories)
      .map(([name, total]) => ({ name, total, percentage: total > 0 ? (total / total) * 100 : 0 }))
      .sort((a, b) => b.total - a.total);
  });
</script>

<div class="card expenses-card">
  <h3 class="card-title">Gastos del mes <a href="/goals?tab=expenses" class="card-link">Ver gastos →</a></h3>
  {#if currentMonthByCategory().length > 0}
    <div class="expenses-chart">
      <PieChart data={currentMonthByCategory()} type="pie" />
    </div>
    <div class="month-expense-total">
      Total: <span>${currentMonthTotal.toFixed(2)}</span>
    </div>
  {:else}
    <div class="empty-state">Sin gastos este mes</div>
  {/if}
</div>

<style>
  .expenses-card {
    grid-column: span 1;
    display: flex;
    flex-direction: column;
  }

  .card-title {
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-family: var(--font-display);
  }

  .card-link {
    font-size: 12px;
    color: var(--accent-green);
    font-weight: 500;
    font-family: var(--font-body);
  }

  .expenses-chart {
    display: flex;
    justify-content: center;
    margin: 10px 0;
    min-height: 280px;
  }

  .month-expense-total {
    text-align: center;
    font-size: 13px;
    color: var(--text2);
    font-family: var(--font-mono);
  }

  .month-expense-total span {
    font-weight: 700;
    color: var(--accent-yellow);
    font-size: 16px;
  }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: center;
    padding: 24px 0;
  }
</style>