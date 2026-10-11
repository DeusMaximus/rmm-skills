# NinjaOne WYSIWYG Fields

Read this file when a script writes HTML into a NinjaOne WYSIWYG custom field. It defines what NinjaOne renders. How to write the field from a script (cmdlet or CLI syntax, piping large content, HTML-encoding values) is in the platform's NINJAONE-CUSTOM-FIELDS.md.

This file is shared and identical in all three skills. The canonical copy is in the rmm-powershell folder. All examples are plain HTML, so build them with your platform's normal string handling.

## Limits

- Maximum 200,000 characters per field.
- Fields over 10,000 characters are collapsed in the NinjaOne UI. For content this large, write the field by piping to the CLI (see NINJAONE-CUSTOM-FIELDS.md).
- Maximum 20 WYSIWYG fields per form or template.
- Styling must use HTML and inline style attributes written by a script or the API. The WYSIWYG editor in the UI does not provide it.
- NinjaOne sanitises the HTML. Elements, attributes and CSS properties outside the allowlists below are removed silently, with no error.
- Like every custom field, WYSIWYG fields can only be written when the script runs as SYSTEM or root.

## Allowed HTML Elements

```text
a  blockquote  caption  code  col  div
h1  h2  h3  h4  h5  h6
i  li  ol  p  pre
span  table  tbody  td  tfoot  th  thead  tr  ul
```

Removed silently: img, script, style, iframe, form, input, button, video, audio, canvas, svg and br, as well as any element not listed above.

- Use p elements for line breaks and div elements for containers.
- NinjaOne CSS classes do not apply to code and pre elements. Wrap them in a div or span to style them.
- The card examples below use b for bold labels. The b element is not on the published allowlist, so check that it renders in your tenant before relying on it.

## Allowed Inline CSS Properties

Only these properties survive inside a style attribute.

```text
Colour    color, background-color
Layout    display, justify-content, align-items, text-align, box-sizing
Sizing    width, height, font-size
Spacing   margin, margin-top, margin-right, margin-bottom, margin-left,
          padding, padding-top, padding-right, padding-bottom, padding-left
Borders   border-width, border-style, border-color, border-radius, border-collapse,
          border-top, border-right, border-bottom, border-left
Text      word-break, white-space, overflow-wrap, font-family
```

Removed silently: flex-wrap, gap, overflow, position, top, left, right, bottom, z-index, opacity, transform, transition, animation, float, clear, max-width, min-width, max-height, min-height, line-height, letter-spacing, text-decoration, text-transform, font-weight, font-style and list-style.

Font families are limited to serif, sans-serif, monospace, cursive, fantasy, system-ui and emoji.

```html
<div style="display: flex; justify-content: space-between; align-items: center;">
  <span style="color: #f015ca; font-size: 2em;">Hex colour</span>
  <span style="background-color: rgb(240, 30, 50, 0.7); font-family: monospace;">RGB colour</span>
</div>
<div style="width: 100%; border: 2px solid #ccc; border-radius: 5px; padding: 8px;">Bordered box</div>
```

## Dynamic Values

Encode every value collected from the system or supplied by a user before inserting it into HTML, so that characters such as less-than, greater-than, ampersand and double quote cannot break the markup. The encoding function for each language is in NINJAONE-CUSTOM-FIELDS.md.

## NinjaOne CSS Classes

### Card

The main layout component. Add flex-grow-1 to fill the available width.

```html
<div class="card flex-grow-1">
  <div class="card-title-box">
    <div class="card-title"><i class="fas fa-server"></i>&nbsp;&nbsp;Server Status</div>
  </div>
  <div class="card-body">
    <p><b>Status:</b> Online</p>
    <p><b>Uptime:</b> 47 days</p>
  </div>
</div>
```

### Card With a Title-Bar Link

```html
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
```

### Table With Status Rows

Table rows accept the success, danger and warning classes.

```html
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
```

### Info Card

An alert-style card. The variants are success, error and warning.

```html
<div class="info-card success">
  <i class="info-icon fa-solid fa-circle-check"></i>
  <div class="info-text">
    <div class="info-title">Success</div>
    <div class="info-description">All checks passed</div>
  </div>
</div>

<div class="info-card error">
  <i class="info-icon fa-solid fa-circle-exclamation"></i>
  <div class="info-text">
    <div class="info-title">Error</div>
    <div class="info-description">Service stopped unexpectedly</div>
  </div>
</div>

<div class="info-card warning">
  <i class="info-icon fa-solid fa-triangle-exclamation"></i>
  <div class="info-text">
    <div class="info-title">Warning</div>
    <div class="info-description">Disk space below 10%</div>
  </div>
</div>
```

### Statistic Card

```html
<div class="stat-card">
  <div class="stat-value">
    <span style="color: #008001;">25</span>
  </div>
  <div class="stat-desc">
    <span style="font-size: 18px;">Active Users</span>
  </div>
</div>
```

### Buttons

Link-styled buttons. The variants are the default (primary), secondary and danger.

```html
<a href="https://example.com" target="_blank" class="btn">Primary</a>
<a href="https://example.com" target="_blank" class="btn secondary">Secondary</a>
<a href="https://example.com" target="_blank" class="btn danger">Danger</a>
```

### Tags and Badges

The variants are the default, disabled and expired.

```html
<div class="tag">Enabled</div>
<div class="tag disabled">Disabled</div>
<div class="tag expired">Expired</div>
```

### Proportional Bar

A single bar split into proportional segments, such as a licence split or storage breakdown. It is not a time series.

```html
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
```

### Utility Classes

```text
d-flex         display: flex
flex-grow-1    flex-grow: 1
p-3            padding level 3
unstyled       removes list bullets and numbering
```

## Font Awesome 6 Icons

NinjaOne includes Font Awesome 6. Use the fas class for solid icons.

```html
<i class="fas fa-server"></i>
<i class="fas fa-desktop"></i>
<i class="fas fa-database"></i>
<i class="fas fa-shield-halved"></i>
<i class="fas fa-chart-line"></i>
<i class="fas fa-circle-check"></i>
<i class="fas fa-circle-xmark"></i>
<i class="fas fa-triangle-exclamation"></i>
<i class="fas fa-circle-info"></i>
<i class="fas fa-arrow-up-right-from-square"></i>
<i class="fas fa-hard-drive"></i>
<i class="fas fa-memory"></i>
<i class="fas fa-microchip"></i>
<i class="fas fa-network-wired"></i>
<i class="fas fa-wifi"></i>
<i class="fas fa-user"></i>
<i class="fas fa-users"></i>
<i class="fas fa-clock"></i>
<i class="fas fa-download"></i>
<i class="fas fa-lock"></i>
<i class="fas fa-unlock"></i>
```

## Charts.css

NinjaOne includes Charts.css. A chart is a table with the charts-css class plus a chart-type class. The size of each value is set with the custom properties in the style attribute, as fractions from 0 to 1.

### Bar and Column Charts

Use bar for horizontal bars or column for vertical columns. The markup is otherwise identical.

```html
<table class="charts-css bar show-heading">
  <tbody>
    <tr><td style="--size: 0.75"><span class="data">75%</span></td></tr>
    <tr><td style="--size: 0.4"><span class="data">40%</span></td></tr>
    <tr><td style="--size: 0.6"><span class="data">60%</span></td></tr>
  </tbody>
</table>
```

### Pie Chart

A pie chart must be inside a container with a fixed size.

```html
<div style="height: 300px; width: 300px;">
  <table class="charts-css pie show-heading">
    <tbody>
      <tr><th scope="row">Online</th><td style="--start: 0; --end: 0.7;"><span class="data">70%</span></td></tr>
      <tr><th scope="row">Offline</th><td style="--start: 0.7; --end: 1.0;"><span class="data">30%</span></td></tr>
    </tbody>
  </table>
</div>
```

### Line and Area Charts

Use line or area for a time series. Add multiple when there is more than one data series.

```html
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
```

### Chart Modifier Classes

```text
show-heading             display the chart heading
show-data-on-hover       show data labels only on hover
show-labels              show row labels taken from th elements
show-primary-axis        show the baseline axis
show-10-secondary-axes   show ten secondary grid lines
multiple                 required for charts with more than one series
```

## Bootstrap 5 Grid

NinjaOne supports the Bootstrap 5 grid for more complex layouts.

```text
Breakpoint   Minimum width   Column class prefix
xs           below 576px     col-
sm           576px           col-sm-
md           768px           col-md-
lg           992px           col-lg-
xl           1200px          col-xl-
xxl          1400px          col-xxl-
```

```html
<div class="container">
  <div class="row">
    <div class="col">Column 1</div>
    <div class="col">Column 2</div>
    <div class="col">Column 3</div>
  </div>
</div>

<div class="container">
  <div class="row">
    <div class="col-sm-8">Main content (stacked on narrow screens)</div>
    <div class="col-sm-4">Sidebar</div>
  </div>
</div>

<div class="row row-cols-1 row-cols-sm-2 row-cols-md-4 g-3">
  <div class="col">Item 1</div>
  <div class="col">Item 2</div>
  <div class="col">Item 3</div>
  <div class="col">Item 4</div>
</div>
```

```text
justify-content-between   spread items across the row
justify-content-center    centre items
align-items-center        centre vertically
align-items-start         align to the top
g-0 to g-5                gap on all sides
gx-0 to gx-5              horizontal gap
gy-0 to gy-5              vertical gap
```

## Common Mistakes

1. Using removed elements such as img, br or style. They disappear without an error. Use p for line breaks, div for containers, and inline style attributes for styling.
2. Using removed CSS properties such as gap, flex-wrap, overflow, position, max-width, line-height or font-weight. Use only the properties on the allowlist.
3. Styling code or pre elements directly. Wrap them in a div or span.
4. Inserting dynamic values without HTML-encoding them, which breaks the layout when a value contains markup characters.
5. Writing large reports without piping them to the CLI. Above 10,000 characters, use the piped method in NINJAONE-CUSTOM-FIELDS.md.
