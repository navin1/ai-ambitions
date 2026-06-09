export interface Widget {
  id: string
  title: string
  chart_type: ChartType
  x_axis?: string
  y_axis: string[]
  color_field?: string
  stacked: boolean
  dual_axis: boolean
  secondary_y?: string
  ai_description: string
  sql: string
  data: Record<string, unknown>[]
  error?: string
}

export type ChartType =
  | 'bar'
  | 'stacked_bar'
  | 'line'
  | 'combo'
  | 'donut'
  | 'pie'
  | 'table'
  | 'kpi'
  | 'horizontal_bar'

export interface QueryResponse {
  sql: string
  chart_type: ChartType
  title: string
  x_axis?: string
  y_axis: string[]
  color_field?: string
  stacked: boolean
  dual_axis: boolean
  secondary_y?: string
  ai_description: string
  data: Record<string, unknown>[]
  error?: string
}
