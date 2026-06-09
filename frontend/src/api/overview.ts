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

export interface BarItem     { label: string; amount: number; plan?: number | null }
export interface UseCaseItem { rank: string; name: string; kpi: string; amount: number; plan?: number | null }
export interface DrillData   { byCategory: BarItem[]; byUseCase: UseCaseItem[]; byVendor: BarItem[] }

export interface OverviewSummary {
  kpis: TileVal[]
  investment: DrillData
}

export async function fetchOverviewSummary(period: string): Promise<OverviewSummary> {
  const { data } = await client.get<OverviewSummary>(`/overview/summary?period=${period}`)
  return data
}
