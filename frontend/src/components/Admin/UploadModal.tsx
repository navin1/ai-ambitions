import { useState } from 'react'
import axios from 'axios'
import { X, UploadCloud, Loader2, CheckCircle2, AlertCircle, AlertTriangle, Download } from 'lucide-react'
import { uploadFile, ImportResult } from '../../api/admin'
import { DataTable } from '../DataTable/DataTable'

interface Props {
  onClose: () => void
}

// Mirrors excel_ingest.FILENAME_PATTERN on the backend — client-side check is
// just for instant feedback; the backend is the source of truth.
const FILENAME_PATTERN = /^AI_Ambitions_FY\d{2}_(YTD|Q[1-4])_\d{8}\.xlsx$/
const FILENAME_HINT = 'AI_Ambitions_FY<YY>_<Period>_<YYYYMMDD>.xlsx (e.g. AI_Ambitions_FY26_YTD_20260822.xlsx)'

export function UploadModal({ onClose }: Props) {
  const [file, setFile] = useState<File | null>(null)
  const [status, setStatus] = useState<'idle' | 'uploading' | 'processing' | 'success' | 'error'>('idle')
  const [requestError, setRequestError] = useState('')
  const [result, setResult] = useState<ImportResult | null>(null)

  const filenameError = file && !FILENAME_PATTERN.test(file.name) ? `File name must match ${FILENAME_HINT}` : null
  const isBusy = status === 'uploading' || status === 'processing'

  async function handleUpload() {
    if (!file || filenameError) return
    setStatus('uploading')
    setRequestError('')
    setResult(null)
    try {
      const res = await uploadFile(file, (percent) => {
        if (percent >= 100) setStatus('processing')
      })
      setResult(res)
      setStatus(res.success ? 'success' : 'error')
    } catch (err) {
      const detail = axios.isAxiosError(err) ? err.response?.data?.detail : undefined
      setRequestError(detail || 'Upload failed.')
      setStatus('error')
    }
  }

  function handleFileChange(newFile: File | null) {
    setFile(newFile)
    // Picking a file after a failed attempt starts a fresh attempt — clears
    // the disabled/error state so Upload becomes clickable again.
    setStatus('idle')
    setResult(null)
    setRequestError('')
  }

  const hasRowErrors = status === 'error' && (result?.errors.length ?? 0) > 0

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4" onClick={onClose}>
      <div
        className={`bg-white rounded-2xl shadow-2xl w-full p-6 relative transition-all ${hasRowErrors ? 'max-w-2xl' : 'max-w-sm'}`}
        onClick={(e) => e.stopPropagation()}
      >
        <button onClick={onClose} className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition">
          <X size={18} />
        </button>

        <h2 className="text-lg font-semibold text-gray-900 mb-1">Upload data workbook</h2>
        <p className="text-sm text-gray-500 mb-1">
          Admin-only. Validates the workbook, then replaces matching fiscal_year/period rows in BigQuery.
        </p>
        <a
          href="/AI_Ambitions_FY26_YTD_20260822.xlsx"
          download
          className="inline-flex items-center gap-1.5 text-xs font-medium text-red-600 hover:text-red-700 mb-1 transition"
        >
          <Download size={12} />
          Download file template
        </a>
        <p className="text-xs text-gray-400 mb-4">File name must match {FILENAME_HINT}</p>

        {status === 'success' && result ? (
          <div className="flex flex-col items-center text-center py-2">
            <div className="h-12 w-12 rounded-full bg-emerald-50 border border-emerald-200 flex items-center justify-center mb-3">
              <CheckCircle2 size={22} className="text-emerald-500" />
            </div>
            <p className="text-sm font-medium text-gray-900 mb-1">Upload complete</p>
            <p className="text-xs text-gray-500 mb-2">
              Replaced {result.periods_replaced.map((p) => `FY${p.fiscal_year} ${p.period}`).join(', ')} —{' '}
              {result.kpi_rows_loaded} KPI rows, {result.use_case_rows_loaded} use-case rows
            </p>
            <p className="text-xs text-gray-400 break-all">{result.gcs_path}</p>
            {result.warning && (
              <div className="flex items-start gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2 mt-3 text-left">
                <AlertTriangle size={14} className="shrink-0 mt-0.5" />
                <span>{result.warning}</span>
              </div>
            )}
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
                onChange={(e) => handleFileChange(e.target.files?.[0] ?? null)}
                disabled={isBusy}
              />
            </label>

            {filenameError && (
              <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2 mt-4">
                <AlertCircle size={15} className="shrink-0" />
                <span>{filenameError}</span>
              </div>
            )}

            {!filenameError && status === 'error' && !hasRowErrors && (
              <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2 mt-4">
                <AlertCircle size={15} className="shrink-0" />
                <span>{requestError}</span>
              </div>
            )}

            {hasRowErrors && result && (
              <div className="mt-4">
                <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2 mb-2">
                  <AlertCircle size={15} className="shrink-0" />
                  <span>
                    Validation failed — {result.errors.length} issue{result.errors.length === 1 ? '' : 's'} found.
                    Nothing was loaded to BigQuery.
                  </span>
                </div>
                <DataTable data={result.errors as unknown as Record<string, unknown>[]} maxRows={200} />
              </div>
            )}

            <button
              onClick={handleUpload}
              disabled={!file || !!filenameError || isBusy || status === 'error'}
              className={`w-full flex items-center justify-center gap-2 rounded-lg text-white text-sm font-semibold py-2.5 transition mt-4 ${
                status === 'processing'
                  ? 'bg-blue-600 disabled:bg-blue-400'
                  : status === 'error'
                    ? 'bg-gray-300 disabled:bg-gray-300'
                    : 'bg-red-600 hover:bg-red-500 disabled:bg-red-300'
              }`}
            >
              {isBusy ? <Loader2 size={16} className="animate-spin" /> : null}
              {status === 'uploading' ? 'Uploading…' : status === 'processing' ? 'Processing…' : 'Upload'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}
