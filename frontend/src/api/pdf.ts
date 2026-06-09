import client from './client'
import type { TileVal, DrillData } from './overview'

// ── Overview-specific PDF export ──────────────────────────────────────────────
// Builds widget objects from the current dashboard state and sends them to
// the existing /api/pdf/export endpoint, preserving the current report template.

export async function exportOverviewPDF(
  period: string,
  kpis: TileVal[],
  investment: DrillData,
  drillView: 'category' | 'use-case' | 'vendor'
): Promise<void> {
  const kpiLabels = ['Revenue Growth', 'NPS Improvement', 'Efficiency Gain', 'AI Cost']

  const kpiTableData = kpis.map((k, i) => ({
    KPI:    kpiLabels[i] ?? `KPI ${i + 1}`,
    Value:  k.value,
    Delta:  k.delta,
    Period: period,
    Status: k.statusLabel,
  }))

  const drillItems =
    drillView === 'category' ? investment.byCategory.map(r => ({ Category: r.label, 'Actual $M': r.amount, 'Plan $M': r.plan ?? '' })) :
    drillView === 'vendor'   ? investment.byVendor.map(r  => ({ Vendor: r.label,    'Actual $M': r.amount, 'Plan $M': r.plan ?? '' })) :
    investment.byUseCase.map(r => ({ Rank: r.rank, 'Use Case': r.name, KPI: r.kpi, 'Actual $M': r.amount, 'Plan $M': r.plan ?? '' }))

  const drillHeading =
    drillView === 'category' ? 'Spend by Category' :
    drillView === 'vendor'   ? 'Spend by Vendor'   :
    'Spend by Use Case'

  const widgets = [
    {
      title: `AI Ambition KPIs — ${period}`,
      chart_type: 'table',
      ai_description: '',
      data: kpiTableData,
      x_axis: 'KPI',
      y_axis: [],
      stacked: false,
      dual_axis: false,
    },
    {
      title: `${drillHeading} — ${period}`,
      chart_type: 'horizontal_bar',
      ai_description: '',
      data: drillItems,
      x_axis: Object.keys(drillItems[0] ?? {})[0],
      y_axis: ['Actual $M'],
      stacked: false,
      dual_axis: false,
    },
    {
      title: `Top Use Cases by Spend — ${period}`,
      chart_type: 'table',
      ai_description: '',
      data: investment.byUseCase.map(r => ({
        Rank: r.rank,
        'Use Case': r.name,
        KPI: r.kpi,
        'Actual $M': r.amount,
        ...(r.plan != null ? { 'Plan $M': r.plan } : {}),
      })),
      x_axis: 'Rank',
      y_axis: [],
      stacked: false,
      dual_axis: false,
    },
  ]

  const resp = await client.post(
    '/pdf/export',
    { tab_name: `AI Ambitions — ${period}`, title: 'AI Ambitions Dashboard', widgets },
    { responseType: 'blob' }
  )

  const url = URL.createObjectURL(new Blob([resp.data], { type: 'application/pdf' }))
  const a   = document.createElement('a')
  a.href     = url
  a.download = `AI_Ambitions_${period}_report.pdf`
  a.click()
  URL.revokeObjectURL(url)
}
