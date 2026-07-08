import { useEffect, useState } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Loader2 } from 'lucide-react'
import { Header } from './components/Header/Header'
import { OverviewTab } from './tabs/OverviewTab'
import { ChatPanel } from './components/Chat/ChatPanel'
import { LoginPage } from './pages/LoginPage'
import { LogoutPage } from './pages/LogoutPage'
import { UploadModal } from './components/Admin/UploadModal'
import { fetchMe } from './api/auth'
import type { CurrentUser } from './api/auth'
import type { ChatWidgetDef } from './api/chat'

const qc = new QueryClient({ defaultOptions: { queries: { retry: 1 } } })

// Prefetch default period/year on load so the Overview tab renders instantly.
// Key must match OverviewTab's ['overview', period, selectedYear] shape —
// selectedYear starts undefined until the fiscal-year list loads.
qc.prefetchQuery({
  queryKey: ['overview', 'YTD', undefined],
  queryFn: () => import('./api/overview').then(m => m.fetchOverviewSummary('YTD')),
})

// Flip to 'true' to surface the AI chat panel
const ENABLE_AI = import.meta.env.VITE_ENABLE_AI_FEATURES === 'true'

function navigate(path: string) {
  window.history.pushState(null, '', path)
  window.dispatchEvent(new PopStateEvent('popstate'))
}

function Dashboard({ user, onLogout }: { user: CurrentUser; onLogout: () => void }) {
  const [showUpload, setShowUpload] = useState(false)

  function handleChatAddWidget(_widget: ChatWidgetDef) { /* no-op until tab expansion */ }

  return (
    <div className="h-screen flex flex-col bg-gray-50 font-sans overflow-hidden">
      <Header
        title="AI Ambitions"
        subtitle="AI Investment Tracker"
        userEmail={user.email}
        role={user.role}
        onLogout={onLogout}
        onUploadClick={() => setShowUpload(true)}
      />

      <main className="flex-1 min-h-0 overflow-auto pb-14" style={{ scrollbarGutter: 'stable' }}>
        <OverviewTab />
      </main>

      <div className={ENABLE_AI ? undefined : 'hidden'}>
        <ChatPanel onAddWidget={handleChatAddWidget} />
      </div>

      {showUpload && <UploadModal onClose={() => setShowUpload(false)} />}
    </div>
  )
}

export default function App() {
  const [path, setPath] = useState(window.location.pathname)
  const [checking, setChecking] = useState(true)
  const [user, setUser] = useState<CurrentUser | null>(null)

  useEffect(() => {
    const onPopState = () => setPath(window.location.pathname)
    window.addEventListener('popstate', onPopState)
    return () => window.removeEventListener('popstate', onPopState)
  }, [])

  useEffect(() => {
    fetchMe()
      .then((me) => setUser(me.authenticated ? me : null))
      .catch(() => setUser(null))
      .finally(() => setChecking(false))
  }, [])

  if (path === '/logout') {
    return <LogoutPage onReturnToLogin={() => { setUser(null); navigate('/login') }} />
  }

  if (checking) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-gray-50">
        <Loader2 size={22} className="text-gray-400 animate-spin" />
      </div>
    )
  }

  if (!user) {
    return (
      <LoginPage
        onSuccess={async () => {
          const me = await fetchMe()
          setUser(me)
          navigate('/')
        }}
      />
    )
  }

  if (path === '/login') navigate('/')

  return (
    <QueryClientProvider client={qc}>
      <Dashboard user={user} onLogout={() => navigate('/logout')} />
    </QueryClientProvider>
  )
}
