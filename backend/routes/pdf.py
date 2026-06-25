import json
import re
import base64
import tempfile
import os
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
from fastapi import APIRouter
from fastapi.responses import FileResponse
from schemas import PDFRequest

_ASSETS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets')

# ── Margin constants ─────────────────────────────────────────────────────────
# Change ONLY these two values to control body/header gap on every content page.
# Rule: both @page CSS (line ~397) and Playwright margin= (line ~460) read these.
_MARGIN_TOP    = "72px"   # header height (52px) + breathing room
_MARGIN_BOTTOM = "50px"   # footer height (36px) + breathing room

def _logo_b64() -> str:
    try:
        with open(os.path.join(_ASSETS_DIR, 'logo.png'), 'rb') as f:
            return base64.b64encode(f.read()).decode()
    except Exception:
        return ''

def _header_html() -> str:
    logo = _logo_b64()
    now  = datetime.now(tz=ZoneInfo("America/New_York"))
    ts   = now.strftime('%m-%d-%Y %H:%M:%S') + ' ' + now.strftime('%Z')
    img  = (f'<img src="data:image/png;base64,{logo}" '
            f'style="height:28px;display:block;" />'
            if logo else
            '<span style="font-size:10pt;font-weight:700;color:#0F172A;">Company</span>')
    return f"""
<div style="width:100%;display:flex;align-items:center;justify-content:space-between;
     padding:0 56px;font-family:Arial,Helvetica,sans-serif;
     height:52px;box-sizing:border-box;">
  {img}
  <div style="text-align:right;line-height:1.3;">
    <div style="font-size:8.5pt;font-weight:700;color:#0F172A;letter-spacing:1.2px;">EXECUTIVE REPORT</div>
    <div style="font-size:7pt;color:#CBD5E1;margin-top:2px;">{ts}</div>
  </div>
</div>"""

def _footer_html() -> str:
    return """
<div style="width:100%;display:flex;align-items:center;justify-content:space-between;
     padding:0 56px;font-family:Arial,Helvetica,sans-serif;
     height:36px;box-sizing:border-box;">
  <span style="font-size:6.5pt;color:#CBD5E1;">Confidential</span>
  <span style="font-size:6.5pt;color:#CBD5E1;">
    Page <span class="pageNumber"></span> of <span class="totalPages"></span>
  </span>
</div>"""

router = APIRouter(prefix="/api/pdf", tags=["pdf"])

_MONEY_RE = re.compile(r'spend|dollar|amount|budget|fee|cost|ytd|capital|expense|salary|rate', re.IGNORECASE)

PDF_PALETTE = [
    '#2563EB', '#16A34A', '#D97706', '#DC2626', '#7C3AED',
    '#0891B2', '#DB2777', '#65A30D', '#EA580C', '#0D9488',
    '#9333EA', '#CA8A04', '#1D4ED8', '#15803D',
]


def _fmt_dollars(val) -> str:
    try:
        v = float(val)
        if abs(v) >= 1_000_000:
            return f"${v/1_000_000:.2f}M"
        if abs(v) >= 1_000:
            return f"${v/1_000:.2f}K"
        return f"${v:,.2f}"
    except Exception:
        return str(val)


def _fmt_number(val) -> str:
    try:
        return f"{float(val):,.2f}"
    except Exception:
        return str(val)


def _pivot(data, x_key, val_key, color_field):
    seen_cats: list[str] = []
    for r in data:
        c = str(r.get(color_field, ''))
        if c not in seen_cats:
            seen_cats.append(c)
    by_x: dict = {}
    all_x: list[str] = []
    for row in data:
        xv = str(row.get(x_key, ''))
        if xv not in by_x:
            by_x[xv] = {}
            all_x.append(xv)
        cat = str(row.get(color_field, ''))
        by_x[xv][cat] = row.get(val_key, 0)
    return all_x, seen_cats, by_x


def _num_keys(row: dict, exclude: list[str]) -> list[str]:
    return [k for k in row if k not in exclude and isinstance(row[k], (int, float))]


def _build_chartjs_config(widget: dict) -> dict | None:
    chart_type = widget.get('chart_type', 'table')
    data = widget.get('data', [])
    x_axis = widget.get('x_axis')
    y_axis = widget.get('y_axis') or []
    color_field = widget.get('color_field')
    stacked = widget.get('stacked', False) or chart_type == 'stacked_bar'
    secondary_y = widget.get('secondary_y')
    bar_color = widget.get('bar_color', None)

    if not data or chart_type in ('table', 'kpi'):
        return None

    x_key = x_axis or list(data[0].keys())[0]
    P = PDF_PALETTE
    is_money = bool(_MONEY_RE.search(' '.join(y_axis)))

    legend_opts = {
        'position': 'bottom',
        'labels': {'font': {'size': 8, 'family': 'Inter, Segoe UI, Arial'}, 'boxWidth': 10, 'padding': 12},
    }
    grid_opts = {
        'x': {'grid': {'display': False}, 'ticks': {'font': {'size': 8}, 'maxRotation': 45, 'minRotation': 0}},
        'y': {'grid': {'color': 'rgba(0,0,0,0.06)'}, 'ticks': {'font': {'size': 8}}},
    }
    base_opts: dict = {
        'responsive': True,
        'maintainAspectRatio': False,
        'plugins': {'legend': legend_opts, 'datalabels': False},
        'scales': grid_opts,
    }

    if chart_type in ('bar', 'stacked_bar', 'horizontal_bar'):
        is_horiz = chart_type == 'horizontal_bar'
        if color_field and any(color_field in r for r in data):
            val_key = (y_axis[0] if y_axis else None) or next(
                (k for k in data[0] if k not in (x_key, color_field) and isinstance(data[0][k], (int, float))), None
            )
            labels, cats, by_x = _pivot(data, x_key, val_key, color_field)
            datasets = [
                {'label': c, 'data': [by_x[x].get(c, 0) for x in labels],
                 'backgroundColor': P[i % len(P)], 'borderRadius': 4}
                for i, c in enumerate(cats)
            ]
        else:
            y_keys = y_axis or _num_keys(data[0], [x_key, 'm_ord'])[:6]
            labels = [str(r.get(x_key, '')) for r in data]
            datasets = [
                {'label': k, 'data': [r.get(k, 0) for r in data],
                 'backgroundColor': (bar_color if bar_color and i == 0 else P[i % len(P)]),
                 'borderRadius': 4}
                for i, k in enumerate(y_keys)
            ]
        opts = json.loads(json.dumps(base_opts))
        opts['scales']['x']['stacked'] = stacked
        opts['scales']['y']['stacked'] = stacked
        label_fmt = None
        if is_horiz:
            opts['indexAxis'] = 'y'
            opts['scales']['x']['grid'] = {'color': 'rgba(0,0,0,0.05)'}
            opts['scales']['y']['grid'] = {'display': False}
            opts['scales']['y']['ticks'] = {'font': {'size': 7}, 'autoSkip': False}
            opts['layout'] = {'padding': {'right': 38}}
            val_unit = (y_axis[0] if y_axis else '').strip()
            label_fmt = 'dollar' if val_unit == '$M' else ('pts' if val_unit == 'pts' else 'pct')
            opts['plugins']['datalabels'] = {
                'anchor': 'end', 'align': 'end', 'offset': 4,
                'font': {'size': 6.5, 'weight': '700'}, 'color': '#374151', 'clip': False,
            }
            for ds in datasets:
                ds['maxBarThickness'] = 11
                ds['borderRadius'] = 2
        return {'type': 'bar', 'data': {'labels': labels, 'datasets': datasets}, 'options': opts, '_money': is_money, '_label_fmt': label_fmt}

    if chart_type == 'line':
        if color_field and any(color_field in r for r in data):
            val_key = (y_axis[0] if y_axis else None) or next(
                (k for k in data[0] if k not in (x_key, color_field) and isinstance(data[0][k], (int, float))), None
            )
            labels, cats, by_x = _pivot(data, x_key, val_key, color_field)
            datasets = [
                {'label': c, 'data': [by_x[x].get(c, 0) for x in labels],
                 'borderColor': P[i % len(P)], 'backgroundColor': P[i % len(P)],
                 'fill': False, 'borderWidth': 1, 'tension': 0.2, 'pointRadius': 0}
                for i, c in enumerate(cats)
            ]
        else:
            y_keys = y_axis or _num_keys(data[0], [x_key, 'm_ord'])[:6]
            labels = [str(r.get(x_key, '')) for r in data]
            datasets = [
                {'label': k, 'data': [r.get(k, 0) for r in data],
                 'borderColor': P[i % len(P)], 'backgroundColor': P[i % len(P)],
                 'fill': False, 'borderWidth': 1, 'tension': 0.2, 'pointRadius': 0}
                for i, k in enumerate(y_keys)
            ]
        line_opts = json.loads(json.dumps(base_opts))
        return {'type': 'line', 'data': {'labels': labels, 'datasets': datasets}, 'options': line_opts, '_money': is_money, '_label_fmt': None}

    if chart_type in ('donut', 'pie'):
        val_key = (y_axis[0] if y_axis else None) or next(
            (k for k in data[0] if isinstance(data[0][k], (int, float))), list(data[0].keys())[-1]
        )
        labels = [str(r.get(x_key, '')) for r in data]
        values = [r.get(val_key, 0) for r in data]
        return {
            'type': 'doughnut' if chart_type == 'donut' else 'pie',
            'data': {'labels': labels, 'datasets': [{'data': values, 'backgroundColor': P[:len(values)], 'hoverOffset': 4}]},
            'options': {
                'responsive': True, 'maintainAspectRatio': False,
                'plugins': {
                    'legend': {'position': 'right', 'labels': {'font': {'size': 13}, 'boxWidth': 14, 'padding': 16}},
                    'datalabels': False,
                },
            },
            '_money': is_money, '_label_fmt': None,
        }

    if chart_type == 'combo':
        y_keys = y_axis or _num_keys(data[0], [x_key, 'm_ord'])[:4]
        bar_keys = [k for k in y_keys if k != secondary_y]
        labels = [str(r.get(x_key, '')) for r in data]
        datasets = [
            {'type': 'bar', 'label': k, 'data': [r.get(k, 0) for r in data],
             'backgroundColor': P[i % len(P)], 'yAxisID': 'y', 'borderRadius': 4}
            for i, k in enumerate(bar_keys)
        ]
        if secondary_y:
            datasets.append({
                'type': 'line', 'label': secondary_y,
                'data': [r.get(secondary_y, 0) for r in data],
                'borderColor': P[len(bar_keys) % len(P)], 'backgroundColor': P[len(bar_keys) % len(P)],
                'fill': False, 'tension': 0.3, 'pointRadius': 3, 'yAxisID': 'y1',
            })
        return {
            'type': 'bar',
            'data': {'labels': labels, 'datasets': datasets},
            'options': {
                'responsive': True, 'maintainAspectRatio': False,
                'plugins': {'legend': legend_opts, 'datalabels': False},
                'scales': {
                    'x': {'grid': {'display': False}, 'ticks': {'font': {'size': 12}, 'maxRotation': 45, 'minRotation': 0}},
                    'y': {'position': 'left', 'grid': {'color': 'rgba(0,0,0,0.06)'}, 'ticks': {'font': {'size': 12}}},
                    'y1': {'position': 'right', 'grid': {'drawOnChartArea': False}, 'ticks': {'font': {'size': 12}}},
                },
            },
            '_money': is_money, '_label_fmt': None,
        }

    return None


def _build_table_html(data: list, max_rows: int = 20, actual_col: str = '', plan_col: str = '', invert_color: bool = False) -> str:
    if not data:
        return ''
    headers = list(data[0].keys())
    num_set = {h for h in headers if isinstance(data[0].get(h), (int, float)) and not isinstance(data[0].get(h), bool)}
    heads = ''.join(
        f'<th style="text-align:right">{h.replace("_", " ")}</th>' if h in num_set
        else f'<th>{h.replace("_", " ")}</th>'
        for h in headers
    )
    body = ''
    for row in data[:max_rows]:
        act_color = ''
        if actual_col and plan_col:
            av, pv = row.get(actual_col), row.get(plan_col)
            if (isinstance(av, (int, float)) and not isinstance(av, bool) and
                    isinstance(pv, (int, float)) and not isinstance(pv, bool)):
                act_color = ('#16A34A' if av < pv else ('#DC2626' if av > pv else '')) if invert_color \
                    else ('#DC2626' if av < pv else ('#16A34A' if av > pv else ''))
        cells = ''
        for h in headers:
            v = row.get(h, '')
            if v is None:
                cells += '<td style="color:#94A3B8">—</td>'
                continue
            hk = h.lower().strip()
            if isinstance(v, (int, float)) and not isinstance(v, bool):
                if hk == '$m' or ' $m' in hk or '($m)' in hk:
                    v = f"${v:.1f}M"
                elif hk == '%' or hk.endswith(' %') or '(%)' in hk:
                    v = f"{v:.1f}%"
                elif hk.endswith(('spend', 'dollars', 'amount', 'budget', 'account')):
                    v = _fmt_dollars(v)
                else:
                    v = _fmt_number(v)
            is_num = h in num_set
            if h == actual_col and act_color:
                s = ('text-align:right;' if is_num else '') + f'color:{act_color}'
                cells += f'<td style="{s}">{v}</td>'
            else:
                cells += f'<td{" style=\"text-align:right\"" if is_num else ""}>{v}</td>'
        body += f'<tr>{cells}</tr>'
    note = f'<p class="truncate-note">Showing top {max_rows} of {len(data)} rows</p>' if len(data) > max_rows else ''
    return f'<div class="data-table"><table><thead><tr>{heads}</tr></thead><tbody>{body}</tbody></table>{note}</div>'


def _build_html(title: str, tab_name: str, widgets: list[dict], date_str: str, include_cover: bool = True) -> str:
    chart_configs: list[dict] = []
    sections = ''

    for idx, w in enumerate(widgets):
        widget_title = w.get('title', '')
        chart_type = w.get('chart_type', 'table')
        data = w.get('data', [])

        # ── multi_panel: 2×2 card grid (colored header + chart + table) ─────────
        if chart_type == 'multi_panel':
            panels = w.get('panels', [])
            cards_html = ''
            for pidx, panel in enumerate(panels):
                pchart_id = f'chart_{idx}_{pidx}'
                pcfg = _build_chartjs_config(panel)
                pchart_html = ''
                if pcfg:
                    chart_configs.append({'id': pchart_id, 'config': pcfg})
                    pchart_html = f'<canvas id="{pchart_id}"></canvas>'
                pkpi   = panel.get('kpi_id', '').replace('-', '_')
                ptitle = panel.get('title', '')
                ptotal = panel.get('total_str', '')
                ptable = _build_table_html(panel.get('table_data') or panel.get('data', []), max_rows=20)
                cards_html += f'''<div class="mpanel-card">
  <div class="mpanel-head {pkpi}">
    <span class="mpanel-title {pkpi}">{ptitle}</span>
    <span class="mpanel-total">{ptotal}</span>
  </div>
  <div class="mpanel-body">
    <div class="mpanel-chart">{pchart_html}</div>
    <div class="mpanel-table">{ptable}</div>
  </div>
</div>'''
            sections += f'''
  <div class="widget-section">
    <div class="widget-header">
      <h2>{widget_title}</h2>
      <span class="badge">Breakdown</span>
    </div>
    <div class="widget-body">
      <div class="mpanel-grid">{cards_html}</div>
    </div>
  </div>'''
            continue

        max_rows     = w.get('max_rows', 20)
        actual_col   = w.get('actual_col', '')
        plan_col     = w.get('plan_col', '')
        invert_color = w.get('invert_actual_color', False)

        cfg = _build_chartjs_config(w)
        chart_id = f'chart_{idx}'
        chart_html = ''
        if cfg:
            chart_configs.append({'id': chart_id, 'config': cfg})
            aspect = 'chart-wide' if chart_type in ('bar', 'stacked_bar', 'line', 'combo', 'horizontal_bar') else 'chart-sq'
            chart_html = f'<div class="chart-wrap {aspect}"><canvas id="{chart_id}"></canvas></div>'

        table_html = _build_table_html(data, max_rows=max_rows, actual_col=actual_col, plan_col=plan_col, invert_color=invert_color)

        subsection = w.get('subsection')
        subsection_html = ''
        if subsection:
            sub_title = subsection.get('title', '')
            sub_table = _build_table_html(subsection.get('data', []), max_rows=10)
            subsection_html = f'''<div class="subsection">
  <div class="subsection-header">{sub_title}</div>
  {sub_table}
</div>'''

        sections += f'''
  <div class="widget-section">
    <div class="widget-header">
      <h2>{widget_title}</h2>
      <span class="badge">{chart_type.replace("_", " ").title()}</span>
    </div>
    <div class="widget-body">
      {chart_html}
      {table_html}
      {subsection_html}
    </div>
  </div>'''

    charts_js = ''
    if chart_configs:
        configs_json = json.dumps(chart_configs, default=str)
        charts_js = f'''<script>
(function() {{
  if (typeof Chart === 'undefined') {{ window.chartsReady = true; return; }}
  if (typeof ChartDataLabels !== 'undefined') {{ Chart.register(ChartDataLabels); }}
  Chart.defaults.font.family = "Inter, Segoe UI, Arial, sans-serif";
  function numFmt(v, money) {{
    var a = Math.abs(v), p = money ? '$' : '';
    if (a >= 1e9) return p + (v/1e9).toFixed(1) + 'B';
    if (a >= 1e6) return p + (v/1e6).toFixed(1) + 'M';
    if (a >= 1e3) return p + Math.round(v/1e3) + 'K';
    if (a > 0 && a < 1)  return p + parseFloat(v.toFixed(2));
    if (a < 10)          return p + parseFloat(v.toFixed(1));
    return p + Math.round(v).toLocaleString();
  }}
  function fmtLabel(v, fmt) {{
    v = parseFloat(v);
    if (fmt === 'dollar') return '$' + v.toFixed(1) + 'M';
    if (fmt === 'pts')    return v.toFixed(2) + ' pts';
    return v.toFixed(1) + '%';
  }}
  var items = {configs_json};
  items.forEach(function(item) {{
    var el = document.getElementById(item.id);
    if (!el) return;
    var money = item.config._money === true;
    var labelFmt = item.config._label_fmt || null;
    var scales = (item.config.options || {{}}).scales || {{}};
    var isHoriz = (item.config.options || {{}}).indexAxis === 'y';
    var valAxis = isHoriz ? scales.x : scales.y;
    if (valAxis) valAxis.ticks = Object.assign(valAxis.ticks || {{}}, {{
      callback: function(v) {{ return numFmt(v, false); }}
    }});
    if (scales.y1) scales.y1.ticks = Object.assign(scales.y1.ticks || {{}}, {{
      callback: function(v) {{ return numFmt(v, false); }}
    }});
    if (isHoriz && labelFmt) {{
      var dl = ((item.config.options || {{}}).plugins || {{}}).datalabels;
      if (dl && typeof dl === 'object') {{
        dl.formatter = function(v) {{ return fmtLabel(v, labelFmt); }};
      }}
    }}
    new Chart(el, item.config);
  }});
  window.chartsReady = true;
}})();
</script>'''

    page_first_rule = '@page :first { margin:0; }' if include_cover else ''
    cover_block = f'''
<div class="cover">
  <div class="cover-rule-top"></div>
  <p class="cover-eyebrow">Executive Report</p>
  <h1>{title}</h1>
  <p class="sub">{tab_name}</p>
  <div class="cover-divider"></div>
  <div class="cover-meta">
    <div class="cover-meta-item"><label>Report Date</label><span>{date_str}</span></div>
    <div class="cover-meta-item"><label>Analysis</label><span>EDA Team</span></div>
  </div>
  <div class="cover-foot">Confidential</div>
</div>''' if include_cover else ''

    return f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0/dist/chartjs-plugin-datalabels.min.js"></script>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:'Inter','Segoe UI',Arial,sans-serif; font-size:10pt; color:#1E293B; background:#fff; }}

/* ── Cover ─────────────────────────────────── */
.cover {{
  page-break-after:always;
  min-height:100vh; display:flex; flex-direction:column; justify-content:center;
  padding:80px 72px; background:#fff; position:relative;
  border-left:6px solid #991B1B;
}}
.cover-rule-top {{ position:absolute; top:0; left:0; right:0; height:3px; background:linear-gradient(90deg,#991B1B,#EF4444,#FCA5A5); }}
.cover-eyebrow {{ font-size:8pt; font-weight:600; letter-spacing:2.5px; text-transform:uppercase; color:#EF4444; margin-bottom:20px; }}
.cover h1 {{ font-size:28pt; font-weight:700; line-height:1.2; color:#0F172A; margin-bottom:10px; }}
.cover .sub {{ font-size:13pt; color:#64748B; margin-bottom:56px; font-weight:300; }}
.cover-divider {{ height:1px; background:#E2E8F0; margin:0 0 40px; }}
.cover-meta {{ display:flex; gap:48px; margin-bottom:auto; }}
.cover-meta-item label {{ display:block; font-size:7.5pt; text-transform:uppercase; letter-spacing:1px; color:#94A3B8; margin-bottom:5px; }}
.cover-meta-item span {{ font-size:10pt; color:#334155; font-weight:500; }}
.cover-foot {{ position:absolute; bottom:48px; right:72px; font-size:7.5pt; color:#CBD5E1; letter-spacing:0.5px; }}

/* ── Content ──────────────────────────────── */
.content {{ padding:0 56px 48px 56px; }}

/* ── Widget ───────────────────────────────── */
.widget-section {{ margin-bottom:44px; border:1px solid #E2E8F0; border-radius:10px; }}
.widget-section + .widget-section {{ page-break-before:always; margin-top:0; }}
.widget-header {{
  background:#FFF5F5; border-bottom:1px solid #FEE2E2;
  border-left:4px solid #991B1B;
  padding:13px 18px; display:flex; align-items:center; justify-content:space-between;
}}
.widget-header h2 {{ font-size:11pt; font-weight:600; color:#0F172A; }}
.badge {{ background:#FFF1F2; color:#991B1B; font-size:7pt; font-weight:600; padding:3px 10px; border-radius:20px; letter-spacing:0.5px; text-transform:uppercase; }}
.widget-body {{ padding:20px 22px; align-items:center; }}

/* ── Charts ───────────────────────────────── */
.chart-wrap {{ margin-bottom:18px; break-inside:avoid; page-break-inside:avoid; }}
.chart-wide {{ width:40%; height:240px; margin-left:50px; }}
.chart-sq   {{ width:32%; height:240px; margin-left:50px; }}
canvas {{ display:block; }}

/* ── Data table ───────────────────────────── */
.data-table {{ border:1px solid #E2E8F0; border-radius:6px; overflow:hidden; }}
table {{ width:100%; border-collapse:collapse; font-size:7.5pt; }}
th {{ background:#F1F5F9; color:#475569; font-weight:600; text-align:left; padding:7px 10px; border-bottom:2px solid #E2E8F0; text-transform:uppercase; font-size:6.5pt; letter-spacing:0.6px; white-space:nowrap; }}
td {{ padding:5px 10px; border-bottom:1px solid #F1F5F9; color:#1E293B; white-space:nowrap; }}
tr:last-child td {{ border-bottom:none; }}
tr:nth-child(even) td {{ background:#F8FAFC; }}
.truncate-note {{ font-size:7pt; color:#94A3B8; margin-top:7px; }}

/* ── Multi-panel 2×2 card grid ───────────────────────── */
.mpanel-grid {{ display:grid; grid-template-columns:1fr 1fr; gap:16px; }}
.mpanel-card {{ border-radius:10px; overflow:hidden; border:1px solid #E2E8F0; break-inside:avoid; page-break-inside:avoid; }}
.mpanel-head {{ padding:9px 14px; display:flex; justify-content:space-between; align-items:center; }}
.mpanel-head.revenue    {{ background:linear-gradient(135deg,#DCFCE7,#F0FDF4); border-bottom:2px solid #16A34A; }}
.mpanel-head.nps        {{ background:linear-gradient(135deg,#DBEAFE,#EFF6FF); border-bottom:2px solid #2563EB; }}
.mpanel-head.efficiency {{ background:linear-gradient(135deg,#FEF3C7,#FFFBEB); border-bottom:2px solid #D97706; }}
.mpanel-head.ai_cost    {{ background:linear-gradient(135deg,#EDE9FE,#F5F3FF); border-bottom:2px solid #7C3AED; }}
.mpanel-title {{ font-size:7.5pt; font-weight:700; text-transform:uppercase; letter-spacing:0.8px; }}
.mpanel-title.revenue    {{ color:#15803D; }}
.mpanel-title.nps        {{ color:#1D4ED8; }}
.mpanel-title.efficiency {{ color:#B45309; }}
.mpanel-title.ai_cost    {{ color:#6D28D9; }}
.mpanel-total {{ font-size:11pt; font-weight:800; color:#0F172A; letter-spacing:-0.3px; }}
.mpanel-body {{ display:flex; padding:10px 12px; gap:12px; background:#fff; }}
.mpanel-chart {{ flex:0 0 56%; height:300px; }}
.mpanel-table {{ flex:1; min-width:0; }}
.mpanel-table .data-table {{ border:none; }}
.mpanel-table table {{ font-size:6pt; width:100%; }}
.mpanel-table th {{ font-size:5.5pt; font-weight:700; padding:2px 5px; color:#64748B; text-transform:uppercase; letter-spacing:0.4px; border-bottom:1px solid #E2E8F0; background:transparent; }}
.mpanel-table td {{ padding:2px 5px; border-bottom:1px solid #F8FAFC; color:#1E293B; }}
.mpanel-table tr:last-child td {{ border-bottom:none; }}
/* ── Subsection (filter focus block) ─────────────────── */
.subsection {{ margin-top:18px; padding-top:16px; border-top:2px dashed #E2E8F0; }}
.subsection-header {{ font-size:9pt; font-weight:700; color:#334155; margin-bottom:10px; padding:6px 12px; background:#F8FAFC; border-radius:6px; border-left:3px solid #6366F1; }}

@page {{ size:letter; margin:{_MARGIN_TOP} 0 {_MARGIN_BOTTOM} 0; }}
{page_first_rule}
</style>
</head>
<body>

{cover_block}

<div class="content">
{sections}
</div>

{charts_js}
</body>
</html>'''


async def _render_html(browser, html: str, has_charts: bool, dest: str, header_footer: bool) -> None:
    page = await browser.new_page(viewport={"width": 1400, "height": 10000}, device_scale_factor=4)
    await page.set_content(html, wait_until="domcontentloaded")
    try:
        await page.wait_for_load_state("networkidle", timeout=15_000)
    except Exception:
        pass
    if has_charts:
        try:
            await page.wait_for_function("window.chartsReady === true", timeout=15_000)
            await page.wait_for_timeout(1500)
        except Exception:
            await page.wait_for_timeout(2_000)
    kwargs: dict = {"path": dest, "format": "Letter", "print_background": True}
    if header_footer:
        kwargs.update({
            "display_header_footer": True,
            "header_template": _header_html(),
            "footer_template": _footer_html(),
            "margin": {"top": _MARGIN_TOP, "bottom": _MARGIN_BOTTOM, "left": "0", "right": "0"},
        })
    await page.pdf(**kwargs)
    await page.close()


@router.post("/export")
async def export_pdf(req: PDFRequest):
    from datetime import date
    from playwright.async_api import async_playwright
    from pypdf import PdfWriter, PdfReader

    date_str = date.today().strftime("%B %d, %Y")
    has_charts = any(
        _build_chartjs_config(w) or any(_build_chartjs_config(p) for p in w.get('panels', []))
        for w in req.widgets
    )

    cover_html   = _build_html(req.title, req.tab_name, [], date_str, include_cover=True)
    content_html = _build_html(req.title, req.tab_name, req.widgets, date_str, include_cover=False)

    tmp_cover   = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False)
    tmp_content = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False)
    tmp_final   = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False)
    tmp_cover.close(); tmp_content.close(); tmp_final.close()

    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(args=["--no-sandbox", "--disable-dev-shm-usage"])
            # Pass 1: cover page — no header/footer, no charts
            await _render_html(browser, cover_html, False, tmp_cover.name, header_footer=False)
            # Pass 2: content pages — header/footer, page counter starts at 1
            await _render_html(browser, content_html, has_charts, tmp_content.name, header_footer=True)
            await browser.close()

        writer = PdfWriter()
        writer.add_page(PdfReader(tmp_cover.name).pages[0])
        for p in PdfReader(tmp_content.name).pages:
            writer.add_page(p)
        with open(tmp_final.name, "wb") as f:
            writer.write(f)
    except Exception as e:
        for path in (tmp_cover.name, tmp_content.name, tmp_final.name):
            try: os.unlink(path)
            except OSError: pass
        raise e
    finally:
        for path in (tmp_cover.name, tmp_content.name):
            try: os.unlink(path)
            except OSError: pass

    return FileResponse(
        tmp_final.name,
        media_type="application/pdf",
        filename=f"{req.tab_name.replace(' ', '_')}_report.pdf",
        background=None,
    )
