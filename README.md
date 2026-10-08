# Zetta Propostas — gestão comercial

Aplicação web da Zetta, sem Streamlit, com interface React e backend no Supabase (PostgreSQL, autenticação, API, funções transacionais, controle de acesso e arquivos privados). Implantação do site no Cloudflare Pages, com plano gratuito sujeito às cotas dos provedores.

## Recursos da versão 1.0

- Login com Supabase Auth; sem cadastro público na interface.
- Controles de equipe: aprovados na tabela `equipe`, perfis administrador/comercial, ativação e desativação.
- Clientes: cadastrar, pesquisar, editar e excluir se não houver solicitações.
- Solicitações: cadastrar, pesquisar, editar, prioridade, responsável, prazo, status e motivo de cancelamento; anexos e histórico.
- Propostas: vincular à solicitação; escopo, itens e quantidades, preços, desconto, validade, pagamento e observações; status de negociação e cancelamento.
- Gravação **transacional** da proposta, com número `ZP-00001`, snapshot automático a cada revisão e auditoria do banco.
- Visualização da proposta e impressão/salvamento em PDF pelo navegador.
- Anexos privados de até 10 MB, com URLs temporárias para download.
- Dashboard, indicadores, filtros, relatório por intervalo e CSV.
- Layout adaptado para desktop e celular.

### Estrutura

```
zetta-propostas-web/
├── index.html
├── package.json
├── vite.config.js
├── .env.example
├── .gitignore
├── src/
│   ├── main.jsx
│   ├── App.jsx                 # todas as telas e formulários
│   ├── style.css               # identidade visual e responsividade
│   └── lib/
│       ├── supabase.js         # inicialização do cliente
│       ├── data.js             # operações e chamadas de API
│       └── business.js         # cálculos de negócio (testados)
├── tests/
│   └── business.test.js
├── supabase/
│   ├── 01_migracao.sql         # banco, segurança, RPC, storage
│   └── 02_admin_inicial.sql    # primeiro administrador
└── GUIA-PUBLICACAO.md
```

## Por que não há um servidor Express/FastAPI?

O backend **não é simulado**: é executado no Supabase. O PostgreSQL armazena os dados, a API PostgREST consulta as tabelas sob RLS, o Auth emite tokens e a função `salvar_proposta` valida e salva proposta + itens + revisão na mesma transação. As operações de criação/edição de propostas só podem ocorrer por essa função protegida. O React consome esta API autenticada com a chave pública, sem uma máquina/instância para manter ligada. Isso reduz a complexidade e viabiliza hospedagem gratuita.

A aplicação necessita de uma conexão real com o Supabase; o arquivo ZIP não inclui credenciais nem banco de dados.

## Instalação local (opcional)

Instale Node.js 20 ou superior. Na pasta do projeto:

```bash
cp .env.example .env
# edite .env com a URL e chave PUBLICÁVEL do seu projeto
npm install
npm run dev
npm test
```

Abra o endereço informado no terminal (habitualmente `http://localhost:5173`).

**Nunca** use `service_role`, chave secreta ou senha do banco em `VITE_...`. Variáveis `VITE_` ficam visíveis no JavaScript do navegador por design. A segurança depende das políticas RLS e da autenticação do Supabase.

## Publicação gratuita

Consulte [GUIA-PUBLICACAO.md](GUIA-PUBLICACAO.md) para os passos pelo navegador, sem instalar nada no computador.

## Segurança e operação

- O arquivo SQL remove antigas políticas permissivas das tabelas da Zetta e exige vínculo ativo em `equipe`.
- Crie o primeiro administrador após a migração, usando o e-mail real de um usuário existente no Supabase Auth.
- Desative o cadastro público em **Supabase > Authentication > Settings** (a localização exata pode variar; procure "Allow new users to sign up").
- Não publique dados de clientes em repositórios públicos ou exemplos.
- O Supabase Free não oferece backup diário automático; exporte periodicamente seus dados pelo painel SQL/Table Editor e guarde uma cópia segura.
- É uma primeira versão funcional baseada em código. Antes de usar em vendas reais, teste todos os fluxos, avalie exigências de LGPD, política de retenção, permissões dos colaboradores e termos comerciais/tributários dos seus documentos.

## Limitações deliberadas da v1

- PDFs usam a impressão do navegador. O documento não possui assinatura eletrônica, emissão de NF ou envio automático por e-mail/WhatsApp.
- Inclusão de novo login é feita no painel do Supabase Auth; dentro do sistema o administrador concede permissão usando o UUID gerado no Auth.
- Comercial e administrador podem trabalhar com os mesmos clientes/propostas; o administrador também gerencia acesso dos usuários.
- Auditoria é interna (log das operações sobre clientes, solicitações e propostas), não substitui logs regulatórios nem trilha certificada.
- Supabase gratuito pode pausar após 7 dias sem atividade; há cotas. Não é garantia de disponibilidade para um sistema crítico.

## Problemas frequentes

- **Tela "Configure a conexão"**: faltam `VITE_SUPABASE_URL` e/ou `VITE_SUPABASE_ANON_KEY` nas variáveis do build Cloudflare. Configure e faça novo deploy.
- **"Acesso ainda não autorizado"**: usuário logou, mas falta executar `02_admin_inicial.sql` com e-mail correto ou está inativo em `equipe`.
- **Tabela não encontrada / função salvar_proposta inexistente**: execute `01_migracao.sql` no mesmo projeto Supabase da URL configurada.
- **Falha ao anexar**: confirme bucket privado `zetta-anexos` e políticas storage criados pelo SQL.
- **Login incorreto**: confirme usuário em Authentication > Users e se o provedor Email está ativado.
- **Build do Cloudflare falha**: confira Build command `npm run build`, output `dist`, Node 20+ e conteúdo do repo na raiz.

© Zetta. Uso interno.
