import client from './client'

export interface TileVal {
  value: string
  delta: string
  deltaLabel: string
  current: number
  status: string
  statusLabel: string
  planCurrent?: number
  planLabel?: string
  planValue?: number
}

export interface BarItem        { label: string; amount: number; plan?: number | null }
export interface UseCaseItem    { rank: string; name: string; kpi: string; amount: number; plan?: number | null; description?: string | null; csg?: string | null; functionalArea?: string | null; currentPhase?: string | null }
export interface DrillData      { byCategory: BarItem[]; byUseCase: UseCaseItem[]; byVendor: BarItem[] }
export interface KpiMetricItem  { label: string; value: number; plan?: number | null; rank?: string | null; currentPhase?: string | null; functionalArea?: string | null; dollarValue?: number | null; dollarPlan?: number | null }
export interface KpiDrillData   { byCategory: KpiMetricItem[]; byUseCase: KpiMetricItem[]; byVendor: KpiMetricItem[] }

export interface OverviewSummary {
  kpis: TileVal[]
  investment: DrillData
  kpiBreakdown: { revenue: KpiDrillData; nps: KpiDrillData; efficiency: KpiDrillData }
}

export async function fetchOverviewSummary(period: string): Promise<OverviewSummary> {
  const { data } = await client.get<OverviewSummary>(`/overview/summary?period=${period}`)
  return data
}
