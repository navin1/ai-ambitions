import client from './client'
import type { TileVal, DrillData, KpiDrillData } from './overview'

const TOP_UC = 25
const TRUNCATE_LEN = 40

// ── Helpers ───────────────────────────────────────────────────────────────────

function trunc(s: string, n = TRUNCATE_LEN): string {
  return s.length > n ? s.slice(0, n - 1) + '…' : s
}

function aggregateBy<T>(
  items: T[],
  keyFn: (i: T) => string | null | undefined,
  valFn: (i: T) => number,
): { name: string; actual: number }[] {
  const map = new Map<string, number>()
  for (const item of items) {
    const k = keyFn(item)
    if (!k) continue
    map.set(k, (map.get(k) ?? 0) + valFn(item))
  }
  return [...map.entries()]
    .map(([name, actual]) => ({ name, actual }))
    .sort((a, b) => b.actual - a.actual)
}

function sumTotal(rows: { actual: number }[], unit: 'dollar' | 'pts' | 'pct'): string {
  const t = rows.reduce((s, r) => s + r.actual, 0)
  if (unit === 'dollar') return `$${t.toFixed(1)}M`
  if (unit === 'pts')    return `${t.toFixed(2)} pts`
  return `${t.toFixed(1)}%`
}

function mkPanel(
  title: string, kpiId: string, dimKey: string,
  rows: { name: string; actual: number }[],
  valKey: string, barColor: string, totalStr: string,
) {
  const toRow = (r: { name: string; actual: number }) => ({ [dimKey]: r.name, [valKey]: +r.actual.toFixed(2) })
  return {
    title, kpi_id: kpiId,
    chart_type: 'horizontal_bar',
    data:       rows.slice(0, 10).map(toRow),
    table_data: rows.map(toRow),
    x_axis: dimKey, y_axis: [valKey],
    bar_color: barColor, total_str: totalStr,
  }
}

// ── Main export ───────────────────────────────────────────────────────────────

export async function exportOverviewPDF(
  period: string,
  kpis: TileVal[],
  investment: DrillData,
  kpiBreakdown: { revenue: KpiDrillData; nps: KpiDrillData; efficiency: KpiDrillData } | undefined,
  useCaseToCsg: Record<string, string | null>,
  filterArea?: string | null,
  filterCsg?: string | null,
): Promise<void> {
  // KPI order from backend: [0]=ai-cost, [1]=revenue, [2]=nps, [3]=efficiency
  const KPI_LABELS = ['AI Cost', 'Revenue Growth', 'NPS Improvement', 'Efficiency Gain']

  const matchesFilter = (label: string, fa?: string | null): boolean => {
    if (filterArea && fa !== filterArea) return false
    if (filterCsg && useCaseToCsg[label] !== filterCsg) return false
    return true
  }
  const matchesFilterInv = (fa?: string | null, csg?: string | null): boolean => {
    if (filterArea && fa !== filterArea) return false
    if (filterCsg && csg !== filterCsg) return false
    return true
  }

  const filterSuffix = [filterArea, filterCsg].filter(Boolean).join(' · ')
  const titleTag     = filterSuffix ? ` [${filterSuffix}]` : ''

  // ── 1. KPI headline summary ──────────────────────────────────────────────────
  const kpiTableData = kpis.map((k, i) => ({
    KPI: KPI_LABELS[i] ?? `KPI ${i + 1}`, Value: k.value, Delta: k.delta, Status: k.statusLabel,
  }))

  // ── Filter focus section for KPI page ───────────────────────────────────────
  let filterSubsection: { title: string; data: object[] } | null = null
  if (filterArea || filterCsg) {
    const revItems  = (kpiBreakdown?.revenue.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea))
    const npsItems  = (kpiBreakdown?.nps.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea))
    const effItems  = (kpiBreakdown?.efficiency.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea))
    const costItems = investment.byUseCase.filter(u => matchesFilterInv(u.functionalArea, u.csg))

    const revContrib  = revItems.reduce((s, i) => s + (i.dollarValue ?? i.value * 20), 0)
    const revPct      = revItems.reduce((s, i) => s + i.value, 0)
    const npsContrib  = npsItems.reduce((s, i) => s + i.value, 0)
    const effContrib  = effItems.reduce((s, i) => s + i.value, 0)
    const costContrib = costItems.reduce((s, u) => s + u.amount, 0)

    const pctOf = (part: number, total: number) =>
      total > 0 ? `${((part / total) * 100).toFixed(0)}% of total` : '—'

    filterSubsection = {
      title: `Filter Focus — ${filterSuffix}`,
      data: [
        { KPI: 'Revenue Growth',  Contribution: `$${revContrib.toFixed(1)}M`,   'vs. Total': pctOf(revPct, kpis[1]?.current ?? 0) },
        { KPI: 'NPS Improvement', Contribution: `${npsContrib.toFixed(2)} pts`, 'vs. Total': pctOf(npsContrib, kpis[2]?.current ?? 0) },
        { KPI: 'Efficiency Gain', Contribution: `${effContrib.toFixed(1)}%`,    'vs. Total': pctOf(effContrib, kpis[3]?.current ?? 0) },
        { KPI: 'AI Cost',         Contribution: `$${costContrib.toFixed(1)}M`,  'vs. Total': pctOf(costContrib, kpis[0]?.current ?? 0) },
      ],
    }
  }

  // ── 2. Aggregate by Functional Area (filtered) ───────────────────────────────
  const revByFA  = aggregateBy((kpiBreakdown?.revenue.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea)),   i => i.functionalArea, i => i.dollarValue ?? i.value * 20)
  const npsByFA  = aggregateBy((kpiBreakdown?.nps.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea)),        i => i.functionalArea, i => i.value)
  const effByFA  = aggregateBy((kpiBreakdown?.efficiency.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea)), i => i.functionalArea, i => i.value)
  const costByFA = aggregateBy(investment.byUseCase.filter(u => matchesFilterInv(u.functionalArea, u.csg)),                       u => u.functionalArea, u => u.amount)

  // ── 3. Aggregate by CSG (filtered) ───────────────────────────────────────────
  const revByCSG  = aggregateBy((kpiBreakdown?.revenue.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea)),   i => useCaseToCsg[i.label], i => i.dollarValue ?? i.value * 20)
  const npsByCSG  = aggregateBy((kpiBreakdown?.nps.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea)),        i => useCaseToCsg[i.label], i => i.value)
  const effByCSG  = aggregateBy((kpiBreakdown?.efficiency.byUseCase ?? []).filter(i => matchesFilter(i.label, i.functionalArea)), i => useCaseToCsg[i.label], i => i.value)
  const costByCSG = aggregateBy(investment.byUseCase.filter(u => matchesFilterInv(u.functionalArea, u.csg)),                       u => u.csg ?? null,         u => u.amount)

  // ── 4. Top 25 use cases per KPI (filtered) ───────────────────────────────────
  const top25Revenue = [...(kpiBreakdown?.revenue.byUseCase ?? [])]
    .filter(i => matchesFilter(i.label, i.functionalArea))
    .sort((a, b) => (b.dollarValue ?? b.value * 20) - (a.dollarValue ?? a.value * 20))
    .slice(0, TOP_UC)
    .map((r, i) => ({
      '#':         String(i + 1).padStart(2, '0'),
      'Use Case':  trunc(r.label),
      'Area':      r.functionalArea ?? '—',
      'Actual $M': +(r.dollarValue ?? r.value * 20).toFixed(1),
      'Plan $M':   r.plan != null ? +(r.plan * 20).toFixed(1) : null,
    }))

  const top25NPS = [...(kpiBreakdown?.nps.byUseCase ?? [])]
    .filter(i => matchesFilter(i.label, i.functionalArea))
    .sort((a, b) => b.value - a.value)
    .slice(0, TOP_UC)
    .map((r, i) => ({
      '#':            String(i + 1).padStart(2, '0'),
      'Use Case':     trunc(r.label),
      'Area':         r.functionalArea ?? '—',
      'Actual (pts)': +r.value.toFixed(2),
      'Plan (pts)':   r.plan != null ? +r.plan.toFixed(2) : null,
    }))

  const top25Eff = [...(kpiBreakdown?.efficiency.byUseCase ?? [])]
    .filter(i => matchesFilter(i.label, i.functionalArea))
    .sort((a, b) => b.value - a.value)
    .slice(0, TOP_UC)
    .map((r, i) => ({
      '#':          String(i + 1).padStart(2, '0'),
      'Use Case':   trunc(r.label),
      'Area':       r.functionalArea ?? '—',
      'Actual (%)': +r.value.toFixed(1),
      'Plan (%)':   r.plan != null ? +r.plan.toFixed(1) : null,
    }))

  const top25Cost = [...investment.byUseCase]
    .filter(u => matchesFilterInv(u.functionalArea, u.csg))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, TOP_UC)
    .map((u, i) => ({
      '#':         String(i + 1).padStart(2, '0'),
      'Use Case':  trunc(u.name),
      'Area':      u.functionalArea ?? '—',
      'Actual $M': +u.amount.toFixed(1),
      'Plan $M':   u.plan != null ? +u.plan.toFixed(1) : null,
    }))

  // ── Build panel arrays ────────────────────────────────────────────────────────
  function makePanels(dimKey: string, rev: typeof revByFA, nps: typeof npsByFA, eff: typeof effByFA, cost: typeof costByFA) {
    return [
      mkPanel('Revenue Growth',  'revenue',    dimKey, rev,  '$M',  '#16A34A', sumTotal(rev,  'dollar')),
      mkPanel('NPS Improvement', 'nps',        dimKey, nps,  'pts', '#2563EB', sumTotal(nps,  'pts')),
      mkPanel('Efficiency Gain', 'efficiency', dimKey, eff,  '%',   '#D97706', sumTotal(eff,  'pct')),
      mkPanel('AI Cost',         'ai-cost',    dimKey, cost, '$M',  '#7C3AED', sumTotal(cost, 'dollar')),
    ]
  }

  // ── Assemble widgets ──────────────────────────────────────────────────────────
  const widgets = [
    {
      title:       `AI Ambitions KPIs — ${period}${titleTag}`,
      chart_type:  'table',
      data:        kpiTableData,
      x_axis:      'KPI',
      y_axis:      [],
      ...(filterSubsection ? { subsection: filterSubsection } : {}),
    },
    {
      title:      `Top 10 Functional Area — KPIs — ${period}${titleTag}`,
      chart_type: 'multi_panel',
      data:       [],
      panels:     makePanels('Area', revByFA, npsByFA, effByFA, costByFA),
    },
    {
      title:      `Top 10 CSG — KPIs — ${period}${titleTag}`,
      chart_type: 'multi_panel',
      data:       [],
      panels:     makePanels('CSG',
        revByCSG.map(r  => ({ ...r,  name: r.name.split(/\s+/)[0] })),
        npsByCSG.map(r  => ({ ...r,  name: r.name.split(/\s+/)[0] })),
        effByCSG.map(r  => ({ ...r,  name: r.name.split(/\s+/)[0] })),
        costByCSG.map(r => ({ ...r,  name: r.name.split(/\s+/)[0] })),
      ),
    },
    {
      title:       `Top ${TOP_UC} Use Cases — Revenue Growth — ${period}${titleTag}`,
      chart_type:  'table',
      data:        top25Revenue,
      x_axis:      '#',
      y_axis:      [],
      max_rows:    TOP_UC,
      actual_col:  'Actual $M',
      plan_col:    'Plan $M',
    },
    {
      title:       `Top ${TOP_UC} Use Cases — NPS Improvement — ${period}${titleTag}`,
      chart_type:  'table',
      data:        top25NPS,
      x_axis:      '#',
      y_axis:      [],
      max_rows:    TOP_UC,
      actual_col:  'Actual (pts)',
      plan_col:    'Plan (pts)',
    },
    {
      title:       `Top ${TOP_UC} Use Cases — Efficiency Gain — ${period}${titleTag}`,
      chart_type:  'table',
      data:        top25Eff,
      x_axis:      '#',
      y_axis:      [],
      max_rows:    TOP_UC,
      actual_col:  'Actual (%)',
      plan_col:    'Plan (%)',
    },
    {
      title:               `Top ${TOP_UC} Use Cases — AI Cost — ${period}${titleTag}`,
      chart_type:          'table',
      data:                top25Cost,
      x_axis:              '#',
      y_axis:              [],
      max_rows:            TOP_UC,
      actual_col:          'Actual $M',
      plan_col:            'Plan $M',
      invert_actual_color: true,
    },
  ]

  const resp = await client.post(
    '/pdf/export',
    { tab_name: `Overview — ${period}`, title: 'AI Ambitions', widgets },
    { responseType: 'blob' }
  )

  const url = URL.createObjectURL(new Blob([resp.data], { type: 'application/pdf' }))
  const a   = document.createElement('a')
  a.href     = url
  a.download = `AI_Ambitions_${period}_report.pdf`
  a.click()
  URL.revokeObjectURL(url)
}
