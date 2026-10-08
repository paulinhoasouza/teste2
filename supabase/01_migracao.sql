-- ZETTA | Migração para Supabase já criado nas etapas do Streamlit
-- Execute UMA VEZ no SQL Editor do MESMO projeto. Não apaga clientes/solicitações/propostas existentes.
-- ATENÇÃO: após a migração, o acesso é reservado aos usuários inseridos na tabela equipe.
-- O primeiro admin é configurado com o comando documentado no README.

CREATE TABLE IF NOT EXISTS public.clientes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), nome text NOT NULL,
 documento text, email text, telefone text, contato text, observacoes text,
 criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.solicitacoes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 cliente_id uuid NOT NULL REFERENCES public.clientes(id),
 titulo text NOT NULL, descricao text,
 prioridade text NOT NULL DEFAULT 'Media' CHECK (prioridade IN ('Baixa','Media','Alta','Critica')),
 status text NOT NULL DEFAULT 'Aberta' CHECK (status IN ('Aberta','Em analise','Em proposta','Concluida','Cancelada')),
 responsavel text, prazo date, motivo_cancelamento text,
 criado_em timestamptz NOT NULL DEFAULT now(), atualizado_em timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.propostas (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 solicitacao_id uuid NOT NULL REFERENCES public.solicitacoes(id),
 titulo text NOT NULL, escopo text,
 status text NOT NULL DEFAULT 'Rascunho' CHECK (status IN ('Rascunho','Enviada','Em negociacao','Aprovada','Recusada','Cancelada')),
 desconto numeric(12,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
 validade date, condicoes_pagamento text, observacoes text,
 criado_em timestamptz NOT NULL DEFAULT now(), atualizado_em timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.itens_proposta (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 proposta_id uuid NOT NULL REFERENCES public.propostas(id) ON DELETE CASCADE,
 descricao text NOT NULL,
 quantidade numeric(12,2) NOT NULL DEFAULT 1 CHECK(quantidade>0),
 valor_unitario numeric(12,2) NOT NULL DEFAULT 0 CHECK(valor_unitario>=0)
);
CREATE TABLE IF NOT EXISTS public.historico (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 entidade text NOT NULL, registro_id uuid NOT NULL,
 acao text NOT NULL, descricao text, usuario text,
 criado_em timestamptz NOT NULL DEFAULT now()
);

-- Controle de quem pode acessar dados; autenticação ocorre em auth.users (Supabase Auth).
CREATE TABLE IF NOT EXISTS public.equipe (
 id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 nome text NOT NULL, perfil text NOT NULL DEFAULT 'comercial'
   CHECK(perfil IN ('admin','comercial')),
 ativo boolean NOT NULL DEFAULT true,
 criado_em timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.zetta_membro()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = '' AS $$
 SELECT EXISTS (SELECT 1 FROM public.equipe WHERE id = (SELECT auth.uid()) AND ativo = true)
$$;
CREATE OR REPLACE FUNCTION public.zetta_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = '' AS $$
 SELECT EXISTS (SELECT 1 FROM public.equipe WHERE id = (SELECT auth.uid()) AND ativo = true AND perfil = 'admin')
$$;

CREATE SEQUENCE IF NOT EXISTS public.zetta_propostas_seq;
ALTER TABLE public.propostas ADD COLUMN IF NOT EXISTS numero text;
-- Primeiro atribui números às propostas que já existiam, sem mudar seus demais dados.
UPDATE public.propostas SET numero='ZP-' || lpad(nextval('public.zetta_propostas_seq')::text,5,'0') WHERE numero IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS propostas_numero_unique ON public.propostas(numero);
CREATE OR REPLACE FUNCTION public.zetta_numero_proposta()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.numero IS NULL OR btrim(NEW.numero) = '' THEN
  NEW.numero := 'ZP-' || lpad(nextval('public.zetta_propostas_seq')::text,5,'0');
 END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_numero_proposta ON public.propostas;
CREATE TRIGGER trg_numero_proposta BEFORE INSERT ON public.propostas
FOR EACH ROW EXECUTE FUNCTION public.zetta_numero_proposta();

CREATE TABLE IF NOT EXISTS public.revisoes_proposta (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 proposta_id uuid NOT NULL REFERENCES public.propostas(id) ON DELETE CASCADE,
 numero_revisao integer NOT NULL,
 dados jsonb NOT NULL, itens jsonb NOT NULL,
 salvo_por uuid REFERENCES auth.users(id), criado_em timestamptz NOT NULL DEFAULT now(),
 UNIQUE(proposta_id,numero_revisao)
);
CREATE TABLE IF NOT EXISTS public.anexos (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 entidade text NOT NULL CHECK(entidade IN ('solicitacoes','propostas')),
 registro_id uuid NOT NULL, nome text NOT NULL, caminho text NOT NULL UNIQUE,
 tamanho bigint NOT NULL CHECK(tamanho BETWEEN 0 AND 10485760),
 criado_por uuid REFERENCES auth.users(id),
 criado_em timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_solicitacoes_cliente ON public.solicitacoes(cliente_id);
CREATE INDEX IF NOT EXISTS idx_propostas_solicitacao ON public.propostas(solicitacao_id);
CREATE INDEX IF NOT EXISTS idx_itens_proposta ON public.itens_proposta(proposta_id);
CREATE INDEX IF NOT EXISTS idx_hist_registro ON public.historico(entidade,registro_id);
CREATE INDEX IF NOT EXISTS idx_anexos_registro ON public.anexos(entidade,registro_id);

-- Registros de alterações criados pelo banco (não pelo navegador).
CREATE OR REPLACE FUNCTION public.zetta_auditoria()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_registro uuid; v_acao text; v_descricao text;
BEGIN
 v_acao := CASE TG_OP WHEN 'INSERT' THEN 'Criacao' WHEN 'UPDATE' THEN 'Atualizacao' ELSE 'Exclusao' END;
 v_registro := CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END;
 v_descricao := CASE
   WHEN TG_OP='UPDATE' AND TG_TABLE_NAME IN ('solicitacoes','propostas') THEN
      'Status: ' || COALESCE(OLD.status,'') || ' → ' || COALESCE(NEW.status,'')
   WHEN TG_OP='DELETE' THEN 'Registro excluido'
   ELSE 'Registro salvo' END;
 INSERT INTO public.historico(entidade,registro_id,acao,descricao,usuario)
 VALUES (TG_TABLE_NAME,v_registro,v_acao,v_descricao,(SELECT auth.uid())::text);
 RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;

DROP TRIGGER IF EXISTS aud_clientes ON public.clientes;
CREATE TRIGGER aud_clientes AFTER INSERT OR UPDATE OR DELETE ON public.clientes
FOR EACH ROW EXECUTE FUNCTION public.zetta_auditoria();
DROP TRIGGER IF EXISTS aud_solicitacoes ON public.solicitacoes;
CREATE TRIGGER aud_solicitacoes AFTER INSERT OR UPDATE OR DELETE ON public.solicitacoes
FOR EACH ROW EXECUTE FUNCTION public.zetta_auditoria();
DROP TRIGGER IF EXISTS aud_propostas ON public.propostas;
CREATE TRIGGER aud_propostas AFTER INSERT OR UPDATE OR DELETE ON public.propostas
FOR EACH ROW EXECUTE FUNCTION public.zetta_auditoria();

-- Transação única: salvar cabeçalho, substituir itens e registrar revisão juntos.
CREATE OR REPLACE FUNCTION public.salvar_proposta(
 p_id uuid, p_solicitacao_id uuid, p_titulo text,
 p_escopo text, p_status text, p_desconto numeric, p_validade date,
 p_condicoes text, p_observacoes text, p_itens jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_id uuid; v_item jsonb; v_total numeric := 0; v_rev integer;
BEGIN
 IF NOT public.zetta_membro() THEN RAISE EXCEPTION 'Acesso negado'; END IF;
 IF p_solicitacao_id IS NULL OR coalesce(btrim(p_titulo),'')='' THEN
   RAISE EXCEPTION 'Solicitacao e titulo sao obrigatorios'; END IF;
 IF p_status NOT IN ('Rascunho','Enviada','Em negociacao','Aprovada','Recusada','Cancelada') THEN
   RAISE EXCEPTION 'Status invalido'; END IF;
 IF p_desconto IS NULL OR p_desconto < 0 THEN RAISE EXCEPTION 'Desconto invalido'; END IF;
 IF p_itens IS NULL OR jsonb_typeof(p_itens) <> 'array' THEN RAISE EXCEPTION 'Lista de itens invalida'; END IF;
 IF jsonb_array_length(p_itens) > 100 THEN RAISE EXCEPTION 'Limite de 100 itens por proposta'; END IF;
 FOR v_item IN SELECT value FROM jsonb_array_elements(p_itens) LOOP
   IF jsonb_typeof(v_item) <> 'object'
      OR coalesce(btrim(v_item->>'descricao'),'')=''
      OR COALESCE((v_item->>'quantidade')::numeric,0)<=0
      OR COALESCE((v_item->>'valor_unitario')::numeric,-1)<0 THEN
     RAISE EXCEPTION 'Item invalido: informe descricao, quantidade e valor';
   END IF;
   v_total:=v_total + (v_item->>'quantidade')::numeric * (v_item->>'valor_unitario')::numeric;
 END LOOP;
 IF p_desconto>v_total THEN RAISE EXCEPTION 'Desconto maior que o subtotal'; END IF;
 IF p_status IN ('Enviada','Em negociacao','Aprovada') AND v_total <= 0 THEN
    RAISE EXCEPTION 'Proposta enviada ou aprovada precisa ter valor positivo'; END IF;
 IF p_id IS NULL THEN
   INSERT INTO public.propostas(solicitacao_id,titulo,escopo,status,desconto,validade,condicoes_pagamento,observacoes)
   VALUES(p_solicitacao_id,btrim(p_titulo),p_escopo,p_status,p_desconto,p_validade,p_condicoes,p_observacoes)
   RETURNING id INTO v_id;
   -- Solicitação passa automaticamente para a etapa de proposta.
   UPDATE public.solicitacoes SET status='Em proposta', atualizado_em=now()
   WHERE id=p_solicitacao_id AND status IN ('Aberta','Em analise');
 ELSE
   UPDATE public.propostas SET solicitacao_id=p_solicitacao_id,titulo=btrim(p_titulo),escopo=p_escopo,
    status=p_status, desconto=p_desconto, validade=p_validade,condicoes_pagamento=p_condicoes,
    observacoes=p_observacoes, atualizado_em=now() WHERE id=p_id RETURNING id INTO v_id;
   IF v_id IS NULL THEN RAISE EXCEPTION 'Proposta nao encontrada'; END IF;
   DELETE FROM public.itens_proposta WHERE proposta_id=v_id;
 END IF;
 FOR v_item IN SELECT value FROM jsonb_array_elements(p_itens) LOOP
   INSERT INTO public.itens_proposta(proposta_id,descricao,quantidade,valor_unitario)
   VALUES(v_id,btrim(v_item->>'descricao'),(v_item->>'quantidade')::numeric,(v_item->>'valor_unitario')::numeric);
 END LOOP;
 -- Bloqueio na linha de proposta na atualização acima serializa revisões concorrentes.
 SELECT COALESCE(MAX(numero_revisao),0)+1 INTO v_rev
 FROM public.revisoes_proposta WHERE proposta_id=v_id;
 INSERT INTO public.revisoes_proposta(proposta_id,numero_revisao,dados,itens,salvo_por)
 SELECT v_id,v_rev,to_jsonb(p),
   COALESCE((SELECT jsonb_agg(to_jsonb(i)) FROM public.itens_proposta i WHERE i.proposta_id=v_id),'[]'::jsonb),
   auth.uid() FROM public.propostas p WHERE p.id=v_id;
 RETURN v_id;
END $$;

-- RLS: remover políticas antigas permissivas ('authenticated' com acesso indiscriminado).
DO $$ DECLARE r record; BEGIN
 FOR r IN SELECT schemaname,tablename,policyname FROM pg_policies
 WHERE schemaname='public' AND tablename IN ('clientes','solicitacoes','propostas','itens_proposta','historico','equipe','revisoes_proposta','anexos')
 LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I',r.policyname,r.schemaname,r.tablename); END LOOP;
END $$;

ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.propostas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itens_proposta ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipe ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revisoes_proposta ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anexos ENABLE ROW LEVEL SECURITY;

CREATE POLICY zetta_clientes_equipe ON public.clientes FOR ALL TO authenticated
 USING (public.zetta_membro()) WITH CHECK (public.zetta_membro());
CREATE POLICY zetta_solicitacoes_equipe ON public.solicitacoes FOR ALL TO authenticated
 USING (public.zetta_membro()) WITH CHECK (public.zetta_membro());
CREATE POLICY zetta_propostas_leitura ON public.propostas FOR SELECT TO authenticated
 USING (public.zetta_membro());
CREATE POLICY zetta_itens_leitura ON public.itens_proposta FOR SELECT TO authenticated
 USING (public.zetta_membro());
CREATE POLICY zetta_historico_leitura ON public.historico FOR SELECT TO authenticated
 USING (public.zetta_membro());
CREATE POLICY zetta_revisoes_leitura ON public.revisoes_proposta FOR SELECT TO authenticated
 USING (public.zetta_membro());
CREATE POLICY zetta_equipe_leitura ON public.equipe FOR SELECT TO authenticated
 USING (public.zetta_membro());
CREATE POLICY zetta_equipe_admin_insert ON public.equipe FOR INSERT TO authenticated
 WITH CHECK (public.zetta_admin());
CREATE POLICY zetta_equipe_admin_update ON public.equipe FOR UPDATE TO authenticated
 USING (public.zetta_admin()) WITH CHECK (public.zetta_admin());
CREATE POLICY zetta_anexos_equipe ON public.anexos FOR ALL TO authenticated
 USING (public.zetta_membro()) WITH CHECK (public.zetta_membro());

-- Sem acesso anon, nem mesmo para consultas; público do site só acessa autenticação.
REVOKE ALL ON public.clientes,public.solicitacoes,public.propostas,public.itens_proposta,public.historico,public.revisoes_proposta,public.equipe,public.anexos FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.clientes,public.solicitacoes,public.anexos TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.propostas,public.itens_proposta FROM authenticated;
GRANT SELECT ON public.propostas,public.itens_proposta TO authenticated;
GRANT SELECT ON public.historico,public.revisoes_proposta TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.revisoes_proposta FROM authenticated;
GRANT SELECT,INSERT,UPDATE ON public.equipe TO authenticated;
REVOKE USAGE ON SEQUENCE public.zetta_propostas_seq FROM authenticated;
REVOKE ALL ON FUNCTION public.salvar_proposta(uuid,uuid,text,text,text,numeric,date,text,text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.salvar_proposta(uuid,uuid,text,text,text,numeric,date,text,text,jsonb) TO authenticated;

-- Anexos privados (até 10 MB cada). Não tornar o bucket público.
INSERT INTO storage.buckets(id,name,public,file_size_limit)
VALUES('zetta-anexos','zetta-anexos',false,10485760)
ON CONFLICT(id) DO UPDATE SET public=false,file_size_limit=10485760;
DROP POLICY IF EXISTS zetta_storage_read ON storage.objects;
DROP POLICY IF EXISTS zetta_storage_insert ON storage.objects;
DROP POLICY IF EXISTS zetta_storage_delete ON storage.objects;
CREATE POLICY zetta_storage_read ON storage.objects FOR SELECT TO authenticated
 USING (bucket_id='zetta-anexos' AND public.zetta_membro());
CREATE POLICY zetta_storage_insert ON storage.objects FOR INSERT TO authenticated
 WITH CHECK (bucket_id='zetta-anexos' AND public.zetta_membro());
CREATE POLICY zetta_storage_delete ON storage.objects FOR DELETE TO authenticated
 USING (bucket_id='zetta-anexos' AND public.zetta_membro());

-- Próximo passo obrigatório: execute 02_admin_inicial.sql com seu email, no mesmo projeto.
