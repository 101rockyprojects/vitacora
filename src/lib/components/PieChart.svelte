<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import type { ApexOptions } from 'apexcharts';
  import type { ExpenseCategory } from '$lib/types';

  let { data = [], type = 'bar', title = '' }: {
    data: ExpenseCategory[];
    type?: 'bar' | 'pie';
    title?: string;
  } = $props();

  let chartEl: HTMLDivElement;
  let chart: any = null;

  const colors = [
    '#73e7bd',
    '#ebd57f',
    '#ee9863',
    '#5d99ee',
    '#9294f5',
    '#ee8888',
    '#6bcfcf',
    '#f5a3b8',
    '#a3d9a5',
    '#d4c4fb'
  ];

  const darkColors = colors.map(c => c);

  $effect(() => {
    if (!browser || !chartEl || data.length === 0) return;
    updateChart();
  });

  async function initChart() {
    if (!browser || !chartEl) return;

    const ApexCharts = (await import('apexcharts')).default;

    chart = new ApexCharts(chartEl, getOptions());
    chart.render();
  }

  function updateChart() {
    if (chart) {
      chart.updateSeries(getSeries());
      chart.updateOptions(getOptions());
    } else {
      initChart();
    }
  }

  function getSeries() {
    if (type === 'pie') {
      return data.map(d => d.total);
    }
    return [{
      name: 'Gastos',
      data: data.map(d => d.total)
    }];
  }

  function getOptions(): ApexOptions {
    const isDark = true;

    if (type === 'pie') {
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
          labels: { colors: '#9aa3bd' },
          fontSize: '12px'
        },
        dataLabels: {
          enabled: false
        },
        plotOptions: {
          pie: {
            donut: {
              size: '65%',
              labels: {
                show: true,
                total: {
                  show: true,
                  label: 'Total',
                  color: '#9aa3bd',
                  fontSize: '12px',
                  fontFamily: 'Space Mono, monospace',
                  formatter: (w) => {
                    const total = w.globals.seriesTotals.reduce((a: number, b: number) => a + b, 0);
                    return '$' + total.toFixed(2);
                  }
                }
              }
            }
          }
        },
        tooltip: {
          theme: 'dark',
          y: {
            formatter: (val) => '$' + val.toFixed(2)
          }
        },
        stroke: {
          show: false
        }
      };
    }

    return {
      chart: {
        type: 'bar',
        height: 280,
        fontFamily: 'DM Sans, sans-serif',
        toolbar: { show: false },
        animations: { enabled: true },
        background: 'transparent'
      },
      colors: [colors[0]],
      series: [{
        name: 'Gastos',
        data: data.map(d => d.total)
      }],
      xaxis: {
        categories: data.map(d => d.name),
        labels: {
          style: { colors: '#9aa3bd', fontSize: '11px', fontFamily: 'Space Mono, monospace' }
        },
        axisBorder: { show: false },
        axisTicks: { show: false }
      },
      yaxis: {
        labels: {
          style: { colors: '#9aa3bd', fontSize: '11px', fontFamily: 'Space Mono, monospace' },
          formatter: (val) => '$' + val.toFixed(0)
        }
      },
      grid: {
        borderColor: '#333d57',
        strokeDashArray: 4
      },
      plotOptions: {
        bar: {
          borderRadius: 4,
          horizontal: false,
          columnWidth: '60%',
          dataLabels: { position: 'top' }
        }
      },
      dataLabels: {
        enabled: false
      },
      tooltip: {
        theme: 'dark',
        y: {
          formatter: (val) => '$' + val.toFixed(2)
        }
      },
      legend: { show: false }
    };
  }

  onMount(() => {
    if (data.length > 0) {
      initChart();
    }
    return () => {
      if (chart) {
        chart.destroy();
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
    font-size: 14px;
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

  :global(.apexcharts-tooltip) {
    background: var(--bg2) !important;
    border: 1px solid var(--border) !important;
    color: var(--text) !important;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
  }

  :global(.apexcharts-tooltip-title) {
    background: var(--bg3) !important;
    border-bottom: 1px solid var(--border) !important;
    color: var(--text) !important;
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