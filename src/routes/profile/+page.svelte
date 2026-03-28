<script lang="ts">
  import { page } from '$app/stores';
  import { createRepository } from '$lib/services/repository';
  import { levelFromXp, getAreaXP, AREAS, PREDEFINED_BADGES } from '$lib/utils/xp';
  import type { UserBadge } from '$lib/types';
  import html2canvas from 'html2canvas';

  const userId = $derived($page.data.user?.id ?? '');
  const userEmail = $derived($page.data.user?.email ?? '');
  const repo = $derived(createRepository(userId));
  let initialized = $state(false);
  let areaXP: Record<string, number> = $state({});
  let userBadges = $state<UserBadge[]>([]);
  let xpLog = $state<any[]>([]);
  let loading = $state(true);
  let sharing = $state(false);

  let totalXP = $derived(Object.values(areaXP).reduce((a, b) => a + b, 0));
  let globalLevel = $derived(levelFromXp(totalXP));

  // Stats for badge checking
  let stats = $state({ books_finished: 0, successes: 0, tasks_done: 0, projects: 0, memories: 0, learning: 0 });

  $effect(() => {
    if (userId && !initialized) {
      initialized = true;
      void loadAll();
    }
  });

  async function loadAll() {
    const [xpRes, badgesRes, logRes, booksRes, successRes, tasksRes, projectsRes, memoriesRes, learnRes] = await Promise.all([
      Promise.resolve(await getAreaXP(userId)),
      repo.userBadges.list(),
      repo.xp.listLogs(),
      repo.books.listProgress(),
      repo.successes.listDoneIds(),
      repo.tasks.listDoneIds(),
      repo.projects.listIds(),
      repo.memories.listIds(),
      repo.learning.listIds()
    ]);

    areaXP = xpRes;
    userBadges = badgesRes.data || [];
    xpLog = logRes.data || [];

    const books = booksRes.data || [];
    stats = {
      books_finished: books.filter(b => b.current_page >= b.total_pages && b.total_pages > 0).length,
      successes: successRes.data?.length || 0,
      tasks_done: tasksRes.data?.length || 0,
      projects: projectsRes.data?.length || 0,
      memories: memoriesRes.data?.length || 0,
      learning: learnRes.data?.length || 0
    };

    // Check and award badges
    await checkBadges();
    loading = false;
  }

  async function checkBadges() {
    const earnedIds = userBadges.map(ub => ub.badge_id);

    // Ensure badges exist in DB
    const { data: existingBadges } = await repo.badges.list();
    const existingNames = (existingBadges || []).map((b: any) => b.name);

    for (const badge of PREDEFINED_BADGES) {
      if (!existingNames.includes(badge.name)) {
        await repo.badges.insert(badge);
      }
    }

    const { data: allBadges } = await repo.badges.list();
    if (!allBadges) return;

    const globalLvl = levelFromXp(totalXP).level;

    for (const badge of allBadges) {
      if (earnedIds.includes(badge.id)) continue;

      let earned = false;
      const val = badge.condition_value;

      switch (badge.condition_type) {
        case 'books_finished': earned = stats.books_finished >= val; break;
        case 'successes': earned = stats.successes >= val; break;
        case 'tasks_done': earned = stats.tasks_done >= val; break;
        case 'projects': earned = stats.projects >= val; break;
        case 'global_level': earned = globalLvl >= val; break;
        case 'memories': earned = stats.memories >= val; break;
        case 'learning': earned = stats.learning >= val; break;
      }

      if (earned) {
        await repo.userBadges.insert({ badge_id: badge.id });
      }
    }

    const { data: updatedBadges } = await repo.userBadges.list();
    userBadges = updatedBadges || [];
  }

  function areaColor(key: string) {
    return AREAS.find(a => a.key === key)?.color || 'var(--text3)';
  }

  function areaLabel(key: string) {
    return AREAS.find(a => a.key === key)?.label || key;
  }

  function areaIcon(key: string) {
    return AREAS.find(a => a.key === key)?.icon || '●';
  }

  function formatDate(d: string) {
    return new Date(d).toLocaleDateString('es-ES', { day: 'numeric', month: 'short' });
  }

  async function shareAsImage() {
    sharing = true;
    try {
      const node = document.getElementById('share-card');
      if (!node) return;
      
      const canvas = await html2canvas(node, {
        scale: 2,
        backgroundColor: '#ffffff',
        useCORS: true,
        logging: false,
        // Configuración para fuentes
        allowTaint: false,
        foreignObjectRendering: false
      });
      
      const dataUrl = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.download = 'lumina-progress.png';
      link.href = dataUrl;
      link.click();
    } catch (e) {
      console.error('Share error:', e);
    } finally {
      sharing = false;
    }
  }

  const earnedBadgeIds = $derived(userBadges.map(ub => ub.badge_id));
</script>

<div class="profile-page fade-in">
  <div class="section-header">
    <div>
      <h2 class="section-title">Perfil & XP</h2>
      <div class="section-subtitle">Tu progreso gamificado</div>
    </div>
    <button class="btn btn-secondary" onclick={shareAsImage} disabled={sharing}>
      {sharing ? '...' : 'Exportar progreso'}
    </button>
  </div>

  {#if loading}
    <div class="loading-state">Cargando tu progreso...</div>
  {:else}
    <!-- Shareable card -->
    <div id="share-card" class="share-card">
      <div class="share-header">
        <div class="share-avatar">{userEmail[0]?.toUpperCase()}</div>
        <div>
          <div class="share-email">{userEmail}</div>
          <div class="share-level-text">Nivel global {globalLevel.level}</div>
        </div>
        <div class="share-total-xp">
          <span class="share-xp-num">{totalXP}</span>
          <span class="share-xp-label">XP</span>
        </div>
      </div>

      <!-- Global XP bar -->
      <div class="global-bar">
        <div class="global-bar-label">
          <span>Nivel {globalLevel.level}</span>
          <span>{globalLevel.progress} / {globalLevel.nextLevelXp} XP → Nivel {globalLevel.level + 1}</span>
        </div>
        <div class="progress-track" style="height:10px;">
          <div class="progress-fill xp-glow"
            style="width:{(globalLevel.progress/globalLevel.nextLevelXp)*100}%;background:var(--accent-green);">
          </div>
        </div>
      </div>

      <!-- Area XP bars -->
      <div class="area-grid">
        {#each AREAS as area}
          {@const xp = areaXP[area.key] || 0}
          {@const lvl = levelFromXp(xp)}
          <div class="area-card">
            <div class="area-card-top">
              <span class="area-card-icon">{area.icon}</span>
              <span class="area-card-name">{area.label}</span>
              <span class="area-card-lv" style="color:{area.color}">Lv.{lvl.level}</span>
            </div>
            <div class="progress-track" style="margin:8px 0 4px;">
              <div class="progress-fill" style="width:{(lvl.progress/lvl.nextLevelXp)*100}%;background:{area.color};"></div>
            </div>
            <div class="area-card-xp">{xp} XP total</div>
          </div>
        {/each}
      </div>
    </div>

    <!-- Badges -->
    <div class="badges-section">
      <h3 class="badges-title">Logros & Medallas</h3>
      <div class="badges-grid">
        {#each PREDEFINED_BADGES as badge}
          {@const earned = userBadges.some(ub => (ub.badge as any)?.name === badge.name)}
          <div class="badge-card" class:earned>
            <div class="badge-icon" class:earned>{badge.icon}</div>
            <div class="badge-name">{badge.name}</div>
            <div class="badge-desc">{badge.description}</div>
            {#if earned}
              <div class="badge-earned-tag">✓ Conseguido</div>
            {:else}
              <div class="badge-locked-tag">🔒 Bloqueado</div>
            {/if}
          </div>
        {/each}
      </div>
    </div>

    <!-- XP Activity log -->
    <div class="activity-section">
      <h3 class="activity-title">Actividad reciente</h3>
      <div class="activity-list">
        {#each xpLog as log}
          <div class="activity-item">
            <span class="activity-dot" style="background:{areaColor(log.area)}"></span>
            <span class="activity-source">{log.source_type.replace(/_/g, ' ')}</span>
            <span class="activity-area">{areaIcon(log.area)} {areaLabel(log.area)}</span>
            <span class="activity-xp">+{log.xp_gained} XP</span>
            <span class="activity-date">{formatDate(log.date)}</span>
          </div>
        {/each}
        {#if xpLog.length === 0}
          <div class="empty-state">Completa tareas para ganar XP ⚡</div>
        {/if}
      </div>
    </div>

    <!-- Stats overview -->
    <div class="stats-overview">
      <h3 class="stats-title">Estadísticas</h3>
      <div class="stats-boxes">
        <div class="stat-box">
          <span class="stat-box-num">{stats.books_finished}</span>
          <span class="stat-box-label">📚 Libros terminados</span>
        </div>
        <div class="stat-box">
          <span class="stat-box-num">{stats.tasks_done}</span>
          <span class="stat-box-label">✅ Tareas completadas</span>
        </div>
        <div class="stat-box">
          <span class="stat-box-num">{stats.successes}</span>
          <span class="stat-box-label">🏆 Metas logradas</span>
        </div>
        <div class="stat-box">
          <span class="stat-box-num">{stats.projects}</span>
          <span class="stat-box-label">🚀 Proyectos</span>
        </div>
        <div class="stat-box">
          <span class="stat-box-num">{stats.memories}</span>
          <span class="stat-box-label">📸 Memorias</span>
        </div>
        <div class="stat-box">
          <span class="stat-box-num">{stats.learning}</span>
          <span class="stat-box-label">🧠 Temas aprendidos</span>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .profile-page { max-width: 1000px; }

  .loading-state {
    color: var(--text3);
    font-family: var(--font-mono);
    font-size: 13px;
    text-align: center;
    padding: 60px;
  }

  /* Share card */
  .share-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 24px;
    margin-bottom: 28px;
  }

  .share-header {
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 20px;
    flex-wrap: wrap;
  }

  .share-avatar {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    background: var(--accent-green);
    color: #0a1a0f;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    font-weight: 800;
    flex-shrink: 0;
  }

  .share-email { font-size: 14px; font-weight: 600; color: var(--text); }
  .share-level-text { font-size: 12px; color: var(--text3); font-family: var(--font-mono); margin-top: 2px; }

  .share-total-xp {
    margin-left: auto;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
  }

  .share-xp-num {
    font-family: var(--font-display);
    font-size: 32px;
    font-weight: 800;
    color: var(--accent-green);
    line-height: 1;
  }

  .share-xp-label {
    font-size: 12px;
    color: var(--text3);
    font-family: var(--font-mono);
    text-transform: uppercase;
  }

  .global-bar { margin-bottom: 20px; }

  .global-bar-label {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    color: var(--text2);
    font-family: var(--font-mono);
    margin-bottom: 8px;
  }

  .area-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
  }

  .area-card {
    background: var(--bg3);
    border-radius: var(--radius);
    padding: 14px;
  }

  .area-card-top {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 4px;
  }

  .area-card-icon { font-size: 16px; }

  .area-card-name {
    flex: 1;
    font-size: 12px;
    font-weight: 600;
    color: var(--text2);
  }

  .area-card-lv {
    font-size: 11px;
    font-family: var(--font-mono);
    font-weight: 700;
  }

  .area-card-xp {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  /* Badges */
  .badges-section { margin-bottom: 28px; }

  .badges-title {
    font-size: 16px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 16px;
    font-family: var(--font-display);
  }

  .badges-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 12px;
  }

  .badge-card {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    text-align: center;
    transition: all var(--transition);
    filter: grayscale(1);
    opacity: 0.5;
  }

  .badge-card.earned {
    filter: none;
    opacity: 1;
    border-color: rgba(168,230,207,0.3);
    background: var(--surface);
  }

  .badge-card.earned:hover { transform: translateY(-2px); }

  .badge-icon {
    font-size: 32px;
    margin-bottom: 8px;
    display: block;
  }

  .badge-name {
    font-size: 13px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 4px;
  }

  .badge-desc {
    font-size: 11px;
    color: var(--text3);
    margin-bottom: 8px;
    line-height: 1.4;
  }

  .badge-earned-tag {
    font-size: 11px;
    color: var(--accent-green);
    font-family: var(--font-mono);
    font-weight: 700;
  }

  .badge-locked-tag {
    font-size: 11px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  /* Activity */
  .activity-section { margin-bottom: 28px; }

  .activity-title {
    font-size: 16px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 14px;
    font-family: var(--font-display);
  }

  .activity-list {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    overflow: hidden;
  }

  .activity-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    font-size: 13px;
    border-bottom: 1px solid var(--border);
    transition: background var(--transition);
  }

  .activity-item:last-child { border-bottom: none; }
  .activity-item:hover { background: var(--bg3); }

  .activity-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .activity-source { flex: 1; color: var(--text2); text-transform: capitalize; }
  .activity-area { color: var(--text3); font-size: 12px; }
  .activity-xp { color: var(--accent-green); font-family: var(--font-mono); font-weight: 700; font-size: 12px; }
  .activity-date { color: var(--text3); font-family: var(--font-mono); font-size: 11px; }

  /* Stats */
  .stats-overview { }

  .stats-title {
    font-size: 16px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 14px;
    font-family: var(--font-display);
  }

  .stats-boxes {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 12px;
  }

  .stat-box {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 6px;
    text-align: center;
    transition: transform var(--transition);
  }

  .stat-box:hover { transform: translateY(-2px); }

  .stat-box-num {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 800;
    color: var(--accent-green);
    line-height: 1;
  }

  .stat-box-label {
    font-size: 12px;
    color: var(--text3);
    font-family: var(--font-mono);
  }

  .empty-state {
    color: var(--text3);
    font-size: 13px;
    text-align: center;
    padding: 24px;
    font-family: var(--font-mono);
  }

  @media (max-width: 900px) {
    .area-grid { grid-template-columns: 1fr 1fr; }
  }
</style>
