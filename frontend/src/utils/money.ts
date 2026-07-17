// Shared money-column detection and raw-dollar auto-scale formatting, used by
// DataTable and ChartRenderer (both render arbitrary query-result columns and
// need to guess which ones are dollar amounts vs plain counts).

const MONEY_COL = /spend|dollar|amount|budget|cost|ytd|capital|expense|salary|fee/i
const COUNT_COL = /count|ftp|fte|hc|headcount|qty|quantity|rank|row_num|num_/i

export function isMoneyColumn(key: string): boolean {
  return MONEY_COL.test(key) && !COUNT_COL.test(key)
}

// val is raw dollars — auto-scale so small amounts (e.g. $1,500) don't round
// away to "$0.00M".
export function fmtDollarsAutoRaw(val: number, decimals = 2): string {
  const abs = Math.abs(val)
  if (abs >= 1_000_000) return `$${(val / 1_000_000).toFixed(decimals)}M`
  if (abs >= 1_000) return `$${(val / 1_000).toFixed(decimals)}K`
  return `$${val.toFixed(decimals)}`
}

// v is in millions (e.g. 12.34 == $12.34M) — same auto-scale as above, just a
// different input unit (this is the app's native unit for KPI/dollar fields
// coming out of the overview API — see backend/bigquery_client.py's
// _dollars_to_millions).
export function fmtDollarsAutoMillions(v: number, decimals = 2): string {
  const abs = Math.abs(v)
  if (abs >= 1) return `$${v.toFixed(decimals)}M`
  if (abs >= 0.001) return `$${(v * 1_000).toFixed(decimals)}K`
  return `$${(v * 1_000_000).toFixed(decimals)}`
}
