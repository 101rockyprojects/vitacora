-- ============================================================
-- Vitacora — Subscriptions dedupe (una suscripción activa por nombre y usuario)
-- ============================================================

DELETE FROM vitacora.subscriptions a
USING vitacora.subscriptions b
WHERE
  a.user_id = b.user_id
  AND lower(btrim(a.name)) = lower(btrim(b.name))
  AND (
    a.created_at > b.created_at
    OR (a.created_at = b.created_at AND a.id > b.id)
  );

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_user_name_uniq
  ON vitacora.subscriptions (user_id, lower(btrim(name)));
