-- Consultas seguras (RPCs) para o Dashboard
-- Estas funções devem ser executadas no SQL Editor do Supabase.
-- Elas usam "SECURITY DEFINER" para rodar com privilégios de administrador (bypassing RLS),
-- mas retornam apenas dados agregados, garantindo a segurança e privacidade dos dados individuais.

-- 1. Função para retornar as métricas gerais (Overview)
CREATE OR REPLACE FUNCTION overview_metrics()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'totalUsers', (SELECT count(*) FROM public.users),
    'premiumActive', (SELECT count(*) FROM public.users WHERE subscription_status = 'premium' AND is_active = true),
    'trialsActive', (SELECT count(*) FROM public.users WHERE subscription_status = 'trial' AND is_active = true),
    'churnThisMonth', (SELECT count(*) FROM public.users WHERE subscription_status = 'cancelado')
  ) INTO result;
  
  RETURN result;
END;
$$;

-- Revogar acesso público e garantir apenas para usuários autenticados
REVOKE ALL ON FUNCTION overview_metrics() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION overview_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION overview_metrics() TO service_role;


-- 2. Função para retornar os cadastros por mês (Gráfico)
CREATE OR REPLACE FUNCTION signups_per_month()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_object_agg(month, count)
  INTO result
  FROM (
    SELECT to_char(created_at, 'YYYY-MM') AS month, COUNT(*) AS count
    FROM public.users
    WHERE created_at IS NOT NULL
    GROUP BY to_char(created_at, 'YYYY-MM')
    ORDER BY month
  ) t;
  
  RETURN COALESCE(result, '{}'::json);
END;
$$;

-- Revogar acesso público e garantir apenas para usuários autenticados
REVOKE ALL ON FUNCTION signups_per_month() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION signups_per_month() TO authenticated;
GRANT EXECUTE ON FUNCTION signups_per_month() TO service_role;
