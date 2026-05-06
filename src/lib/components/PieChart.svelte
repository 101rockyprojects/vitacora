<script lang="ts">
  import { browser } from '$app/environment';
  import type { ApexOptions } from 'apexcharts';
  import type { ExpenseCategory } from '$lib/types';

  let { data = [], type = 'pie', title = '' }: {
    data: ExpenseCategory[];
    type?: 'pie';
    title?: string;
  } = $props();

  let chartEl: HTMLDivElement;
  let chart: any = null;
  let cleanup: (() => void) | null = null;

  const colors = [
    '#73e7bd', '#ebd57f', '#ee9863', '#5d99ee', '#9294f5',
    '#ee8888', '#6bcfcf', '#f5a3b8', '#a3d9a5', '#d4c4fb'
  ];

  async function renderChart() {
    if (!browser || !chartEl || data.length === 0) return;

    // 1. Destruir gráfico anterior si existe
    if (chart) {
      await chart.destroy();
      chart = null;
    }

    // 2. Limpiar el contenedor manualmente (por si quedan restos)
    while (chartEl.firstChild) {
      chartEl.removeChild(chartEl.firstChild);
    }

    // 3. Importar ApexCharts dinámicamente
    const ApexCharts = (await import('apexcharts')).default;

    // 4. Crear nueva instancia
    chart = new ApexCharts(chartEl, getOptions());
    await chart.render();
  }

  function getOptions(): ApexOptions {
    return {
      chart: {
        type: 'donut',
        height: 280,
        fontFamily: 'DM Sans, sans-serif',
        toolbar: { show: false },
        animations: { enabled: true }
      },
      colors: colors,
      series: data.map(d => d.total),
      labels: data.map(d => d.name),
      legend: {
        position: 'bottom',
        labels: { colors: '#c8cdd8' },
        fontSize: '12px'
      },
      dataLabels: { enabled: false },
      plotOptions: {
        pie: {
          donut: {
            size: '65%',
            labels: {
              show: true,
              name: {
                show: true,
                fontSize: '12px',
                fontFamily: 'Space Mono, monospace',
                color: '#9aa3bd',
                offsetY: -10
              },
              value: {
                show: true,
                fontSize: '25px',
                fontFamily: 'Space Mono, monospace',
                color: '#c8cdd8',
                fontWeight: 'bold',
                offsetY: 10,
                formatter: (val) => `$${Number(val).toFixed(2)}`
              },
              total: {
                show: true,
                label: 'Total',
                color: '#9aa3bd',
                fontSize: '12px',
                fontFamily: 'Space Mono, monospace',
                formatter: (w) => {
                  const total = w.globals.seriesTotals.reduce((a: number, b: number) => a + b, 0);
                  return `$${total.toFixed(2)}`;
                }
              }
            }
          }
        }
      },
      tooltip: {
        theme: 'dark',
        style: { fontSize: '15px', fontFamily: 'Space Mono, monospace' },
        y: { formatter: (val) => `$${val.toFixed(2)}` }
      },
      stroke: { show: false }
    };
  }

  // Único efecto reactivo: cuando data o chartEl cambien, recrea el gráfico
  $effect(() => {
    if (browser && chartEl && data.length > 0) {
      renderChart();
    }
  });

  // Cleanup al desmontar
  $effect(() => {
    return () => {
      if (chart) {
        chart.destroy();
        chart = null;
      }
    };
  });
</script>

<div class="chart-container">
  {#if title}
    <h3 class="chart-title">{title}</h3>
  {/if}
  <div bind:this={chartEl} class="chart-element"></div>
  {#if data.length === 0}
    <div class="empty-chart">Sin datos</div>
  {/if}
</div>

<style>
  .chart-container {
    width: 100%;
    min-height: 280px;
  }
  .chart-element {
    width: 100%;
  }
  .chart-title {
    font-size: 20px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 12px;
    font-family: var(--font-display);
  }
  .empty-chart {
    color: var(--text3);
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: center;
    padding: 40px;
  }
  :global(.apexcharts-tooltip-title) {
    color: var(--bg2) !important;
    font-weight: 700 !important;
  }
  
  :global(.apexcharts-tooltip) {
    background: var(--bg2) !important;
    border: 1px solid var(--border) !important;
    color: var(--bg2) !important;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
  }

  :global(.apexcharts-tooltip-title) {
    background: var(--bg3) !important;
    border-bottom: 1px solid var(--border) !important;
    color: var(--bg2) !important;
    font-family: var(--font-mono) !important;
  }

  :global(.apexcharts-xaxistooltip) {
    background: var(--bg2) !important;
    border: 1px solid var(--border) !important;
    color: var(--text) !important;
  }

  :global(.apexcharts-yaxistooltip) {
    background: var(--bg2) !important;
    border: 1px solid var(--border) !important;
    color: var(--text) !important;
  }
</style>