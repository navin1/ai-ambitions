import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Header } from './components/Header/Header'
import { OverviewTab } from './tabs/OverviewTab'
import { ChatPanel } from './components/Chat/ChatPanel'
import type { ChatWidgetDef } from './api/chat'

const qc = new QueryClient({ defaultOptions: { queries: { retry: 1 } } })

// Prefetch default period on load so the Overview tab renders instantly
qc.prefetchQuery({
  queryKey: ['overview', 'YTD'],
  queryFn: () => import('./api/overview').then(m => m.fetchOverviewSummary('YTD')),
})

// Flip to 'true' to surface the AI chat panel
const ENABLE_AI = import.meta.env.VITE_ENABLE_AI_FEATURES === 'true'

export default function App() {
  // onAddWidget is a no-op here — the Overview tab doesn't accept injected widgets.
  // It exists so ChatPanel has the same interface it will need when tabs are added.
  function handleChatAddWidget(_widget: ChatWidgetDef) { /* no-op until tab expansion */ }

  return (
    <QueryClientProvider client={qc}>
      <div className="h-screen flex flex-col bg-gray-50 font-sans overflow-hidden">
        <Header title="AI Ambitions" subtitle="FY26 Investment Tracker" />

        <main className="flex-1 min-h-0 overflow-auto pb-14">
          <OverviewTab />
        </main>

        {/* AI Analyst panel — present in the bundle, hidden until flag is enabled */}
        <div className={ENABLE_AI ? undefined : 'hidden'}>
          <ChatPanel onAddWidget={handleChatAddWidget} />
        </div>
      </div>
    </QueryClientProvider>
  )
}
