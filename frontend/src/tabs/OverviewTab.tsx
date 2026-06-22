import { useState, useEffect, useRef } from 'react'
import { Download, X, ChevronDown } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import clsx from 'clsx'
import { fetchOverviewSummary, type TileVal, type DrillData, type KpiDrillData } from '../api/overview'
import { exportOverviewPDF } from '../api/pdf'

// ── Types ─────────────────────────────────────────────────────────────────────

type Status = 'in-band' | 'below-target' | 'above-target' | 'under-plan' | 'over-plan'
type Period  = 'YTD' | 'Q1' | 'Q2' | 'Q3' | 'Q4'

interface FaContrib { pct: number; rawValue: string; dollarStr?: string }

interface TileMeta {
  id: string; label: string
  rangeMin: number; rangeMax: number
  targetMin: number; targetMax: number
  rangeUnit: string; targetLabel: string
  isSpendTile?: boolean
}

// ── Static tile metadata ──────────────────────────────────────────────────────

const TILE_META: TileMeta[] = [
  { id: 'ai-cost',    label: 'AI Cost',         rangeMin: 0, rangeMax: 100, targetMin: 0,  targetMax: 45, rangeUnit: 'M', targetLabel: '',                isSpendTile: true },
  { id: 'revenue',    label: 'Revenue Growth',  rangeMin: 0, rangeMax: 10,  targetMin: 3,  targetMax: 7,  rangeUnit: '%', targetLabel: 'target band 3–7%'  },
  { id: 'nps',        label: 'NPS Improvement', rangeMin: 0, rangeMax: 6,   targetMin: 2,  targetMax: 4,  rangeUnit: '',  targetLabel: 'target band 2–4'   },
  { id: 'efficiency', label: 'Efficiency Gain', rangeMin: 0, rangeMax: 50,  targetMin: 30, targetMax: 40, rangeUnit: '%', targetLabel: 'target band 30–40%' },
]

// ── Design tokens ─────────────────────────────────────────────────────────────

const STATUS: Record<Status, {
  strip: string; dot: string
  badgeText: string; badgeBg: string; badgeBorder: string
  ring: string; ringOffset: string
}> = {
  'in-band':      { strip: 'bg-emerald-400', dot: 'bg-emerald-400', badgeText: 'text-emerald-700', badgeBg: 'bg-emerald-50',  badgeBorder: 'border-emerald-200', ring: 'ring-emerald-400', ringOffset: 'ring-offset-emerald-400' },
  'below-target': { strip: 'bg-amber-400',   dot: 'bg-amber-400',   badgeText: 'text-amber-700',   badgeBg: 'bg-amber-50',    badgeBorder: 'border-amber-200',   ring: 'ring-amber-400',   ringOffset: 'ring-offset-amber-400'   },
  'above-target': { strip: 'bg-emerald-400', dot: 'bg-emerald-400', badgeText: 'text-emerald-700', badgeBg: 'bg-emerald-50',  badgeBorder: 'border-emerald-200', ring: 'ring-emerald-400', ringOffset: 'ring-offset-emerald-400' },
  'under-plan':   { strip: 'bg-emerald-400', dot: 'bg-emerald-400', badgeText: 'text-emerald-700', badgeBg: 'bg-emerald-50',  badgeBorder: 'border-emerald-200', ring: 'ring-emerald-400', ringOffset: 'ring-offset-emerald-400' },
  'over-plan':    { strip: 'bg-rose-400',    dot: 'bg-rose-400',    badgeText: 'text-rose-700',    badgeBg: 'bg-rose-50',     badgeBorder: 'border-rose-200',    ring: 'ring-rose-400',    ringOffset: 'ring-offset-rose-400'    },
}

const KPI_TAG: Record<string, string> = {
  REVENUE:    'bg-blue-50   text-blue-700   ring-1 ring-inset ring-blue-600/20',
  EFFICIENCY: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20',
  NPS:        'bg-purple-50 text-purple-700  ring-1 ring-inset ring-purple-600/20',
}

const PHASE_STYLE: Record<string, string> = {
  'Planning':   'bg-gray-100 text-gray-500',
  'Pilot':      'bg-blue-50 text-blue-700',
  'Scaling':    'bg-amber-50 text-amber-700',
  'Production': 'bg-emerald-50 text-emerald-700',
}

const CSG_STYLE: Record<string, string> = {
  'Consumer':  'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20',
  'Business':  'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20',
  'Corporate': 'bg-slate-100 text-slate-600 ring-1 ring-inset ring-slate-400/30',
}
function csgStyle(csg: string) { return CSG_STYLE[csg] ?? 'bg-gray-100 text-gray-600 ring-1 ring-inset ring-gray-400/30' }

function asPct(val: number, min: number, max: number) {
  return `${Math.max(0, Math.min(100, ((val - min) / (max - min)) * 100)).toFixed(2)}%`
}
function kpiTag(kpi: string)                       { return KPI_TAG[kpi] ?? 'bg-gray-100 text-gray-600' }
function phaseStyle(p: string | null | undefined)  { return PHASE_STYLE[p ?? ''] ?? 'bg-gray-100 text-gray-500' }

// ── Range bar ─────────────────────────────────────────────────────────────────

function RangeBar({ meta, val, vsPlan }: { meta: TileMeta; val: TileVal; vsPlan: boolean }) {
  const { rangeMin, rangeMax, targetMin, targetMax, rangeUnit, targetLabel, isSpendTile } = meta
  const { current, planValue, planCurrent } = val

  if (isSpendTile) {
    const budget = planValue ?? 45
    const fillW  = asPct(current, rangeMin, rangeMax)
    const planL  = asPct(budget, rangeMin, rangeMax)
    return (
      <div className="mt-5">
        <div className="relative h-2 bg-gray-100 rounded-full w-full">
          <div className="absolute inset-y-0 left-0 bg-gray-800 rounded-full transition-all duration-700" style={{ width: fillW }} />
          <div className="absolute top-1/2 -translate-y-1/2 w-px h-5 bg-amber-400" style={{ left: planL }} />
        </div>
        <div className="relative flex justify-between mt-2">
          <span className="text-[13px] text-gray-400">$0M</span>
          <span className="absolute text-[13px] font-semibold text-amber-600 -translate-x-1/2 whitespace-nowrap" style={{ left: planL }}>
            plan ${budget}M
          </span>
          <span className="text-[13px] text-gray-400">${rangeMax}M</span>
        </div>
      </div>
    )
  }

  const targetL  = asPct(targetMin, rangeMin, rangeMax)
  const targetW  = `${((targetMax - targetMin) / (rangeMax - rangeMin)) * 100}%`
  const currentL = asPct(current, rangeMin, rangeMax)
  const planL    = planCurrent !== undefined ? asPct(planCurrent, rangeMin, rangeMax) : null

  return (
    <div className="mt-5">
      <div className="relative h-2 bg-gray-100 rounded-full w-full">
        <div className="absolute inset-y-0 bg-gray-300 rounded-full" style={{ left: targetL, width: targetW }} />
        {vsPlan && planL && (
          <div className="absolute top-1/2 w-3.5 h-3.5 bg-sky-400 rounded-full border-2 border-white shadow ring-1 ring-sky-200"
            style={{ left: planL, transform: 'translate(-50%, -50%)' }} />
        )}
        <div className="absolute top-1/2 w-4 h-4 bg-gray-900 rounded-full border-2 border-white shadow-md"
          style={{ left: currentL, transform: 'translate(-50%, -50%)' }} />
      </div>
      <div className="flex justify-between mt-2">
        <span className="text-[13px] text-gray-400">{rangeMin}{rangeUnit}</span>
        <span className="text-[13px] font-medium text-gray-500">{targetLabel}</span>
        <span className="text-[13px] text-gray-400">{rangeMax}{rangeUnit}</span>
      </div>
    </div>
  )
}

// ── KPI card ──────────────────────────────────────────────────────────────────

function KpiCard({ meta, val, period, vsPlan, isSelected, onClick, faContrib, selectedFA }: {
  meta: TileMeta; val: TileVal; period: Period; vsPlan: boolean
  isSelected: boolean; onClick: () => void
  faContrib?: FaContrib | null; selectedFA?: string | null
}) {
  const t = STATUS[val.status as Status] ?? STATUS['in-band']
  return (
    <div
      onClick={onClick}
      className={clsx(
        'relative flex flex-col rounded-2xl overflow-hidden bg-white shadow-sm transition-all duration-200 cursor-pointer hover:shadow-lg',
        isSelected ? clsx('ring-2 ring-offset-2', t.ring, t.ringOffset) : 'ring-1 ring-gray-100',
      )}
    >
      <div className={clsx('absolute left-0 top-0 bottom-0 w-1', t.strip)} />
      <div className="pl-6 pr-5 pt-5 pb-5 flex flex-col flex-1">
        <div className="flex justify-between items-center">
          <span className="text-xs font-bold tracking-[0.16em] text-gray-400 uppercase">{meta.label}</span>
          <span className={clsx('text-xs font-bold px-2 py-0.5 rounded-full border tracking-wide', t.badgeBg, t.badgeBorder, t.badgeText)}>
            {period}
          </span>
        </div>
        <div className="mt-3">
          <div className="text-[2.6rem] font-black text-gray-900 leading-none tracking-tight">{val.value}</div>
          <div className="mt-1.5 flex items-center gap-1.5 flex-wrap">
            <span className="text-sm font-bold text-gray-700">{val.delta}</span>
            <span className="text-xs text-gray-400">{val.deltaLabel}</span>
          </div>
        </div>
        <RangeBar meta={meta} val={val} vsPlan={vsPlan} />
        <div className="mt-4 pt-3.5 border-t border-gray-50 flex items-center justify-between gap-2">
          <span className={clsx(
            'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold tracking-wide border',
            t.badgeBg, t.badgeBorder, t.badgeText,
          )}>
            <span className={clsx('w-1.5 h-1.5 rounded-full flex-shrink-0', t.dot)} />
            {val.statusLabel}
          </span>
          {vsPlan && val.planLabel && !meta.isSpendTile && (
            <span className="inline-flex items-center gap-1 text-[13px] font-bold text-sky-600 whitespace-nowrap">
              <span className="w-2 h-2 rounded-full bg-sky-400 flex-shrink-0" />
              {val.planLabel}
            </span>
          )}
        </div>

        {/* ── Functional Area contribution ────────────────────────────── */}
        {faContrib && selectedFA && (
          <div className="mt-3 pt-3 border-t border-dashed border-violet-100">
            <div className="flex items-center justify-between mb-1.5">
              <div className="flex items-center gap-1.5 min-w-0">
                <span className="w-2 h-2 rounded-sm bg-violet-400 flex-shrink-0" />
                <span className="text-xs font-black tracking-[0.12em] text-violet-600 uppercase truncate">{selectedFA}</span>
              </div>
              <span className="text-xs font-black text-gray-800 tabular-nums ml-2 flex-shrink-0">{faContrib.rawValue}</span>
            </div>
            {faContrib.dollarStr && (
              <p className="text-xs font-semibold text-violet-500 mb-1.5">{faContrib.dollarStr} revenue impact</p>
            )}
            <div className="relative h-1.5 bg-gray-100 rounded-full overflow-hidden">
              <div
                className="absolute inset-y-0 left-0 bg-violet-400 rounded-full"
                style={{ width: `${Math.max(faContrib.pct, 1.5)}%`, transition: 'width 0.7s ease' }}
              />
            </div>
            <p className="mt-1 text-xs text-gray-400 font-semibold">
              {faContrib.pct.toFixed(0)}% contribution to this KPI
            </p>
          </div>
        )}
      </div>
    </div>
  )
}

// ── KPI card skeleton ─────────────────────────────────────────────────────────

function KpiCardSkeleton() {
  return (
    <div className="relative flex flex-col rounded-2xl overflow-hidden bg-white shadow-sm ring-1 ring-gray-100 animate-pulse">
      <div className="absolute left-0 top-0 bottom-0 w-1 bg-gray-200" />
      <div className="pl-6 pr-5 pt-5 pb-5 flex flex-col flex-1 gap-3">
        <div className="h-3 w-28 bg-gray-200 rounded" />
        <div className="h-12 w-24 bg-gray-200 rounded mt-1" />
        <div className="h-2 w-full bg-gray-100 rounded-full mt-4" />
        <div className="h-6 w-20 bg-gray-100 rounded-full mt-3" />
      </div>
    </div>
  )
}

// ── Shared helpers ────────────────────────────────────────────────────────────

function fmtVal(v: number, unit: string): string {
  if (unit === '$M')  return `$${v.toFixed(2)}M`
  if (unit === 'pts') return `${v.toFixed(2)} pts`
  return `${v.toFixed(2)}%`
}


function SortIcon({ sortState, colKey }: { sortState: { key: string; dir: 'asc' | 'desc' }; colKey: string }) {
  if (sortState.key !== colKey) return <span className="text-xs text-gray-300 select-none">⇅</span>
  return <span className="text-xs text-gray-500">{sortState.dir === 'asc' ? '▲' : '▼'}</span>
}

// ── Functional area picker ────────────────────────────────────────────────────

function FunctionalAreaPicker({ areas, value, onChange }: {
  areas: string[]; value: string | null; onChange: (v: string | null) => void
}) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const active = value !== null

  useEffect(() => {
    if (!open) return
    function close(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', close)
    return () => document.removeEventListener('mousedown', close)
  }, [open])

  return (
    <div ref={ref} className="relative">
      <div
        onClick={() => setOpen(o => !o)}
        className={clsx(
          'flex items-center gap-2 px-3 py-2 rounded-xl border shadow-sm cursor-pointer transition-all duration-200 select-none',
          active ? 'bg-violet-50 border-violet-300' : 'bg-white border-gray-200 hover:border-gray-300',
          open && 'ring-2 ring-violet-100',
        )}
      >
        <span className={clsx('text-xs font-black tracking-[0.14em] uppercase whitespace-nowrap',
          active ? 'text-violet-500' : 'text-gray-400'
        )}>Area</span>
        <div className="w-px h-3.5 bg-gray-200" />
        <span className={clsx('text-xs font-semibold whitespace-nowrap max-w-[180px] truncate',
          active ? 'text-violet-700' : 'text-gray-400'
        )}>
          {value ?? 'All'}
        </span>
        {active
          ? <button
              onClick={e => { e.stopPropagation(); onChange(null); setOpen(false) }}
              className="text-violet-400 hover:text-violet-700 transition-colors ml-0.5 flex-shrink-0"
            ><X size={12} /></button>
          : <ChevronDown size={11} className={clsx('text-gray-400 transition-transform duration-200 ml-0.5 flex-shrink-0', open && 'rotate-180')} />
        }
      </div>

      {open && (
        <div className="absolute right-0 top-full mt-1.5 z-50 w-64 bg-white border border-gray-200 rounded-xl shadow-xl overflow-hidden">
          {/* max-h fits exactly 10 items (each ~32px) then scrolls */}
          <div className="overflow-y-auto max-h-[320px]">
            <button
              className={clsx('w-full text-left px-4 py-2 text-xs font-semibold transition-colors',
                value === null ? 'bg-violet-50 text-violet-700' : 'text-gray-500 hover:bg-gray-50'
              )}
              onClick={() => { onChange(null); setOpen(false) }}
            >All areas</button>
            <div className="h-px bg-gray-100 mx-3" />
            {areas.map(a => (
              <button
                key={a}
                className={clsx('w-full text-left px-4 py-2 text-xs font-semibold transition-colors truncate',
                  value === a ? 'bg-violet-50 text-violet-700' : 'text-gray-700 hover:bg-violet-50 hover:text-violet-700'
                )}
                onClick={() => { onChange(a); setOpen(false) }}
              >{a}</button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ── Description popover ───────────────────────────────────────────────────────

function DescriptionPopover({ text }: { text: string }) {
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean)
  const hasBullets = lines.some(l => /^[•\-*]/.test(l))
  return (
    <div
      className="absolute left-0 top-full mt-2 z-50 w-80 bg-white border border-gray-200 rounded-xl shadow-xl p-4 max-h-64 overflow-y-auto"
      onClickCapture={e => e.stopPropagation()}
    >
      {hasBullets ? (
        <ul className="space-y-2">
          {lines.map((line, i) => (
            <li key={i} className="flex gap-2 text-xs text-gray-700 leading-relaxed">
              <span className="text-gray-400 flex-shrink-0 mt-px">•</span>
              <span>{line.replace(/^[•\-*]\s*/, '')}</span>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-xs text-gray-700 leading-relaxed whitespace-pre-line">{text}</p>
      )}
    </div>
  )
}

// ── Use case widget ───────────────────────────────────────────────────────────

function UseCaseWidget({ drill, vsPlan, kpiDrill, unit = '$M', kpiTotal = 0, filterArea }: {
  drill: DrillData; vsPlan: boolean
  kpiDrill?: KpiDrillData | null; unit?: string; kpiTotal?: number
  filterArea?: string | null
}) {
  const [openPopover, setOpenPopover] = useState<string | null>(null)
  const [sort, setSort] = useState<{ key: string; dir: 'asc' | 'desc' }>({ key: 'rank', dir: 'asc' })

  function handleSort(key: string) {
    setSort(s => ({ key, dir: s.key === key && s.dir === 'asc' ? 'desc' : 'asc' }))
  }

  useEffect(() => {
    if (!openPopover) return
    function close() { setOpenPopover(null) }
    document.addEventListener('click', close)
    return () => document.removeEventListener('click', close)
  }, [openPopover])

  const descByName = Object.fromEntries(drill.byUseCase.map(u => [u.name, u.description]))

  // ── KPI metric mode ────────────────────────────────────────────────────────
  if (kpiDrill) {
    const allItems = kpiDrill.byUseCase
    const visibleItems = filterArea ? allItems.filter(i => i.functionalArea === filterArea) : allItems
    const items = [...visibleItems].sort((a, b) => {
      if (sort.key === 'label')         return sort.dir === 'asc' ? a.label.localeCompare(b.label) : b.label.localeCompare(a.label)
      if (sort.key === 'value')         return sort.dir === 'asc' ? a.value - b.value : b.value - a.value
      if (sort.key === 'currentPhase')  return sort.dir === 'asc' ? (a.currentPhase ?? '').localeCompare(b.currentPhase ?? '') : (b.currentPhase ?? '').localeCompare(a.currentPhase ?? '')
      if (sort.key === 'functionalArea') return sort.dir === 'asc' ? (a.functionalArea ?? '').localeCompare(b.functionalArea ?? '') : (b.functionalArea ?? '').localeCompare(a.functionalArea ?? '')
      if (sort.key === 'plan') { const ap = a.plan ?? -1; const bp = b.plan ?? -1; return sort.dir === 'asc' ? ap - bp : bp - ap }
      return 0
    })
    const maxBar     = items.reduce((m, i) => Math.max(m, i.value), 0) || 1
    const hasDollars = items.some(i => i.dollarValue != null)
    const heading    = filterArea
      ? `${items.length} use cases · ${filterArea}`
      : `All ${items.length} use cases`

    function fmtDisplayVal(uc: typeof items[number]) {
      if (hasDollars && uc.dollarValue != null) return `$${uc.dollarValue.toFixed(1)}M`
      return fmtVal(uc.value, unit)
    }
    function fmtDisplayPlan(uc: typeof items[number]) {
      if (hasDollars && uc.dollarPlan != null) return `$${uc.dollarPlan.toFixed(1)}M`
      return fmtVal(uc.plan ?? 0, unit)
    }

    return (
      <div className="bg-white rounded-2xl shadow-sm ring-1 ring-gray-100 p-6 flex flex-col">
        <div className="mb-6">
          <p className="text-xs font-bold tracking-[0.16em] text-gray-400 uppercase">
            {heading} — {unit === 'pts' ? 'NPS impact' : 'metric impact'}
          </p>
        </div>
        <div className="flex items-center gap-3 pb-2.5 border-b border-gray-100 mb-1">
          <span className="text-xs font-bold tracking-wider text-gray-400 w-5 flex-shrink-0">#</span>
          <div className="flex items-center gap-1 cursor-pointer select-none flex-1" onClick={() => handleSort('label')}>
            <span className="text-xs font-bold tracking-wider text-gray-400">Use case</span>
            <SortIcon sortState={sort} colKey="label" />
          </div>
          <div className="flex items-center gap-1 cursor-pointer select-none w-40 flex-shrink-0" onClick={() => handleSort('currentPhase')}>
            <span className="text-xs font-bold tracking-wider text-gray-400">Status</span>
            <SortIcon sortState={sort} colKey="currentPhase" />
          </div>
          <div className="flex items-center gap-1 cursor-pointer select-none w-36 flex-shrink-0" onClick={() => handleSort('functionalArea')}>
            <span className="text-xs font-bold tracking-wider text-gray-400">Area</span>
            <SortIcon sortState={sort} colKey="functionalArea" />
          </div>
          <div className="flex items-center gap-1 cursor-pointer select-none shrink-0" onClick={() => handleSort('value')}>
            <span className="text-xs font-bold tracking-wider text-gray-400">{hasDollars ? '$M' : unit}</span>
            <SortIcon sortState={sort} colKey="value" />
          </div>
          {vsPlan && (
            <div className="flex items-center gap-1 cursor-pointer select-none shrink-0 pl-3 border-l border-dashed border-sky-200" onClick={() => handleSort('plan')}>
              <span className="text-xs font-bold tracking-wider text-sky-400">Plan</span>
              <SortIcon sortState={sort} colKey="plan" />
            </div>
          )}
        </div>
        <div className="space-y-5 overflow-y-auto overflow-x-hidden max-h-[28rem] pr-3">
          {items.map((uc, i) => {
            const isOver     = uc.plan != null && uc.value > uc.plan
            const desc       = descByName[uc.label]
            const actualW    = `${(uc.value / maxBar) * 100}%`
            const pctOfTotal = kpiTotal > 0 ? ((uc.value / kpiTotal) * 100).toFixed(0) : '—'
            return (
              <div key={uc.label}>
                <div className="flex items-center gap-3 mb-2">
                  <span className="text-xs font-black font-mono text-gray-300 w-5 flex-shrink-0">{String(i + 1).padStart(2, '0')}</span>
                  <div className="relative min-w-0 flex-1">
                    <span
                      className={clsx('block truncate text-sm font-semibold text-gray-700 leading-tight', desc ? 'cursor-pointer border-b border-dashed border-gray-300' : 'cursor-default')}
                      title={uc.label}
                      onClick={e => { if (!desc) return; e.stopPropagation(); setOpenPopover(openPopover === uc.label ? null : uc.label) }}
                    >{uc.label}</span>
                    {openPopover === uc.label && desc && <DescriptionPopover text={desc} />}
                  </div>
                  <span className={clsx('text-xs font-semibold px-2 py-1 rounded-md w-40 flex-shrink-0 text-center break-words leading-tight', phaseStyle(uc.currentPhase))}
                    title={uc.currentPhase ?? ''}>
                    {uc.currentPhase ?? '—'}
                  </span>
                  <div className="w-36 flex-shrink-0 min-w-0" title={uc.functionalArea ?? ''}>
                    <span className="block text-xs text-gray-500 truncate leading-tight">{uc.functionalArea ?? '—'}</span>
                  </div>
                  <span className={clsx('text-sm font-black tabular-nums shrink-0',
                    vsPlan && uc.plan != null
                      ? (isOver ? 'text-green-600' : uc.value === uc.plan ? 'text-gray-900' : 'text-rose-500')
                      : 'text-gray-900'
                  )}>{fmtDisplayVal(uc)}</span>
                  {vsPlan && (
                    <span className="text-sm font-bold tabular-nums text-sky-500 shrink-0 pl-3 border-l border-dashed border-sky-100">
                      {uc.plan != null ? fmtDisplayPlan(uc) : '—'}
                    </span>
                  )}
                </div>
                <div className="relative h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div className="absolute inset-y-0 left-0 rounded-full bg-gray-800"
                    style={{ width: actualW, transition: `width 0.5s cubic-bezier(.4,0,.2,1) ${i * 60}ms` }} />
                </div>
                <p className="mt-1 text-xs text-gray-400 font-medium">{pctOfTotal}% of total</p>
              </div>
            )
          })}
          {items.length === 0 && (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center mb-3">
                <X size={16} className="text-gray-400" />
              </div>
              <p className="text-sm font-semibold text-gray-500">No use cases in {filterArea}</p>
              <p className="text-xs text-gray-400 mt-1">for this KPI metric</p>
            </div>
          )}
        </div>
      </div>
    )
  }

  // ── AI Cost mode ───────────────────────────────────────────────────────────
  const allCostItems = drill.byUseCase
  const visibleCostItems = filterArea ? allCostItems.filter(u => u.functionalArea === filterArea) : allCostItems
  const items = [...visibleCostItems].sort((a, b) => {
    if (sort.key === 'name')           return sort.dir === 'asc' ? a.name.localeCompare(b.name) : b.name.localeCompare(a.name)
    if (sort.key === 'amount')         return sort.dir === 'asc' ? a.amount - b.amount : b.amount - a.amount
    if (sort.key === 'currentPhase')   return sort.dir === 'asc' ? (a.currentPhase ?? '').localeCompare(b.currentPhase ?? '') : (b.currentPhase ?? '').localeCompare(a.currentPhase ?? '')
    if (sort.key === 'functionalArea') return sort.dir === 'asc' ? (a.functionalArea ?? '').localeCompare(b.functionalArea ?? '') : (b.functionalArea ?? '').localeCompare(a.functionalArea ?? '')
    if (sort.key === 'plan') { const ap = a.plan ?? -1; const bp = b.plan ?? -1; return sort.dir === 'asc' ? ap - bp : bp - ap }
    return 0
  })
  const heading   = filterArea ? `${items.length} use cases · ${filterArea}` : `All ${items.length} use cases`

  return (
    <div className="bg-white rounded-2xl shadow-sm ring-1 ring-gray-100 p-6 flex flex-col">
      <div className="mb-6">
        <p className="text-xs font-bold tracking-[0.16em] text-gray-400 uppercase">{heading} — by spend</p>
      </div>
      <div className="flex items-center gap-3 pb-2.5 border-b border-gray-100 mb-1">
        <span className="text-xs font-bold tracking-wider text-gray-400 w-5 flex-shrink-0">#</span>
        <div className="flex items-center gap-1 cursor-pointer select-none flex-1" onClick={() => handleSort('name')}>
          <span className="text-xs font-bold tracking-wider text-gray-400">Use case</span>
          <SortIcon sortState={sort} colKey="name" />
        </div>
        <div className="flex items-center gap-1 cursor-pointer select-none w-40 flex-shrink-0" onClick={() => handleSort('currentPhase')}>
          <span className="text-xs font-bold tracking-wider text-gray-400">Status</span>
          <SortIcon sortState={sort} colKey="currentPhase" />
        </div>
        <div className="flex items-center gap-1 cursor-pointer select-none w-36 flex-shrink-0" onClick={() => handleSort('functionalArea')}>
          <span className="text-xs font-bold tracking-wider text-gray-400">Area</span>
          <SortIcon sortState={sort} colKey="functionalArea" />
        </div>
        <div className="flex items-center gap-1 cursor-pointer select-none shrink-0" onClick={() => handleSort('amount')}>
          <span className="text-xs font-bold tracking-wider text-gray-400">$M</span>
          <SortIcon sortState={sort} colKey="amount" />
        </div>
        {vsPlan && (
          <div className="flex items-center gap-1 cursor-pointer select-none shrink-0 pl-3 border-l border-dashed border-sky-200" onClick={() => handleSort('plan')}>
            <span className="text-xs font-bold tracking-wider text-sky-400">Plan</span>
            <SortIcon sortState={sort} colKey="plan" />
          </div>
        )}
      </div>
      <div className="space-y-5 overflow-y-auto overflow-x-hidden max-h-[28rem] pr-3">
        {items.map((uc, i) => {
          const isOver     = uc.plan !== undefined && uc.plan !== null && uc.amount > uc.plan
          const actualW    = `${kpiTotal > 0 ? (uc.amount / kpiTotal) * 100 : 0}%`
          const pctOfTotal = kpiTotal > 0 ? ((uc.amount / kpiTotal) * 100).toFixed(0) : '—'
          return (
            <div key={uc.name}>
              <div className="flex items-center gap-3 mb-2">
                <span className="text-xs font-black font-mono text-gray-300 w-5 flex-shrink-0">{String(i + 1).padStart(2, '0')}</span>
                <div className="min-w-0 flex-1 flex items-center gap-2">
                  <div className="relative min-w-0 flex-1">
                    <span
                      className={clsx('block truncate text-sm font-semibold text-gray-700 leading-tight', uc.description ? 'cursor-pointer border-b border-dashed border-gray-300' : 'cursor-default')}
                      title={uc.name}
                      onClick={e => { if (!uc.description) return; e.stopPropagation(); setOpenPopover(openPopover === uc.name ? null : uc.name) }}
                    >{uc.name}</span>
                    {openPopover === uc.name && uc.description && <DescriptionPopover text={uc.description} />}
                  </div>
                  <div className="flex items-center gap-1 flex-shrink-0">
                    {(uc.kpi ? uc.kpi.split(',').filter(Boolean) : []).map(tag => (
                      <span key={tag} className={clsx('text-xs font-bold px-2 py-0.5 rounded-full', kpiTag(tag))}>
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
                <span className={clsx('text-xs font-semibold px-2 py-1 rounded-md w-40 flex-shrink-0 text-center break-words leading-tight', phaseStyle(uc.currentPhase))}
                  title={uc.currentPhase ?? ''}>
                  {uc.currentPhase ?? '—'}
                </span>
                <div className="w-36 flex-shrink-0 min-w-0" title={uc.functionalArea ?? ''}>
                  <span className="block text-xs text-gray-500 truncate leading-tight">{uc.functionalArea ?? '—'}</span>
                </div>
                <span className={clsx('text-sm font-black tabular-nums shrink-0',
                  vsPlan && uc.plan != null
                    ? (isOver ? 'text-rose-500' : uc.amount === uc.plan ? 'text-gray-900' : 'text-green-600')
                    : 'text-gray-900'
                )}>{fmtVal(uc.amount, '$M')}</span>
                {vsPlan && (
                  <span className="text-sm font-bold tabular-nums text-sky-500 shrink-0 pl-3 border-l border-dashed border-sky-100">
                    {uc.plan != null ? fmtVal(uc.plan, '$M') : '—'}
                  </span>
                )}
              </div>
              <div className="relative h-2 bg-gray-100 rounded-full overflow-hidden">
                <div className={clsx('absolute inset-y-0 left-0 rounded-full', isOver && vsPlan ? 'bg-rose-500' : 'bg-gray-800')}
                  style={{ width: actualW, transition: `width 0.5s cubic-bezier(.4,0,.2,1) ${i * 60}ms` }} />
              </div>
              <p className="mt-1 text-xs text-gray-400 font-medium">{pctOfTotal}% of total</p>
            </div>
          )
        })}
        {items.length === 0 && (
          <div className="flex flex-col items-center justify-center py-16 text-center">
            <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center mb-3">
              <X size={16} className="text-gray-400" />
            </div>
            <p className="text-sm font-semibold text-gray-500">No use cases in {filterArea}</p>
          </div>
        )}
      </div>
    </div>
  )
}

// ── Widget skeleton ───────────────────────────────────────────────────────────

function WidgetSkeleton() {
  return (
    <div className="bg-white rounded-2xl shadow-sm ring-1 ring-gray-100 p-6 animate-pulse">
      <div className="h-3 w-32 bg-gray-200 rounded mb-4" />
      <div className="space-y-4">
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="flex items-center gap-4">
            <div className="h-3 w-40 bg-gray-100 rounded" />
            <div className="flex-1 h-2 bg-gray-100 rounded-full" />
          </div>
        ))}
      </div>
    </div>
  )
}

// ── Main tab ──────────────────────────────────────────────────────────────────

export function OverviewTab() {
  const [period,              setPeriod]              = useState<Period>('YTD')
  const [vsPlan,              setVsPlan]              = useState(false)
  const [exporting,           setExporting]           = useState(false)
  const [selectedKpi,         setSelectedKpi]         = useState<string>('revenue')
  const [selectedFunctionalArea, setSelectedFunctionalArea] = useState<string | null>(null)

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ['overview', period],
    queryFn:  () => fetchOverviewSummary(period),
    staleTime: 5 * 60 * 1000,
    placeholderData: (prev) => prev,
  })

  const tileVals     = data?.kpis
  const drill        = data?.investment
  const kpiBreakdown = data?.kpiBreakdown
  const costVal      = tileVals?.[0]?.value ?? '…'

  // Derive sorted unique functional areas + CSG mapping from all use cases
  const { uniqueAreas, areaToCsgs } = (() => {
    if (!drill?.byUseCase) return { uniqueAreas: [], areaToCsgs: {} as Record<string, string[]> }
    const areaSet = new Set<string>()
    const csgMap: Record<string, Set<string>> = {}
    for (const u of drill.byUseCase) {
      if (u.functionalArea) {
        areaSet.add(u.functionalArea)
        if (u.csg) {
          if (!csgMap[u.functionalArea]) csgMap[u.functionalArea] = new Set()
          csgMap[u.functionalArea].add(u.csg)
        }
      }
    }
    return {
      uniqueAreas: [...areaSet].sort((a, b) => a.localeCompare(b)),
      areaToCsgs:  Object.fromEntries(Object.entries(csgMap).map(([k, v]) => [k, [...v].sort()])),
    }
  })()

  const selectedCsgs = selectedFunctionalArea ? (areaToCsgs[selectedFunctionalArea] ?? []) : []

  // Compute FA contribution for every KPI tile
  const faContribs: Record<string, FaContrib | null> = (() => {
    if (!selectedFunctionalArea || !data || !tileVals) return {}
    const result: Record<string, FaContrib | null> = {}

    for (const m of TILE_META) {
      const tileIdx  = TILE_META.indexOf(m)
      const kpiTotal = tileVals[tileIdx]?.current ?? 0
      if (kpiTotal === 0) { result[m.id] = null; continue }

      let sum = 0; let dollarSum: number | null = null

      if (m.id === 'ai-cost') {
        sum = (data.investment.byUseCase)
          .filter(u => u.functionalArea === selectedFunctionalArea)
          .reduce((s, u) => s + u.amount, 0)
      } else {
        const kpiKey  = m.id as 'revenue' | 'nps' | 'efficiency'
        const kpiItems = data.kpiBreakdown[kpiKey].byUseCase
        sum = kpiItems
          .filter(i => i.functionalArea === selectedFunctionalArea)
          .reduce((s, i) => s + i.value, 0)
        if (m.id === 'revenue') {
          dollarSum = kpiItems
            .filter(i => i.functionalArea === selectedFunctionalArea && i.dollarValue != null)
            .reduce((s, i) => s + (i.dollarValue ?? 0), 0)
        }
      }

      const pct = kpiTotal > 0 ? Math.min(100, (sum / kpiTotal) * 100) : 0
      let rawValue = ''
      if (m.id === 'ai-cost')    rawValue = `$${sum.toFixed(1)}M invested`
      else if (m.id === 'revenue')    rawValue = `${sum.toFixed(2)}% growth`
      else if (m.id === 'nps')        rawValue = `${sum.toFixed(2)} pts`
      else                            rawValue = `${sum.toFixed(1)}% gain`

      result[m.id] = {
        pct,
        rawValue,
        dollarStr: dollarSum != null && dollarSum > 0 ? `$${dollarSum.toFixed(1)}M` : undefined,
      }
    }
    return result
  })()

  async function handleExport() {
    if (!tileVals || !drill || exporting) return
    setExporting(true)
    try {
      await exportOverviewPDF(period, tileVals, drill, 'category', selectedKpi, kpiBreakdown)
    } finally {
      setExporting(false)
    }
  }

  const isSpendView = selectedKpi === 'ai-cost'
  const kpiDrill    = !isSpendView ? kpiBreakdown?.[selectedKpi as 'revenue' | 'nps' | 'efficiency'] ?? null : null
  const unit        = selectedKpi === 'nps' ? 'pts' : isSpendView ? '$M' : '%'
  const kpiTotalVal = tileVals?.[TILE_META.findIndex(m => m.id === selectedKpi)]?.current ?? 0

  const sectionHeading = isSpendView ? 'AI Investment Breakdown' :
    selectedKpi === 'revenue'    ? 'Revenue Growth Breakdown'    :
    selectedKpi === 'nps'        ? 'NPS Improvement Breakdown'   : 'Efficiency Gain Breakdown'
  const sectionSubheading = isSpendView ? `Where the ${costVal} is going` :
    selectedKpi === 'revenue'    ? '% revenue growth by initiative'       :
    selectedKpi === 'nps'        ? 'NPS improvement points by initiative' : '% efficiency gain by initiative'

  return (
    <div className="flex flex-col gap-5 p-6 bg-gray-50/60 min-h-full">

      {/* ── Header ─────────────────────────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black text-gray-900 tracking-tight">Overview</h1>
            {isFetching && !isLoading && (
              <span className="text-xs font-semibold text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full animate-pulse">
                refreshing…
              </span>
            )}
          </div>
          <p className="text-xs text-gray-400 mt-0.5 font-medium tracking-wide">FY26 · AI investment performance tracker</p>
        </div>

        <div className="flex items-center gap-2">
          <div className="flex items-center bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm">
            {(['YTD', 'Q1', 'Q2', 'Q3', 'Q4'] as Period[]).map(p => {
              const isDisabled = p !== 'YTD'
              return (
                <button
                  key={p} onClick={() => setPeriod(p)} disabled={isDisabled}
                  className={clsx(
                    'px-4 py-2 text-xs font-bold tracking-wide transition-all',
                    isDisabled ? 'text-gray-300 cursor-not-allowed'
                      : period === p ? 'bg-gray-900 text-white' : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50',
                  )}
                >{p}</button>
              )
            })}
          </div>
          <button
            onClick={() => setVsPlan(v => !v)}
            className={clsx(
              'px-4 py-2 text-xs font-bold tracking-wide border rounded-xl transition-all shadow-sm',
              vsPlan ? 'bg-gray-900 text-white border-gray-900' : 'bg-white text-gray-500 border-gray-200 hover:text-gray-800 hover:border-gray-300',
            )}
          >VS PLAN</button>
          <button
            onClick={handleExport} disabled={exporting || !data}
            className="flex items-center gap-1.5 px-4 py-2 bg-gray-900 text-white text-xs font-bold tracking-wide rounded-xl hover:bg-gray-700 transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Download size={13} />
            {exporting ? 'EXPORTING…' : 'EXPORT'}
          </button>
        </div>
      </div>

      {/* ── Error ─────────────────────────────────────────────────────── */}
      {isError && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm font-medium">
          Failed to load dashboard data. Check BigQuery connectivity and refresh.
        </div>
      )}

      {/* ── KPI cards ─────────────────────────────────────────────────── */}
      <div className="grid gap-4" style={{ gridTemplateColumns: '1fr 1fr 1fr 3px 1fr' }}>
        {isLoading || !tileVals ? (
          <>
            <KpiCardSkeleton /><KpiCardSkeleton /><KpiCardSkeleton />
            <div className="bg-black self-stretch" />
            <KpiCardSkeleton />
          </>
        ) : (
          <>
            {[1, 2, 3].map(i => (
              <KpiCard
                key={TILE_META[i].id} meta={TILE_META[i]} val={tileVals[i]} period={period} vsPlan={vsPlan}
                isSelected={selectedKpi === TILE_META[i].id}
                onClick={() => setSelectedKpi(TILE_META[i].id)}
                faContrib={faContribs[TILE_META[i].id]}
                selectedFA={selectedFunctionalArea}
              />
            ))}
            <div className="bg-black self-stretch" />
            <KpiCard
              meta={TILE_META[0]} val={tileVals[0]} period={period} vsPlan={vsPlan}
              isSelected={selectedKpi === TILE_META[0].id}
              onClick={() => setSelectedKpi(TILE_META[0].id)}
              faContrib={faContribs[TILE_META[0].id]}
              selectedFA={selectedFunctionalArea}
            />
          </>
        )}
      </div>

      {/* ── Lower section ─────────────────────────────────────────────── */}
      <div className="space-y-3">
        <div className="flex items-start justify-between px-1">
          <div>
            <p className="text-xs font-bold tracking-[0.2em] text-gray-400 uppercase">{sectionHeading}</p>
            <h2 className="text-lg font-black text-gray-900 mt-0.5 tracking-tight">{sectionSubheading}</h2>
          </div>
          <div className="flex flex-col items-end gap-2">
            <FunctionalAreaPicker
              areas={uniqueAreas}
              value={selectedFunctionalArea}
              onChange={setSelectedFunctionalArea}
            />
            {selectedFunctionalArea && selectedCsgs.length > 0 && (
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold tracking-[0.14em] text-gray-400 uppercase">CSG</span>
                <div className="w-px h-3 bg-gray-200" />
                {selectedCsgs.map(csg => (
                  <span key={csg} className={clsx('text-xs font-semibold px-2.5 py-0.5 rounded-full', csgStyle(csg))}>
                    {csg}
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        {isLoading || !drill
          ? <WidgetSkeleton />
          : <UseCaseWidget
              drill={drill} vsPlan={vsPlan} kpiDrill={kpiDrill}
              unit={unit} kpiTotal={kpiTotalVal}
              filterArea={selectedFunctionalArea}
            />
        }
      </div>
    </div>
  )
}
