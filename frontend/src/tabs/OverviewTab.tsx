import { useState, useEffect, useRef } from 'react'
import { Download } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import clsx from 'clsx'
import { fetchOverviewSummary, type TileVal, type DrillData, type KpiDrillData } from '../api/overview'
import { exportOverviewPDF } from '../api/pdf'

// ── Types ─────────────────────────────────────────────────────────────────────

type Status    = 'in-band' | 'below-target' | 'above-target' | 'under-plan' | 'over-plan'
type DrillView = 'category' | 'vendor'
type Period    = 'YTD' | 'Q1' | 'Q2' | 'Q3' | 'Q4'

interface TileMeta {
  id: string; label: string
  rangeMin: number; rangeMax: number
  targetMin: number; targetMax: number
  rangeUnit: string; targetLabel: string
  isSpendTile?: boolean
}

// ── Static tile metadata — UI configuration only, never changes ───────────────

const TILE_META: TileMeta[] = [
  { id: 'ai-cost',    label: 'AI Cost',         rangeMin: 0, rangeMax: 60, targetMin: 0,  targetMax: 45, rangeUnit: 'M', targetLabel: '', isSpendTile: true },
  { id: 'revenue',    label: 'Revenue Growth',  rangeMin: 0, rangeMax: 10, targetMin: 3,  targetMax: 7,  rangeUnit: '%', targetLabel: 'target band 3–7%'   },
  { id: 'nps',        label: 'NPS Improvement', rangeMin: 0, rangeMax: 6,  targetMin: 2,  targetMax: 4,  rangeUnit: '',  targetLabel: 'target band 2–4'    },
  { id: 'efficiency', label: 'Efficiency Gain', rangeMin: 0, rangeMax: 50, targetMin: 30, targetMax: 40, rangeUnit: '%', targetLabel: 'target band 30–40%' },
]

const DRILL_VIEWS: { key: DrillView; label: string }[] = [
  { key: 'category', label: 'By Category' },
  { key: 'vendor',   label: 'By Vendor'   },
]

// ── Design tokens ─────────────────────────────────────────────────────────────

const STATUS: Record<Status, { strip: string; dot: string; badgeText: string; badgeBg: string; badgeBorder: string; ring: string; ringOffset: string }> = {
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

function asPct(val: number, min: number, max: number) {
  return `${Math.max(0, Math.min(100, ((val - min) / (max - min)) * 100)).toFixed(2)}%`
}
function kpiTag(kpi: string) { return KPI_TAG[kpi] ?? 'bg-gray-100 text-gray-600' }

// ── Range bar ─────────────────────────────────────────────────────────────────

function RangeBar({ meta, val, vsPlan }: { meta: TileMeta; val: TileVal; vsPlan: boolean }) {
  const { rangeMin, rangeMax, targetMin, targetMax, rangeUnit, targetLabel, isSpendTile } = meta
  const { current, planValue, planCurrent } = val

  if (isSpendTile) {
    const budget = planValue ?? 45
    const fillW  = asPct(current, rangeMin, rangeMax)
    const planL  = asPct(budget,  rangeMin, rangeMax)
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
  const currentL = asPct(current,   rangeMin, rangeMax)
  const planL    = planCurrent !== undefined ? asPct(planCurrent, rangeMin, rangeMax) : null

  return (
    <div className="mt-5">
      <div className="relative h-2 bg-gray-100 rounded-full w-full">
        <div className="absolute inset-y-0 bg-gray-300 rounded-full" style={{ left: targetL, width: targetW }} />
        {vsPlan && planL && (
          <div
            className="absolute top-1/2 w-3.5 h-3.5 bg-sky-400 rounded-full border-2 border-white shadow ring-1 ring-sky-200"
            style={{ left: planL, transform: 'translate(-50%, -50%)' }}
          />
        )}
        <div
          className="absolute top-1/2 w-4 h-4 bg-gray-900 rounded-full border-2 border-white shadow-md"
          style={{ left: currentL, transform: 'translate(-50%, -50%)' }}
        />
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

function KpiCard({ meta, val, period, vsPlan, isSelected, onClick }: {
  meta: TileMeta; val: TileVal; period: Period; vsPlan: boolean; isSelected: boolean; onClick: () => void
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
          <span className="text-[10px] font-bold tracking-[0.16em] text-gray-400 uppercase">{meta.label}</span>
          <span className={clsx('text-[9px] font-bold px-2 py-0.5 rounded-full border tracking-wide', t.badgeBg, t.badgeBorder, t.badgeText)}>
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
            'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wide border',
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

// ── Bar chart widget ──────────────────────────────────────────────────────────

function fmtVal(v: number, unit: string): string {
  if (unit === '$M')  return `$${v.toFixed(1)}M`
  if (unit === 'pts') return `${v.toFixed(1)} pts`
  return `${v.toFixed(1)}%`
}

function BarChartWidget({ drill, view, vsPlan, kpiDrill, unit = '$M', kpiTotal = 0 }: {
  drill: DrillData; view: DrillView; vsPlan: boolean
  kpiDrill?: KpiDrillData | null; unit?: string; kpiTotal?: number
}) {
  const items: Array<{ label: string; amount: number; plan?: number | null }> = kpiDrill
    ? (view === 'category' ? kpiDrill.byCategory : kpiDrill.byVendor).map(i => ({ label: i.label, amount: i.value, plan: i.plan }))
    : view === 'category' ? drill.byCategory : drill.byVendor

  const maxBar = Math.max(...items.map(i => Math.max(i.amount, i.plan ?? 0)))

  const heading = view === 'category'
    ? `All ${items.length} categories`
    : `All ${items.length} vendors`

  return (
    <div className="col-span-1 bg-white rounded-2xl shadow-sm ring-1 ring-gray-100 p-6 flex flex-col">
      <div className="flex items-start justify-between mb-6">
        <div>
          <p className="text-[10px] font-bold tracking-[0.16em] text-gray-400 uppercase">{heading}</p>
          <p className="text-sm font-black text-gray-900 mt-0.5">{fmtVal(kpiTotal, unit)} total</p>
        </div>
      </div>
      <div className="space-y-5 overflow-y-auto max-h-96">
        {items.map((item, i) => {
          const pctOfTotal = kpiTotal > 0 ? ((item.amount / kpiTotal) * 100).toFixed(0) : '—'
          const actualW    = `${(item.amount / maxBar) * 100}%`
          const planW      = item.plan ? `${(item.plan / maxBar) * 100}%` : '0%'
          const isOver     = item.plan !== undefined && item.plan !== null && item.amount > item.plan
          return (
            <div key={item.label}>
              <div className="flex justify-between items-baseline mb-2">
                <span className="text-sm font-semibold text-gray-700 leading-tight pr-4">{item.label}</span>
                <div className="flex items-center gap-2 shrink-0">
                  {vsPlan && item.plan != null && (
                    <span className={clsx('text-sm font-black tabular-nums', isOver ? 'text-rose-500' : 'text-sky-500')}>
                      Plan {fmtVal(item.plan, unit)}
                    </span>
                  )}
                  <span className="text-sm font-black text-gray-900 tabular-nums">{fmtVal(item.amount, unit)}</span>
                </div>
              </div>
              <div className="relative h-2 bg-gray-100 rounded-full overflow-hidden">
                {vsPlan && item.plan != null && (
                  <div
                    className="absolute inset-y-0 left-0 bg-sky-100 rounded-full"
                    style={{ width: planW, transition: `width 0.5s ease ${i * 60}ms` }}
                  />
                )}
                <div
                  className={clsx('absolute inset-y-0 left-0 rounded-full', isOver && vsPlan ? 'bg-rose-500' : 'bg-gray-800')}
                  style={{ width: actualW, transition: `width 0.5s cubic-bezier(.4,0,.2,1) ${i * 60}ms` }}
                />
              </div>
              <p className="mt-1 text-[10px] text-gray-400 font-medium">{pctOfTotal}% of total</p>
            </div>
          )
        })}
      </div>
      {vsPlan && (
        <div className="mt-5 pt-4 border-t border-gray-50 flex items-center gap-4 text-[11px] font-semibold">
          <span className="flex items-center gap-1.5"><span className="w-3 h-1.5 rounded-full bg-gray-800 inline-block" /> Actual</span>
          <span className="flex items-center gap-1.5"><span className="w-3 h-1.5 rounded-full bg-sky-200 inline-block" /> Plan</span>
          <span className="flex items-center gap-1.5"><span className="w-3 h-1.5 rounded-full bg-rose-400 inline-block" /> Over plan</span>
        </div>
      )}
    </div>
  )
}

// ── Use case table widget ─────────────────────────────────────────────────────

function DescriptionPopover({ text }: { text: string }) {
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean)
  const hasBullets = lines.some(l => /^[•\-\*]/.test(l))
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
              <span>{line.replace(/^[•\-\*]\s*/, '')}</span>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-xs text-gray-700 leading-relaxed whitespace-pre-line">{text}</p>
      )}
    </div>
  )
}

function UseCaseWidget({ drill, vsPlan, kpiDrill, unit = '$M', kpiTotal = 0 }: {
  drill: DrillData; vsPlan: boolean; kpiDrill?: KpiDrillData | null; unit?: string; kpiTotal?: number
}) {
  const [openPopover, setOpenPopover] = useState<string | null>(null)

  useEffect(() => {
    if (!openPopover) return
    function close() { setOpenPopover(null) }
    document.addEventListener('click', close)
    return () => document.removeEventListener('click', close)
  }, [openPopover])

  // Description lookup for kpi-metric mode
  const descByName = Object.fromEntries(drill.byUseCase.map(u => [u.name, u.description]))

  if (kpiDrill) {
    // ── KPI metric mode (Revenue / NPS / Efficiency) ───────────────────────
    const items  = kpiDrill.byUseCase
    const maxVal = Math.max(...items.map(u => Math.max(u.value, u.plan ?? 0)))
    const cols   = vsPlan ? 'repeat(13, minmax(0,1fr))' : 'repeat(12, minmax(0,1fr))'
    return (
      <div className="col-span-1 bg-white rounded-2xl shadow-sm ring-1 ring-gray-100 p-6 flex flex-col">
        <div className="mb-6">
          <p className="text-[10px] font-bold tracking-[0.16em] text-gray-400 uppercase">
            All {items.length} use cases — {unit === 'pts' ? 'NPS impact' : 'metric impact'}
          </p>
        </div>
        <div className="grid pb-2.5 border-b border-gray-100 mb-1" style={{ gridTemplateColumns: cols }}>
          <div className="col-span-1 text-[10px] font-bold tracking-wider text-gray-400">#</div>
          <div className="col-span-7 text-[10px] font-bold tracking-wider text-gray-400">Use case</div>
          <div className="col-span-2 text-[10px] font-bold tracking-wider text-gray-400">Metric</div>
          <div className="col-span-2 text-[10px] font-bold tracking-wider text-gray-400 text-right">{unit}</div>
          {vsPlan && <div className="col-span-1 text-[10px] font-bold tracking-wider text-gray-400 text-right">Plan</div>}
        </div>
        <div className="overflow-y-auto max-h-96">
          {items.map((uc, i) => {
            const actualW = `${(uc.value / maxVal) * 100}%`
            const planW   = uc.plan != null ? `${(uc.plan / maxVal) * 100}%` : '0%'
            const isOver  = uc.plan != null && uc.value > uc.plan
            const desc    = descByName[uc.label]
            return (
              <div
                key={uc.rank ?? uc.label}
                className={clsx(
                  'grid items-center py-3 rounded-xl -mx-2 px-2 transition-colors hover:bg-gray-50',
                  i < items.length - 1 && 'border-b border-gray-50',
                )}
                style={{ gridTemplateColumns: cols }}
              >
                <div className="col-span-1">
                  <span className="text-xs font-black font-mono text-gray-300">{uc.rank ?? String(i + 1).padStart(2, '0')}</span>
                </div>
                <div className="col-span-7 pr-2">
                  <div className="relative inline-block">
                    <span
                      className={clsx('text-sm font-semibold text-gray-800 leading-snug', desc ? 'cursor-pointer border-b border-dashed border-gray-300' : 'cursor-default')}
                      onClick={e => { if (!desc) return; e.stopPropagation(); setOpenPopover(openPopover === uc.label ? null : uc.label) }}
                    >{uc.label}</span>
                    {openPopover === uc.label && desc && <DescriptionPopover text={desc} />}
                  </div>
                </div>
                <div className="col-span-2 pr-2">
                  <div className="relative h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    {vsPlan && uc.plan != null && (
                      <div className="absolute inset-y-0 left-0 bg-sky-100 rounded-full" style={{ width: planW }} />
                    )}
                    <div
                      className={clsx('absolute inset-y-0 left-0 rounded-full', isOver && vsPlan ? 'bg-rose-500' : 'bg-gray-800')}
                      style={{ width: actualW, transition: `width 0.5s cubic-bezier(.4,0,.2,1) ${i * 60}ms` }}
                    />
                  </div>
                </div>
                <div className="col-span-2 text-right">
                  <span className={clsx('text-sm font-black tabular-nums', isOver && vsPlan ? 'text-rose-600' : 'text-gray-900')}>
                    {fmtVal(uc.value, unit)}
                  </span>
                  {kpiTotal > 0 && (
                    <p className="text-[10px] text-gray-400 font-medium">{((uc.value / kpiTotal) * 100).toFixed(0)}% of total</p>
                  )}
                </div>
                {vsPlan && (
                  <div className="col-span-1 text-right">
                    <span className={clsx('text-sm font-black tabular-nums', isOver && vsPlan ? 'text-rose-500' : 'text-sky-500')}>{uc.plan != null ? fmtVal(uc.plan, unit) : '—'}</span>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  // ── AI Cost mode (spend $M) ────────────────────────────────────────────────
  const items  = drill.byUseCase
  const maxAmt = Math.max(...items.map(u => Math.max(u.amount, u.plan ?? 0)))
  const cols   = vsPlan ? 'repeat(13, minmax(0,1fr))' : 'repeat(12, minmax(0,1fr))'
  return (
    <div className="col-span-1 bg-white rounded-2xl shadow-sm ring-1 ring-gray-100 p-6 flex flex-col">
      <div className="mb-6">
        <p className="text-[10px] font-bold tracking-[0.16em] text-gray-400 uppercase">
          All {items.length} use cases — by spend
        </p>
      </div>
      <div className="grid pb-2.5 border-b border-gray-100 mb-1" style={{ gridTemplateColumns: cols }}>
        <div className="col-span-1 text-[10px] font-bold tracking-wider text-gray-400">#</div>
        <div className="col-span-5 text-[10px] font-bold tracking-wider text-gray-400">Use case</div>
        <div className="col-span-2 text-[10px] font-bold tracking-wider text-gray-400">KPI</div>
        <div className="col-span-2 text-[10px] font-bold tracking-wider text-gray-400">Spend</div>
        <div className="col-span-2 text-[10px] font-bold tracking-wider text-gray-400 text-right">$M</div>
        {vsPlan && <div className="col-span-1 text-[10px] font-bold tracking-wider text-gray-400 text-right">Plan</div>}
      </div>
      <div className="overflow-y-auto max-h-96">
        {items.map((uc, i) => {
          const actualW = `${(uc.amount / maxAmt) * 100}%`
          const planW   = uc.plan != null ? `${(uc.plan / maxAmt) * 100}%` : '0%'
          const isOver  = uc.plan !== undefined && uc.plan !== null && uc.amount > uc.plan
          return (
            <div
              key={uc.rank}
              className={clsx(
                'grid items-center py-3 rounded-xl -mx-2 px-2 transition-colors hover:bg-gray-50',
                i < items.length - 1 && 'border-b border-gray-50',
              )}
              style={{ gridTemplateColumns: cols }}
            >
              <div className="col-span-1">
                <span className="text-xs font-black font-mono text-gray-300">{uc.rank}</span>
              </div>
              <div className="col-span-5 pr-2">
                <div className="relative inline-block">
                  <span
                    className={clsx('text-sm font-semibold text-gray-800 leading-snug', uc.description ? 'cursor-pointer border-b border-dashed border-gray-300' : 'cursor-default')}
                    onClick={e => { if (!uc.description) return; e.stopPropagation(); setOpenPopover(openPopover === uc.name ? null : uc.name) }}
                  >{uc.name}</span>
                  {openPopover === uc.name && uc.description && <DescriptionPopover text={uc.description} />}
                </div>
              </div>
              <div className="col-span-2">
                <span className={clsx('text-[10px] font-bold px-2 py-0.5 rounded-full', kpiTag(uc.kpi))}>
                  {uc.kpi}
                </span>
              </div>
              <div className="col-span-2 pr-2">
                <div className="relative h-1.5 bg-gray-100 rounded-full overflow-hidden">
                  {vsPlan && uc.plan != null && (
                    <div className="absolute inset-y-0 left-0 bg-sky-100 rounded-full" style={{ width: planW }} />
                  )}
                  <div
                    className={clsx('absolute inset-y-0 left-0 rounded-full', isOver && vsPlan ? 'bg-rose-500' : 'bg-gray-800')}
                    style={{ width: actualW, transition: `width 0.5s cubic-bezier(.4,0,.2,1) ${i * 60}ms` }}
                  />
                </div>
              </div>
              <div className="col-span-2 text-right">
                <span className={clsx('text-sm font-black tabular-nums', isOver && vsPlan ? 'text-rose-600' : 'text-gray-900')}>
                  ${uc.amount}M
                </span>
                {kpiTotal > 0 && (
                  <p className="text-[10px] text-gray-400 font-medium">{((uc.amount / kpiTotal) * 100).toFixed(0)}% of total</p>
                )}
              </div>
              {vsPlan && (
                <div className="col-span-1 text-right">
                  <span className={clsx('text-sm font-black tabular-nums', isOver && vsPlan ? 'text-rose-500' : 'text-sky-500')}>${uc.plan}M</span>
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}

// ── Widget skeletons ──────────────────────────────────────────────────────────

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
  const [period,      setPeriod]      = useState<Period>('YTD')
  const [vsPlan,      setVsPlan]      = useState(false)
  const [drillView,   setDrillView]   = useState<DrillView>('category')
  const [exporting,   setExporting]   = useState(false)
  const [selectedKpi, setSelectedKpi] = useState<string>('ai-cost')

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ['overview', period],
    queryFn: () => fetchOverviewSummary(period),
    staleTime: 5 * 60 * 1000,
    placeholderData: (prev) => prev,
  })

  const tileVals     = data?.kpis
  const drill        = data?.investment
  const kpiBreakdown = data?.kpiBreakdown
  const costVal      = tileVals?.[0]?.value ?? '…'
  const costLabel = `Where the ${costVal} is going`

  async function handleExport() {
    if (!tileVals || !drill || exporting) return
    setExporting(true)
    try {
      await exportOverviewPDF(period, tileVals, drill, drillView, selectedKpi, kpiBreakdown)
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="flex flex-col gap-5 p-6 bg-gray-50/60 min-h-full">

      {/* ── Header ─────────────────────────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black text-gray-900 tracking-tight">Overview</h1>
            {isFetching && !isLoading && (
              <span className="text-[10px] font-semibold text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full animate-pulse">
                refreshing…
              </span>
            )}
          </div>
          <p className="text-xs text-gray-400 mt-0.5 font-medium tracking-wide">FY26 · AI investment performance tracker</p>
        </div>

        <div className="flex items-center gap-2">
          {/* Period selector */}
          <div className="flex items-center bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm">
            {(['YTD', 'Q1', 'Q2', 'Q3', 'Q4'] as Period[]).map(p => {
              const isDisabled = p !== 'YTD'
              return (
                <button
                  key={p}
                  onClick={() => setPeriod(p)}
                  disabled={isDisabled}
                  className={clsx(
                    'px-4 py-2 text-xs font-bold tracking-wide transition-all',
                    isDisabled
                      ? 'text-gray-300 cursor-not-allowed'
                      : period === p ? 'bg-gray-900 text-white' : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50',
                  )}
                >
                  {p}
                </button>
              )
            })}
          </div>

          {/* VS PLAN */}
          <button
            onClick={() => setVsPlan(v => !v)}
            className={clsx(
              'px-4 py-2 text-xs font-bold tracking-wide border rounded-xl transition-all shadow-sm',
              vsPlan ? 'bg-gray-900 text-white border-gray-900' : 'bg-white text-gray-500 border-gray-200 hover:text-gray-800 hover:border-gray-300',
            )}
          >
            VS PLAN
          </button>

          <button
            onClick={handleExport}
            disabled={exporting || !data}
            className="flex items-center gap-1.5 px-4 py-2 bg-gray-900 text-white text-xs font-bold tracking-wide rounded-xl hover:bg-gray-700 transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Download size={13} />
            {exporting ? 'EXPORTING…' : 'EXPORT'}
          </button>
        </div>
      </div>

      {/* ── Error state ───────────────────────────────────────────────── */}
      {isError && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm font-medium">
          Failed to load dashboard data. Check BigQuery connectivity and refresh.
        </div>
      )}

      {/* ── KPI cards ─────────────────────────────────────────────────── */}
      <div className="grid grid-cols-4 gap-4">
        {isLoading || !tileVals
          ? TILE_META.map(m => <KpiCardSkeleton key={m.id} />)
          : TILE_META.map((meta, i) => (
              <KpiCard
                key={meta.id} meta={meta} val={tileVals[i]} period={period} vsPlan={vsPlan}
                isSelected={selectedKpi === meta.id}
                onClick={() => setSelectedKpi(meta.id)}
              />
            ))
        }
      </div>

      {/* ── Lower section ─────────────────────────────────────────────── */}
      {(() => {
        const isSpendView = selectedKpi === 'ai-cost'
        const kpiDrill    = !isSpendView ? kpiBreakdown?.[selectedKpi as 'revenue' | 'nps' | 'efficiency'] ?? null : null
        const unit        = selectedKpi === 'nps' ? 'pts' : isSpendView ? '$M' : '%'
        const sectionHeading = isSpendView ? 'AI Investment Breakdown' :
          selectedKpi === 'revenue'    ? 'Revenue Growth Breakdown'   :
          selectedKpi === 'nps'        ? 'NPS Improvement Breakdown'  : 'Efficiency Gain Breakdown'
        const sectionSubheading = isSpendView ? costLabel :
          selectedKpi === 'revenue'    ? '% revenue growth by initiative'    :
          selectedKpi === 'nps'        ? 'NPS improvement points by initiative' : '% efficiency gain by initiative'
        return (
          <div className="space-y-3">
            <div className="flex items-end justify-between px-1">
              <div>
                <p className="text-[10px] font-bold tracking-[0.2em] text-gray-400 uppercase">{sectionHeading}</p>
                <h2 className="text-lg font-black text-gray-900 mt-0.5 tracking-tight">{sectionSubheading}</h2>
              </div>
              <div className="flex items-center bg-white border border-gray-200 rounded-xl p-1 gap-0.5 shadow-sm">
                {DRILL_VIEWS.map(({ key, label }) => (
                  <button
                    key={key}
                    onClick={() => setDrillView(key)}
                    className={clsx(
                      'px-4 py-2 text-xs font-bold rounded-lg transition-all duration-200 tracking-wide',
                      drillView === key ? 'bg-gray-900 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700',
                    )}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              {isLoading || !drill
                ? <>
                    <div className="col-span-1"><WidgetSkeleton /></div>
                    <div className="col-span-1"><WidgetSkeleton /></div>
                  </>
                : <>
                    <UseCaseWidget  drill={drill} vsPlan={vsPlan} kpiDrill={kpiDrill} unit={unit} kpiTotal={tileVals?.[TILE_META.findIndex(m => m.id === selectedKpi)]?.current ?? 0} />
                    <BarChartWidget drill={drill} view={drillView} vsPlan={vsPlan} kpiDrill={kpiDrill} unit={unit} kpiTotal={tileVals?.[TILE_META.findIndex(m => m.id === selectedKpi)]?.current ?? 0} />
                  </>
              }
            </div>
          </div>
        )
      })()}
    </div>
  )
}
