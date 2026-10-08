-- SUBSTITUA o e-mail entre aspas pelo email REAL do usuário que você já criou
-- em Supabase > Authentication > Users (não informe senha aqui).
-- Necessário UMA vez, após 01_migracao.sql.
INSERT INTO public.equipe (id,nome,perfil,ativo)
SELECT id, COALESCE(raw_user_meta_data->>'full_name', email), 'admin', true
FROM auth.users WHERE lower(email) = lower('COLOQUE_SEU_EMAIL_AQUI')
ON CONFLICT (id) DO UPDATE SET perfil='admin',ativo=true;
-- Confirme que retornou 1 linha; se for 0, o e-mail não existe no Auth.
SELECT id,nome,perfil,ativo FROM public.equipe;
