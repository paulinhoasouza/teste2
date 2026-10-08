# Checklist de homologação (antes de colocar em operação)

Execute com dados de TESTE criados manualmente por você; o pacote não inclui clientes fictícios.

1. **Autenticação:** usuário errado não entra; usuário Supabase Auth sem linha em `equipe` vê acesso negado; usuário inativo não entra na plataforma.
2. **Clientes:** novo, editar (inclusive alternar clientes e voltar), busca por nome, exclusão sem solicitações; impedir exclusão com solicitação vinculada.
3. **Solicitações:** inserir vinculada ao cliente, trocar status e prioridade, registrar motivo quando cancelar, anexar e baixar documento privado.
4. **Propostas:** inserir 2 itens; validar quantidade negativa e desconto acima do total; salvar rascunho e enviado; verificar número e revisão 1; editar e verificar revisão 2; aprovar; visualizar PDF.
5. **Relatórios:** verificar valores e taxa de conversão com exemplos conhecidos; filtrar datas; exportar CSV.
6. **Equipe:** admin aprova novo usuário Auth pelo UID; comercial acessa; comercial não vê botão de adicionar membro; admin desativa outro usuário.
7. **Permissões:** no painel Supabase, confirmar RLS habilitada para todas as tabelas; chave service_role nunca presente no frontend ou no GitHub.
8. **Responsividade:** testar desktop e celular, menu lateral e modais.
9. **Persistência:** atualizar o navegador; novos dados devem continuar no Supabase.

Se um erro surgir no Cloudflare, abra Deployments / Logs. Se erros de dados surgirem, revise a execução SQL e o Console/Network do navegador. Não copie credenciais ao compartilhar logs.
