import client from './client'
import type { TileVal, DrillData, KpiDrillData } from './overview'

// ── Overview-specific PDF export ──────────────────────────────────────────────

const TOP_N = 10

export async function exportOverviewPDF(
  period: string,
  kpis: TileVal[],
  investment: DrillData,
  drillView: 'category' | 'vendor',
  selectedKpi: string,
  kpiBreakdown: { revenue: KpiDrillData; nps: KpiDrillData; efficiency: KpiDrillData } | undefined,
): Promise<void> {
  const kpiLabels = ['Revenue Growth', 'NPS Improvement', 'Efficiency Gain', 'AI Cost']

  const kpiTableData = kpis.map((k, i) => ({
    KPI:    kpiLabels[i] ?? `KPI ${i + 1}`,
    Value:  k.value,
    Delta:  k.delta,
    Period: period,
    Status: k.statusLabel,
  }))

  // ── Bottom-right drill widget (category or vendor) ─────────────────────────
  const drillItems =
    drillView === 'category'
      ? (() => {
          if (selectedKpi === 'ai-cost') {
            return investment.byCategory.slice(0, TOP_N).map(r => ({ Category: r.label, 'Actual $M': r.amount, 'Plan $M': r.plan ?? '' }))
          }
          const rows = (kpiBreakdown?.[selectedKpi as 'revenue' | 'nps' | 'efficiency']?.byCategory ?? []).slice(0, TOP_N)
          const unit = selectedKpi === 'nps' ? 'pts' : '%'
          return rows.map(r => ({ Category: r.label, [`Actual ${unit}`]: r.value, [`Plan ${unit}`]: r.plan ?? '' }))
        })()
      : (() => {
          if (selectedKpi === 'ai-cost') {
            return investment.byVendor.slice(0, TOP_N).map(r => ({ Vendor: r.label, 'Actual $M': r.amount, 'Plan $M': r.plan ?? '' }))
          }
          const rows = (kpiBreakdown?.[selectedKpi as 'revenue' | 'nps' | 'efficiency']?.byVendor ?? []).slice(0, TOP_N)
          const unit = selectedKpi === 'nps' ? 'pts' : '%'
          return rows.map(r => ({ Vendor: r.label, [`Actual ${unit}`]: r.value, [`Plan ${unit}`]: r.plan ?? '' }))
        })()

  const kpiLabelMap: Record<string, string> = {
    'ai-cost':   'AI Cost',
    'revenue':   'Revenue Growth',
    'nps':       'NPS Improvement',
    'efficiency':'Efficiency Gain',
  }
  const drillDimension = drillView === 'category' ? 'Category' : 'Vendor'
  const drillHeading   = `Top ${Math.min(TOP_N, drillItems.length)} ${drillDimension}s — ${kpiLabelMap[selectedKpi] ?? selectedKpi}`

  // ── Bottom-left use-case widget (top 10 by value) ─────────────────────────
  let useCaseRows: object[]
  let useCaseTitle: string

  if (selectedKpi === 'ai-cost') {
    useCaseRows = investment.byUseCase.slice(0, TOP_N).map((r, i) => ({
      '#':         String(i + 1).padStart(2, '0'),
      'Use Case':  r.name,
      'KPI':       r.kpi,
      'Actual $M': r.amount,
      ...(r.plan != null ? { 'Plan $M': r.plan } : {}),
    }))
    useCaseTitle = `Top ${Math.min(TOP_N, investment.byUseCase.length)} Use Cases by Spend — ${period}`
  } else {
    const kpiKey  = selectedKpi as 'revenue' | 'nps' | 'efficiency'
    const items   = (kpiBreakdown?.[kpiKey]?.byUseCase ?? []).slice(0, TOP_N)
    const unit    = selectedKpi === 'nps' ? 'pts' : '%'
    const label   = kpiLabelMap[selectedKpi]
    useCaseRows = items.map((r, i) => ({
      '#':                String(i + 1).padStart(2, '0'),
      'Use Case':         r.label,
      [`Actual ${unit}`]: r.value,
      ...(r.plan != null ? { [`Plan ${unit}`]: r.plan } : {}),
    }))
    useCaseTitle = `Top ${Math.min(TOP_N, items.length)} Use Cases by ${label} — ${period}`
  }

  const widgets = [
    {
      title:      `AI Ambition KPIs — ${period}`,
      chart_type: 'table',
      data:       kpiTableData,
      x_axis:     'KPI',
      y_axis:     [],
      stacked:    false,
      dual_axis:  false,
    },
    {
      title:      `${drillHeading} — ${period}`,
      chart_type: 'horizontal_bar',
      data:       drillItems,
      x_axis:     Object.keys(drillItems[0] ?? {})[0],
      y_axis:     [Object.keys(drillItems[0] ?? {})[1] ?? ''],
      stacked:    false,
      dual_axis:  false,
    },
    {
      title:      useCaseTitle,
      chart_type: 'table',
      data:       useCaseRows,
      x_axis:     '#',
      y_axis:     [],
      stacked:    false,
      dual_axis:  false,
    },
  ]

  const resp = await client.post(
    '/pdf/export',
    { tab_name: `Overview — ${period}`, title: 'AI Ambitions Dashboard', widgets },
    { responseType: 'blob' }
  )

  const url = URL.createObjectURL(new Blob([resp.data], { type: 'application/pdf' }))
  const a   = document.createElement('a')
  a.href     = url
  a.download = `AI_Ambitions_${period}_report.pdf`
  a.click()
  URL.revokeObjectURL(url)
}
