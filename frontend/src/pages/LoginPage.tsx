import { useState, FormEvent } from 'react'
import { Eye, EyeOff, Lock, User, AlertCircle, Loader2 } from 'lucide-react'
import { login } from '../api/auth'
import { BrandPanel } from './BrandPanel'

interface Props {
  onSuccess: () => void
}

export function LoginPage({ onSuccess }: Props) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!username.trim() || !password) {
      setError('Enter your username and password.')
      return
    }
    setError('')
    setLoading(true)
    try {
      await login(username.trim(), password)
      onSuccess()
    } catch {
      setError('Invalid username or password.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen w-full flex bg-white dark:bg-gray-800">
      <BrandPanel />

      <div className="flex-1 flex items-center justify-center px-4 relative overflow-hidden">
        <div
          className="pointer-events-none absolute inset-0 opacity-[0.35]"
          style={{ backgroundImage: 'radial-gradient(var(--dot-pattern-color) 1px, transparent 1px)', backgroundSize: '22px 22px' }}
        />

        <div className="relative w-full max-w-sm">
          <div className="flex flex-col items-center mb-8 lg:hidden">
            <img src="/logo.png" alt="Logo" className="h-12 w-auto mb-4" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }} />
            <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 tracking-tight">AI Ambitions</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">AI Investment Tracker</p>
          </div>

          <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl shadow-xl shadow-gray-200/60 p-8">
            <img src="/logo.png" alt="Logo" className="hidden lg:block h-7 w-auto mb-5" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }} />
            <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-1">Sign in</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">Use your Macy's credentials to continue.</p>

            <form onSubmit={handleSubmit} className="space-y-4" noValidate>
              <div>
                <label htmlFor="username" className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1.5">Username</label>
                <div className="relative">
                  <User size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500" />
                  <input
                    id="username"
                    type="text"
                    autoComplete="username"
                    autoFocus
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="w-full rounded-lg bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 pl-9 pr-3 py-2.5 text-sm text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-red-500/40 focus:border-red-400 focus:bg-white dark:focus:bg-gray-900 transition"
                    placeholder="jane.doe"
                    disabled={loading}
                  />
                </div>
              </div>

              <div>
                <label htmlFor="password" className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1.5">Password</label>
                <div className="relative">
                  <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500" />
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full rounded-lg bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 pl-9 pr-9 py-2.5 text-sm text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-red-500/40 focus:border-red-400 focus:bg-white dark:focus:bg-gray-900 transition"
                    placeholder="••••••••"
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-400 transition"
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              {error && (
                <div className="flex items-center gap-2 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 rounded-lg px-3 py-2">
                  <AlertCircle size={15} className="shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 rounded-lg bg-red-600 hover:bg-red-500 disabled:bg-red-600/50 text-white text-sm font-semibold py-2.5 transition shadow-lg shadow-red-600/20"
              >
                {loading ? <Loader2 size={16} className="animate-spin" /> : null}
                {loading ? 'Signing in…' : 'Sign in'}
              </button>
            </form>
          </div>

          <p className="text-center text-xs text-gray-400 dark:text-gray-500 mt-6">
            Protected by ForgeRock Identity Gateway
          </p>
        </div>
      </div>
    </div>
  )
}
