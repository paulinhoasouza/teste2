# Guia de publicação gratuita — Zetta Propostas

Este caminho utiliza **seu Supabase existente** (para reaproveitar os clientes já cadastrados), **GitHub** (código) e **Cloudflare Pages** (site). Não utiliza Streamlit e não exige Node/Git instalados no computador.

## PASSO 0 — Salvar os dados que você já tem

Entre no Supabase da Zetta. Em **Table Editor**, exporte um CSV de `clientes`, `solicitacoes` e `propostas` se já houver dados. Guarde os arquivos fora de um repositório público. Essa é uma medida preventiva antes de alterar políticas e funções do banco.

## PASSO 1 — Aplicar o backend

1. Acesse https://supabase.com/dashboard e selecione **o mesmo projeto Supabase** utilizado no antigo app Streamlit (não crie um novo, se pretende preservar dados).
2. Abra **SQL Editor > New query**.
3. Abra o arquivo `supabase/01_migracao.sql` deste pacote, copie todo o conteúdo e execute em **Run**.
4. Em **Authentication > Users**, confirme o e-mail do usuário administrador já criado durante os testes do Streamlit.
5. Abra `supabase/02_admin_inicial.sql`, substitua `COLOQUE_SEU_EMAIL_AQUI` por esse e-mail e execute no SQL Editor.
6. O SELECT final deve listar seu usuário com perfil `admin` e `ativo = true`. Se não aparecer, revise o e-mail e confirme que está no mesmo projeto.
7. Em **Authentication > Settings**, desative o cadastro público (**Allow new users to sign up**). Acesse **Providers > Email** e mantenha o login por e-mail habilitado.

**Importante:** no SQL Editor, use seu usuário administrativo do próprio projeto. As regras criadas bloqueiam consultas de usuários não autorizados. O antigo aplicativo Streamlit poderá deixar de funcionar com as antigas políticas; é esperado durante a migração.

## PASSO 2 — Subir o código para o GitHub

1. Baixe `zetta-propostas-web.zip` e **extraia** o arquivo no computador.
2. Entre em https://github.com/new e crie um repositório **Private** chamado `zetta-propostas-web`. Pode deixar a inicialização com README desmarcada (ou mantê-la e substituir depois).
3. Entre no repositório e clique em **Add file > Upload files**.
4. Abra a pasta extraída `zetta-propostas-web` e **arraste todo o conteúdo dela** para a área de upload do GitHub (incluindo as pastas `src` e `supabase` e os arquivos `index.html` e `package.json`). Arraste o CONTEÚDO, não o ZIP. Também não carregue `.env` nem senhas.
5. Confirme que `package.json` e `index.html` aparecem diretamente na raiz do repositório, não dentro de outra pasta aninhada.
6. Clique em **Commit changes**.

Nota: `.gitignore` é um arquivo oculto em alguns sistemas; ele ajuda a não subir `.env`/`node_modules`. Não há segredos dentro do pacote. Se o GitHub não aceitar arrastar toda a pasta, use o botão de upload por partes, respeitando a estrutura de subpastas, ou o GitHub Desktop como alternativa.

## PASSO 3 — Publicar no Cloudflare Pages

1. Entre em https://dash.cloudflare.com e crie sua conta gratuita, se necessário.
2. Entre em **Workers & Pages** e escolha **Create application > Pages > Import an existing Git repository** (a nomenclatura pode variar; escolha a opção Git para Pages, não Worker).
3. Autorize o Cloudflare a acessar seu repositório GitHub privado `zetta-propostas-web`.
4. Configure:

| Campo | Valor |
|---|---|
| Production branch | `main` |
| Framework preset | `React (Vite)` ou `Vite` (opcional) |
| Build command | `npm run build` |
| Build output directory | `dist` |
| Root directory | `/` (raiz) |
| Node.js | 20+ se precisar selecionar |

5. No mesmo assistente ou em **Pages project > Settings > Environment variables**, adicione estas variáveis de ambiente **de build**:

```
VITE_SUPABASE_URL=https://SEU-PROJETO.supabase.co
VITE_SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICAVEL_OU_ANON
```

Localize os valores em **Supabase > Project Settings > Data API / API Keys**. Use somente uma **publishable key** (por exemplo `sb_publishable_...`) ou a antiga chave **anon**. **Nunca** use `service_role`, `sb_secret_...` ou a senha do banco. O código do React incorpora variáveis `VITE_` na aplicação; são públicas.

6. Clique em **Save and Deploy**. Se já publicou antes de configurar as variáveis, vá a **Deployments > Retry deployment** para reconstruir o site.
7. O Cloudflare fornecerá um endereço como `https://zetta-propostas-web.pages.dev`. O subdomínio gratuito depende da disponibilidade.
8. Acesse a URL e entre com o usuário que já existe no Supabase Auth.

## PASSO 4 — Verificar tudo antes de usar

- [ ] Login aparece e autentica o administrador.
- [ ] Equipe mostra sua conta ativa.
- [ ] Clientes existentes continuam cadastrados.
- [ ] Criar/editar um cliente funciona e persiste após atualizar.
- [ ] Criar uma solicitação vinculada a cliente funciona.
- [ ] Criar proposta com dois itens e desconto apresenta total correto.
- [ ] Ao salvar, número `ZP-xxxxx` é criado e aparece uma revisão.
- [ ] Editar proposta cria outra revisão; mudar status funciona.
- [ ] Imprimir/salvar proposta em PDF funciona no navegador.
- [ ] Anexo privado é enviado, aberto e excluído.
- [ ] Relatório filtra datas e exporta CSV.
- [ ] Encerrar sessão impede acesso aos dados.

## PASSO 5 — Adicionar outros colaboradores

1. Acesse Supabase > **Authentication > Users > Add user**.
2. Crie uma conta com senha individual (não compartilhe a conta administrativa).
3. Copie o **User UID** gerado para a conta.
4. No site, use **Equipe > Adicionar integrante** e preencha esse UID, nome, perfil e status ativo.
5. O colaborador já poderá entrar com suas próprias credenciais.

## Custo e restrições

- **Cloudflare Pages Free:** hospedagem estática e integração com GitHub, sujeita aos limites de build/tráfego. Commit na branch principal atualiza o site automaticamente.
- **Supabase Free:** banco e autenticação gratuitos com quotas de armazenamento, uso e atividade; projeto pode pausar após período de inatividade. Leia as condições atuais antes de depender disso para negócios em produção.
- **GitHub Free:** repositório privado sem custo para este porte de projeto.

Documentação oficial:
- https://developers.cloudflare.com/pages/framework-guides/deploy-a-react-site/
- https://developers.cloudflare.com/pages/configuration/build-configuration/
- https://supabase.com/docs/guides/database/secure-data
- https://supabase.com/docs/guides/platform/free-project-pausing
- https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
