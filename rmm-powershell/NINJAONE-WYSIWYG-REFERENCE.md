# NinjaOne WYSIWYG Field Reference

This reference covers the HTML, CSS, and styling capabilities available in NinjaOne WYSIWYG custom fields. WYSIWYG fields are set via `Set-NinjaProperty -Name 'FieldName' -Value $html -Type 'WYSIWYG'` (PowerShell) or `ninjarmm-cli set FieldName "$html"` (CLI).

## Limits and Constraints

- **Maximum characters:** 200,000 per field
- **Auto-collapse threshold:** Fields exceeding 10,000 characters collapse in the NinjaOne UI
- **Maximum fields:** 20 WYSIWYG fields per form/template
- **Styling:** HTML and inline styles only — applied via script/API, not the WYSIWYG editor
- **Sanitiser:** NinjaOne strips any HTML elements, attributes, or CSS properties not on the allowlist below
- **For large content (>10,000 chars):** Use `Ninja-Property-Set-Piped` via CLI to avoid truncation issues

## Allowed HTML Elements

```
<a>  <blockquote>  <caption>  <code>  <col>  <div>
<h1> <h2> <h3> <h4> <h5> <h6>
<i>  <li>  <ol>  <p>  <pre>
<span>  <table>  <tbody>  <td>  <tfoot>  <th>  <thead>  <tr>  <ul>
```

**NOT allowed (silently stripped):** `<img>`, `<script>`, `<style>`, `<iframe>`, `<form>`, `<input>`, `<button>`, `<video>`, `<audio>`, `<canvas>`, `<svg>`, `<br>` — and any other element not listed above.

**Note:** `<code>` and `<pre>` do not support NinjaOne CSS classes — wrap in `<div>` or `<span>` if styling is needed.

## Allowed Inline CSS Properties

Only these CSS properties work in `style=""` attributes. Everything else is silently stripped.

| Category | Properties |
|---|---|
| **Colour** | `color`, `background-color` |
| **Layout** | `display`, `justify-content`, `align-items`, `text-align`, `box-sizing` |
| **Sizing** | `width`, `height`, `font-size` |
| **Spacing** | `margin`, `margin-top`, `margin-right`, `margin-bottom`, `margin-left`, `padding`, `padding-top`, `padding-right`, `padding-bottom`, `padding-left` |
| **Borders** | `border-width`, `border-style`, `border-color`, `border-radius`, `border-collapse`, `border-top`, `border-right`, `border-bottom`, `border-left` |
| **Text** | `word-break`, `white-space`, `overflow-wrap`, `font-family` |

**NOT allowed (silently stripped):** `flex-wrap`, `gap`, `overflow`, `position`, `top`, `left`, `right`, `bottom`, `z-index`, `opacity`, `transform`, `transition`, `animation`, `float`, `clear`, `max-width`, `min-width`, `max-height`, `min-height`, `line-height`, `letter-spacing`, `text-decoration`, `text-transform`, `font-weight`, `font-style`, `list-style`.

### CSS Value Formats

```html
<!-- Colours: hex or RGB -->
style="color: #f015ca; background-color: rgb(240,30,50,0.7);"

<!-- Layout -->
style="display: flex; justify-content: space-between; align-items: center;"

<!-- Sizing: valid CSS units -->
style="width: 100%; height: 400px; font-size: 2em;"

<!-- Font families (limited set) -->
style="font-family: sans-serif;"
<!-- Options: serif, sans-serif, monospace, cursive, fantasy, system-ui, emoji -->

<!-- Borders -->
style="border: 2px solid #ccc; border-radius: 5px; border-collapse: collapse;"
```

## NinjaOne CSS Classes

### Cards

The primary layout component. Use `flex-grow-1` to fill available width.

```powershell
$Card = @"
<div class="card flex-grow-1">
  <div class="card-title-box">
    <div class="card-title"><i class="fas fa-server"></i>&nbsp;&nbsp;Server Status</div>
  </div>
  <div class="card-body">
    <p><b>Status:</b> Online</p>
    <p><b>Uptime:</b> 47 days</p>
  </div>
</div>
"@
```

Card with an action link (external URL icon in the title bar):

```powershell
$CardWithLink = @"
<div class="card flex-grow-1">
  <div class="card-title-box">
    <div class="card-title">Dashboard</div>
    <div class="card-link-box">
      <a href="https://example.com" target="_blank" class="card-link">
        <i class="fas fa-arrow-up-right-from-square"></i>
      </a>
    </div>
  </div>
  <div class="card-body">Content here</div>
</div>
"@
```

### Tables with Status Rows

Table rows support `success`, `danger`, and `warning` classes for colour-coded status:

```powershell
$Table = @"
<table>
  <thead>
    <tr><th>Service</th><th>Status</th></tr>
  </thead>
  <tbody>
    <tr class="success"><td>Web Server</td><td>Running</td></tr>
    <tr class="danger"><td>Database</td><td>Stopped</td></tr>
    <tr class="warning"><td>Mail Relay</td><td>Degraded</td></tr>
  </tbody>
</table>
"@
```

### Info Cards

Colour-coded alert-style cards with icons. Variants: `success`, `error`, `warning`.

```powershell
# Success
$Success = @"
<div class="info-card success">
  <i class="info-icon fa-solid fa-circle-check"></i>
  <div class="info-text">
    <div class="info-title">Success</div>
    <div class="info-description">All checks passed</div>
  </div>
</div>
"@

# Error
$Error = @"
<div class="info-card error">
  <i class="info-icon fa-solid fa-circle-exclamation"></i>
  <div class="info-text">
    <div class="info-title">Error</div>
    <div class="info-description">Service stopped unexpectedly</div>
  </div>
</div>
"@

# Warning
$Warning = @"
<div class="info-card warning">
  <i class="info-icon fa-solid fa-triangle-exclamation"></i>
  <div class="info-text">
    <div class="info-title">Warning</div>
    <div class="info-description">Disk space below 10%</div>
  </div>
</div>
"@
```

### Statistic Cards

Large number display with a description label:

```powershell
$StatCard = @"
<div class="stat-card">
  <div class="stat-value">
    <span style="color: #008001;">25</span>
  </div>
  <div class="stat-desc">
    <span style="font-size: 18px;">Active Users</span>
  </div>
</div>
"@
```

### Buttons

Link-styled buttons. Variants: default (primary), `secondary`, `danger`.

```powershell
$Buttons = @"
<a href="https://example.com" target="_blank" class="btn">Primary</a>
<a href="https://example.com" target="_blank" class="btn secondary">Secondary</a>
<a href="https://example.com" target="_blank" class="btn danger">Danger</a>
"@
```

### Tags / Badges

Inline status badges. Variants: default, `disabled`, `expired`.

```powershell
$Tags = @"
<div class="tag">Enabled</div>
<div class="tag disabled">Disabled</div>
<div class="tag expired">Expired</div>
"@
```

### Proportional Bar (Line Chart)

A simple proportional distribution bar — not a time-series chart. Good for showing licence splits, storage breakdown, etc.

```powershell
$LineChart = @"
<div class="p-3 linechart">
  <div style="width: 33.33%; background-color: #55ACBF;"></div>
  <div style="width: 33.33%; background-color: #3633B7;"></div>
  <div style="width: 33.33%; background-color: #8063BF;"></div>
</div>
<ul class="unstyled p-3" style="display: flex; justify-content: space-between;">
  <li><span class="chart-key" style="background-color: #55ACBF;"></span><span>Licensed (20)</span></li>
  <li><span class="chart-key" style="background-color: #3633B7;"></span><span>Unlicensed (20)</span></li>
  <li><span class="chart-key" style="background-color: #8063BF;"></span><span>Guests (20)</span></li>
</ul>
"@
```

### Utility Classes

```
.d-flex          — display: flex
.flex-grow-1     — flex-grow: 1
.p-3             — padding level 3
.unstyled        — remove list styling (bullets/numbers)
```

## Font Awesome 6 Icons

NinjaOne includes Font Awesome 6. Use `<i class="fas fa-icon-name"></i>` for solid icons.

Common icons for RMM reporting:

```html
<i class="fas fa-server"></i>                 <!-- server -->
<i class="fas fa-desktop"></i>                <!-- workstation -->
<i class="fas fa-database"></i>               <!-- database -->
<i class="fas fa-shield-halved"></i>          <!-- security -->
<i class="fas fa-chart-line"></i>             <!-- chart/metrics -->
<i class="fas fa-circle-check"></i>           <!-- success/pass -->
<i class="fas fa-circle-xmark"></i>           <!-- failure/fail -->
<i class="fas fa-triangle-exclamation"></i>   <!-- warning -->
<i class="fas fa-circle-info"></i>            <!-- information -->
<i class="fas fa-arrow-up-right-from-square"></i>  <!-- external link -->
<i class="fas fa-hard-drive"></i>             <!-- disk/storage -->
<i class="fas fa-memory"></i>                 <!-- RAM -->
<i class="fas fa-microchip"></i>              <!-- CPU/processor -->
<i class="fas fa-network-wired"></i>          <!-- network -->
<i class="fas fa-wifi"></i>                   <!-- wireless -->
<i class="fas fa-user"></i>                   <!-- user -->
<i class="fas fa-users"></i>                  <!-- users/group -->
<i class="fas fa-clock"></i>                  <!-- time/uptime -->
<i class="fas fa-download"></i>               <!-- download/update -->
<i class="fas fa-lock"></i>                   <!-- locked/secure -->
<i class="fas fa-unlock"></i>                 <!-- unlocked/insecure -->
```

## Charts.css Data Visualisation

NinjaOne includes Charts.css for rendering data charts in WYSIWYG fields.

### Bar Chart

```powershell
$BarChart = @"
<table class="charts-css bar show-heading">
  <tbody>
    <tr><td style="--size: 0.75"><span class="data">75%</span></td></tr>
    <tr><td style="--size: 0.4"><span class="data">40%</span></td></tr>
    <tr><td style="--size: 0.6"><span class="data">60%</span></td></tr>
  </tbody>
</table>
"@
```

### Column Chart

```powershell
$ColumnChart = @"
<table class="charts-css column show-heading">
  <tbody>
    <tr><td style="--size: 0.4"><span class="data">40%</span></td></tr>
    <tr><td style="--size: 0.6"><span class="data">60%</span></td></tr>
    <tr><td style="--size: 0.75"><span class="data">75%</span></td></tr>
  </tbody>
</table>
"@
```

### Pie Chart

Must be wrapped in a sized container:

```powershell
$PieChart = @"
<div style="height: 300px; width: 300px;">
  <table class="charts-css pie show-heading">
    <tbody>
      <tr><th scope="row">Online</th><td style="--start: 0; --end: 0.7;"><span class="data">70%</span></td></tr>
      <tr><th scope="row">Offline</th><td style="--start: 0.7; --end: 1.0;"><span class="data">30%</span></td></tr>
    </tbody>
  </table>
</div>
"@
```

### Line Chart (Time-Series)

```powershell
$LineChart = @"
<table class="charts-css line multiple show-data-on-hover show-labels show-primary-axis show-10-secondary-axes show-heading">
  <tbody>
    <tr>
      <th scope="row">Mon</th>
      <td style="--start: 0.1; --end: 0.3;"><span class="data">30%</span></td>
      <td style="--start: 0.6; --end: 0.4;"><span class="data">40%</span></td>
    </tr>
    <tr>
      <th scope="row">Tue</th>
      <td style="--start: 0.3; --end: 0.5;"><span class="data">50%</span></td>
      <td style="--start: 0.4; --end: 0.7;"><span class="data">70%</span></td>
    </tr>
  </tbody>
</table>
<ul class="charts-css legend legend-inline legend-rectangle">
  <li>CPU</li>
  <li>Memory</li>
</ul>
"@
```

### Area Chart

Same syntax as line chart but with `area` class:

```powershell
$AreaChart = @"
<table class="charts-css area show-heading">
  <tbody>
    <tr>
      <th scope="row">Week 1</th>
      <td style="--start: 0.1; --end: 0.3;"><span class="data">30</span></td>
    </tr>
    <tr>
      <th scope="row">Week 2</th>
      <td style="--start: 0.3; --end: 0.5;"><span class="data">50</span></td>
    </tr>
  </tbody>
</table>
"@
```

### Chart Modifiers

Add these classes to `<table>` for additional features:

```
show-heading              — display chart heading
show-data-on-hover        — show data labels on hover only
show-labels               — show row labels (from <th>)
show-primary-axis         — show the primary (baseline) axis
show-10-secondary-axes    — show 10 secondary grid lines
multiple                  — required for multi-series charts
```

## Bootstrap 5 Grid (Optional)

For complex responsive layouts, NinjaOne supports Bootstrap 5's grid system.

### Breakpoints

| Breakpoint | Min Width | Class Prefix |
|---|---|---|
| Extra small (xs) | <576px | `.col-` |
| Small (sm) | ≥576px | `.col-sm-` |
| Medium (md) | ≥768px | `.col-md-` |
| Large (lg) | ≥992px | `.col-lg-` |
| Extra large (xl) | ≥1200px | `.col-xl-` |
| Extra extra large (xxl) | ≥1400px | `.col-xxl-` |

### Grid Examples

```powershell
# Three equal columns
$Grid = @"
<div class="container">
  <div class="row">
    <div class="col">Column 1</div>
    <div class="col">Column 2</div>
    <div class="col">Column 3</div>
  </div>
</div>
"@

# Responsive: stacked on mobile, side-by-side on tablet+
$Responsive = @"
<div class="container">
  <div class="row">
    <div class="col-sm-8">Main content</div>
    <div class="col-sm-4">Sidebar</div>
  </div>
</div>
"@

# Row columns: control items per row
$RowCols = @"
<div class="row row-cols-1 row-cols-sm-2 row-cols-md-4 g-3">
  <div class="col">Item 1</div>
  <div class="col">Item 2</div>
  <div class="col">Item 3</div>
  <div class="col">Item 4</div>
</div>
"@
```

### Grid Utility Classes

```
.justify-content-between   — space items evenly
.justify-content-center    — centre items
.align-items-center        — vertically centre
.align-items-start         — top-align
.g-0 through .g-5          — gap (all sides)
.gx-0 through .gx-5        — horizontal gap
.gy-0 through .gy-5        — vertical gap
```

## Piped Commands for Large Content

For WYSIWYG content exceeding 10,000 characters, pipe via CLI to avoid issues:

```powershell
# PowerShell — pipe to CLI
$Html | & "$env:NINJA_DATA_PATH\ninjarmm-cli.exe" set --stdin FieldName
```

```bash
# bash / zsh — pipe to CLI
echo "$html" | ./ninjarmm-cli set --stdin FieldName
```

## Common WYSIWYG Mistakes

1. **Broken here-string delimiters** — The closing `"@` must start at column 1 with no leading whitespace. This is the most common issue when generating large HTML blocks inside functions or if-blocks.

2. **Using stripped HTML elements** — `<img>`, `<script>`, `<style>`, `<iframe>`, `<br>` are silently removed. Use `<p>` tags for line breaks, `<div>` for containers, and inline `style=""` for all styling.

3. **Using stripped CSS properties** — `flex-wrap`, `gap`, `overflow`, `position`, `float`, `max-width`, `min-width`, `line-height`, `text-decoration`, `font-weight` are all stripped. Use only properties from the allowlist above.

4. **Styling `<code>` or `<pre>` elements** — These don't support NinjaOne CSS classes. Wrap in `<div>` or `<span>` for styling.

5. **Not escaping HTML in dynamic data** — If inserting user-supplied or system-collected data into HTML, escape `<`, `>`, `&`, `"` to prevent broken rendering. Use `[System.Web.HttpUtility]::HtmlEncode($value)` or `[System.Security.SecurityElement]::Escape($value)` in PowerShell.

6. **Exceeding 10,000 chars without piping** — Fields over 10,000 characters auto-collapse and may have issues when set via the PowerShell module. Use `Ninja-Property-Set-Piped` or the CLI `--stdin` flag for large reports.
