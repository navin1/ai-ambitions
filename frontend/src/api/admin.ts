import client from './client'

export interface UploadResult {
  filename: string
  gcs_path: string
  size_bytes: number
}

export async function uploadFile(file: File): Promise<UploadResult> {
  const form = new FormData()
  form.append('file', file)
  const { data } = await client.post<UploadResult>('/admin/upload', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
  return data
}
