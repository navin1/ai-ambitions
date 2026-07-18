import { useEffect, useState } from 'react'
import { CheckCircle2, Loader2 } from 'lucide-react'
import { logout } from '../api/auth'
import { BrandPanel } from './BrandPanel'

interface Props {
  onReturnToLogin: () => void
}

export function LogoutPage({ onReturnToLogin }: Props) {
  const [done, setDone] = useState(false)

  useEffect(() => {
    logout().finally(() => setDone(true))
  }, [])

  return (
    <div className="min-h-screen w-full flex bg-white dark:bg-gray-800">
      <BrandPanel />

      <div className="flex-1 flex items-center justify-center px-4 relative overflow-hidden">
        <div
          className="pointer-events-none absolute inset-0 opacity-[0.35]"
          style={{ backgroundImage: 'radial-gradient(#e5e7eb 1px, transparent 1px)', backgroundSize: '22px 22px' }}
        />

        <div className="relative w-full max-w-sm">
          <div className="flex flex-col items-center mb-8 lg:hidden">
            <img src="/logo.png" alt="Logo" className="h-12 w-auto mb-4" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }} />
            <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 tracking-tight">AI Ambitions</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">AI Investment Tracker</p>
          </div>

          <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl shadow-xl shadow-gray-200/60 p-8 flex flex-col items-center text-center">
            {done ? (
              <>
                <div className="h-12 w-12 rounded-full bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 flex items-center justify-center mb-4">
                  <CheckCircle2 size={24} className="text-emerald-500 dark:text-emerald-400" />
                </div>
                <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-1">You've been signed out</h2>
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">Your session has ended. Sign in again to access the dashboard.</p>
                <button
                  onClick={onReturnToLogin}
                  className="w-full rounded-lg bg-red-600 hover:bg-red-500 text-white text-sm font-semibold py-2.5 transition shadow-lg shadow-red-600/20"
                >
                  Back to sign in
                </button>
              </>
            ) : (
              <>
                <Loader2 size={24} className="text-gray-400 dark:text-gray-500 animate-spin mb-4" />
                <p className="text-sm text-gray-500 dark:text-gray-400">Signing you out…</p>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
