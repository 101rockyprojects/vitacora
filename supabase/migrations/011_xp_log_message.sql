-- ============================================================
-- Vitacora — xp_log: mensaje de detalle para el historial de XP
-- ============================================================

ALTER TABLE vitacora.xp_log
  ADD COLUMN IF NOT EXISTS message text;
