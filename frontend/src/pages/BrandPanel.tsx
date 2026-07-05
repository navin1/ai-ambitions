import { TrendingUp, Gauge, Sparkles } from 'lucide-react'

const HIGHLIGHTS = [
  { icon: TrendingUp, label: 'Revenue growth by initiative' },
  { icon: Gauge, label: 'NPS & efficiency vs. plan' },
  { icon: Sparkles, label: 'AI investment cost tracking' },
]

export function BrandPanel() {
  return (
    <div className="hidden lg:flex lg:w-[46%] relative overflow-hidden bg-gradient-to-br from-red-600 via-red-700 to-red-900 flex-col justify-center px-14 py-12">
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.12]"
        style={{ backgroundImage: 'radial-gradient(#ffffff 1.5px, transparent 1.5px)', backgroundSize: '26px 26px' }}
      />
      <div className="pointer-events-none absolute -top-28 -right-20 h-80 w-80 rounded-full bg-white/10 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-32 -left-16 h-80 w-80 rounded-full bg-black/20 blur-3xl" />

      <div className="relative">
        <h1 className="text-4xl font-bold text-white tracking-tight leading-tight">AI Ambitions</h1>
        <p className="text-red-100/90 text-sm mt-2 max-w-xs">
          Track AI investment performance across revenue, NPS, and efficiency — in one place.
        </p>

        <div className="mt-10 space-y-4">
          {HIGHLIGHTS.map(({ icon: Icon, label }) => (
            <div key={label} className="flex items-center gap-3">
              <div className="h-8 w-8 rounded-lg bg-white/10 border border-white/15 flex items-center justify-center shrink-0">
                <Icon size={15} className="text-white" />
              </div>
              <span className="text-sm text-red-50/90">{label}</span>
            </div>
          ))}
        </div>
      </div>

      <p className="relative text-xs text-red-100/60 mt-16">Macy's · Enterprise AI performance dashboard</p>
    </div>
  )
}
