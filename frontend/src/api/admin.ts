import client from './client'

export interface RowError {
  sheet: string
  row?: number | null
  column?: string | null
  message: string
}

export interface ImportResult {
  filename: string
  gcs_path: string
  success: boolean
  periods_replaced: { fiscal_year: number; period: string }[]
  kpi_rows_loaded: number
  use_case_rows_loaded: number
  errors: RowError[]
  warning?: string | null
}

export async function uploadFile(file: File): Promise<ImportResult> {
  const form = new FormData()
  form.append('file', file)
  const { data } = await client.post<ImportResult>('/admin/upload', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
  return data
}
