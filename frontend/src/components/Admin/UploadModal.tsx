import { useState } from 'react'
import axios from 'axios'
import { X, UploadCloud, Loader2, CheckCircle2, AlertCircle, Download } from 'lucide-react'
import { uploadFile } from '../../api/admin'

interface Props {
  onClose: () => void
}

export function UploadModal({ onClose }: Props) {
  const [file, setFile] = useState<File | null>(null)
  const [status, setStatus] = useState<'idle' | 'uploading' | 'success' | 'error'>('idle')
  const [error, setError] = useState('')
  const [gcsPath, setGcsPath] = useState('')

  async function handleUpload() {
    if (!file) return
    setStatus('uploading')
    setError('')
    try {
      const result = await uploadFile(file)
      setGcsPath(result.gcs_path)
      setStatus('success')
    } catch (err) {
      const detail = axios.isAxiosError(err) ? err.response?.data?.detail : undefined
      setError(detail || 'Upload failed.')
      setStatus('error')
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4" onClick={onClose}>
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 relative" onClick={(e) => e.stopPropagation()}>
        <button onClick={onClose} className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition">
          <X size={18} />
        </button>

        <h2 className="text-lg font-semibold text-gray-900 mb-1">Upload to GCS</h2>
        <p className="text-sm text-gray-500 mb-1">Admin-only. Files upload directly to the configured bucket.</p>
        <a
          href="/use-case-upload-template.xlsx"
          download
          className="inline-flex items-center gap-1.5 text-xs font-medium text-red-600 hover:text-red-700 mb-4 transition"
        >
          <Download size={12} />
          Download file template
        </a>

        {status === 'success' ? (
          <div className="flex flex-col items-center text-center py-2">
            <div className="h-12 w-12 rounded-full bg-emerald-50 border border-emerald-200 flex items-center justify-center mb-3">
              <CheckCircle2 size={22} className="text-emerald-500" />
            </div>
            <p className="text-sm font-medium text-gray-900 mb-1">Upload complete</p>
            <p className="text-xs text-gray-500 break-all">{gcsPath}</p>
            <button
              onClick={onClose}
              className="mt-5 w-full rounded-lg bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm font-medium py-2 transition"
            >
              Close
            </button>
          </div>
        ) : (
          <>
            <label className="flex flex-col items-center justify-center gap-2 border-2 border-dashed border-gray-200 rounded-xl py-8 cursor-pointer hover:border-red-300 hover:bg-red-50/40 transition">
              <UploadCloud size={22} className="text-gray-400" />
              <span className="text-sm text-gray-600 px-4 text-center truncate max-w-full">{file ? file.name : 'Choose a file'}</span>
              <input
                type="file"
                className="hidden"
                onChange={(e) => setFile(e.target.files?.[0] ?? null)}
                disabled={status === 'uploading'}
              />
            </label>

            {status === 'error' && (
              <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2 mt-4">
                <AlertCircle size={15} className="shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <button
              onClick={handleUpload}
              disabled={!file || status === 'uploading'}
              className="w-full flex items-center justify-center gap-2 rounded-lg bg-red-600 hover:bg-red-500 disabled:bg-red-300 text-white text-sm font-semibold py-2.5 transition mt-4"
            >
              {status === 'uploading' ? <Loader2 size={16} className="animate-spin" /> : null}
              {status === 'uploading' ? 'Uploading…' : 'Upload'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}
