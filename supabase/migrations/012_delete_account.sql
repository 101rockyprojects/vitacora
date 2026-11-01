CREATE OR REPLACE FUNCTION vitacora.delete_my_account()
RETURNS VOID AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

REVOKE EXECUTE ON FUNCTION vitacora.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION vitacora.delete_my_account() TO authenticated;
