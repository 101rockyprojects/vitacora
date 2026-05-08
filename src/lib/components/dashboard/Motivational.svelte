<script lang="ts">
</script>

<div class="card motive-card">
  <div class="motive-glyph">⊶</div>
  <blockquote class="motive-quote">
    "1% better every day"
    <br> <br>
    
    "DO NOT WASTE YOUR POTENTIAL"
    
    <br> <br>
    "¡Commit yourself!"
  </blockquote>
  <div class="motive-links">
    <a href="/goals" class="motive-link">Visión →</a>
    <a href="/projects" class="motive-link">Kanban →</a>
    <a href="/goals?tab=calendar" class="motive-link">Calendario →</a>
  </div>
</div>

<style>
  .motive-card {
    background: linear-gradient(135deg, rgba(168,230,207,0.08), rgba(255,217,61,0.04));
    border-color: rgba(168,230,207,0.25);
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
    min-height: 180px;
  }

  .motive-card {
    grid-column: span 1;
  }

  .motive-glyph {
    font-size: 32px;
    color: var(--accent-green);
    margin-bottom: 12px;
  }

  .motive-quote {
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 700;
    color: var(--text);
    font-style: italic;
    margin-bottom: 16px;
    line-height: 1.4;
  }

  .motive-links {
    display: flex;
    gap: 12px;
  }

  .motive-link {
    font-size: 13px;
    color: var(--accent-green);
    font-family: var(--font-mono);
    transition: opacity var(--transition);
  }

  .motive-link:hover { opacity: 0.7; }
</style>