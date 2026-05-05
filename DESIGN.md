# Vitacora - Design System

## Core Libraries
- **Flowbite-Svelte** - UI component library (Modal, Card, Button, Forms, etc.)
- **ApexCharts** - Charts via `@flowbite-svelte-plugins/chart`
- **Gridstack** - Memory album drag-and-drop grid

## Color Palette
Using dark theme as primary:

```css
/* Backgrounds */
--bg: #0f1117         /* Main background */
--bg2: #161b25        /* Card/container background */
--bg3: #1e2535        /* Input/hover background */
--surface: #242b3d    /* Elevated surfaces */
--surface2: #2e3650   /* Active/selected states */
--border: #333d57     /* Borders */

/* Text */
--text: #e8eaf0       /* Primary text */
--text2: #9aa3bd      /* Secondary text */
--text3: #636d8a      /* Muted/placeholder */

/* Accents */
--accent-green: #73e7bd   /* Success, primary actions */
--accent-yellow: #ebd57f  /* Warnings, highlights */
--accent-orange: #ee9863  /* Pending, todos */
--accent-blue: #5d99ee    /* Events, info */
--accent-purple: #9294f5  /* Special tags */
--accent-red: #ee8888     /* Errors, delete */
```

## Typography
- **Display**: Syne (headings, hero text)
- **Body**: DM Sans (general text)
- **Mono**: Space Mono (code, stats, dates)

```css
font-family: var(--font-display);  /* Syne */
font-family: var(--font-body);    /* DM Sans */
font-family: var(--font-mono);     /* Space Mono */
```

## Spacing & Sizing
```css
--radius: 10px;       /* Small elements */
--radius-lg: 16px;    /* Cards, modals */
--sidebar-width: 240px;
--transition: 0.18s ease;
```

## Component Usage

### Card (Custom)
```svelte
<div class="card">
  <!-- Content -->
</div>
```

### Modal
```svelte
<div class="modal-backdrop" onclick={closeOnBackdrop}>
  <div class="modal">
    <h3>Title</h3>
    <!-- Form content -->
    <div class="form-actions">
      <button class="btn btn-secondary">Cancel</button>
      <button class="btn btn-primary">Save</button>
    </div>
  </div>
</div>
```

### Buttons
```svelte
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-danger">Danger</button>
<button class="small-btn">Small</button>
```

### Form Elements
```svelte
<div class="form-group">
  <label>Label</label>
  <input type="text" bind:value={value} />
</div>

<select bind:value={selected}>
  <option value="a">Option A</option>
</select>

<textarea rows="3"></textarea>
```

### Progress Bar
```svelte
<div class="progress-track">
  <div class="progress-fill" style="width: {percent}%"></div>
</div>
```

### Tags
```svelte
<span class="tag">Tag text</span>
```

### Grid Layouts
```css
/* 2 columns */
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

/* Auto-fill cards */
.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}
```

## Flowbite Components Available

### Navigation
- Tabs (horizontal tabs bar)
- Breadcrumb
- Pagination

### Forms
- Button, Button Group
- Input Field, Textarea, Select
- Checkbox, Radio, Toggle
- Range Slider
- Datepicker

### Data Display
- Card
- Table
- Progress Bar
- Avatar
- Badge
- Tooltip
- Popover

### Feedback
- Modal
- Alert
- Toast
- Spinner, Skeleton

### Layout
- Accordion
- Drawer (Sidebar)
- Mega Menu

## Chart Component (PieChart.svelte)

```svelte
<script>
  import PieChart from '$lib/components/PieChart.svelte';
</script>

<!-- Bar chart (dashboard) -->
<PieChart data={expenseData} type="bar" />

<!-- Pie chart (expenses) -->
<PieChart data={categoryData} type="pie" title="Gastos por categoría" />
```

**Props:**
- `data: ExpenseCategory[]` - Array of { name, total, percentage }
- `type: 'bar' | 'pie'` - Chart type
- `title?: string` - Optional title

## Responsive Breakpoints

```css
/* Desktop */
@media (max-width: 900px) {
  /* Tablet */
  .dash-grid { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 640px) {
  /* Mobile */
  .dash-grid { grid-template-columns: 1fr; }
}
```

## Best Practices

1. **Always use semantic HTML** - `<button>` for actions, `<a>` for links, `<label>` for inputs
2. **Accessibility** - Add `aria-label`, `aria-expanded`, keyboard handlers for custom interactions
3. **CSS Variables** - Use existing variables instead of hardcoding colors
4. **Svelte 5 Runes** - Use `$state`, `$derived`, `$effect` for reactivity
5. **Repository Pattern** - Access data through `repo` object from `$lib/services/repository.ts`
6. **TypeScript** - Define types in `$lib/types/index.ts`
7. **No external UI libraries** - Use Flowbite-Svelte components or custom CSS

## Icons
Currently using emoji for simplicity. Consider adding `flowbite-svelte-icons` for proper icons.