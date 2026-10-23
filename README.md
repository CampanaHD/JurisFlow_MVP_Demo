# JurisFlow — MVP demonstrativo

## O que vem neste pacote
- `index.html`: protótipo navegável com dashboard e módulos de clientes, casos, agenda/prazos, tarefas, financeiro, registros de documentos, relatórios, prévia de portal do cliente e demonstração de fluxo de IA.
- `supabase_schema.sql`: esquema inicial PostgreSQL/Supabase com separação por escritório e políticas RLS iniciais.
- Este README com instruções e limites.

## Abrir a demonstração agora
1. Extraia o ZIP.
2. Abra `index.html` no Chrome ou Edge.
3. Clique em “Entrar na demonstração”.
4. Explore os menus e cadastre/edite/exclua registros.
5. Os dados ficam no `localStorage` deste navegador. Use “Reiniciar demo” para restaurar os dados fictícios.

Não precisa de banco para a demonstração local. Não use informações reais, nomes, documentos ou processos de clientes: não há autenticação, isolamento entre usuários ou armazenamento seguro nesta versão.

## Hospedar a demo
Pode ser publicada como página estática (por exemplo GitHub Pages) para demonstrar a interface, mas todos os visitantes desse link terão uma demo local independente. Não compartilhe como se fosse um sistema de produção.

## Banco Supabase
1. Crie um projeto Supabase de desenvolvimento.
2. Abra SQL Editor e revise/execute `supabase_schema.sql`.
3. O SQL cria tabelas e RLS iniciais, mas não cria sozinho o fluxo de cadastro de escritórios/membros nem conecta o `index.html` ao Supabase.
4. A integração exige autenticação, onboarding seguro, validação de referências dentro do mesmo escritório, políticas de Storage privado e testes de segurança antes de inserir qualquer dado real.

## O que ainda é apenas prévia / não implementado
- Login real e contas separadas por escritório.
- Sincronização entre dispositivos e usuários.
- Notificações por e-mail/WhatsApp/push e alertas em segundo plano.
- Integração automática com tribunais ou captura de prazos.
- Upload/armazenamento privado de arquivos.
- Portal externo real com autenticação de clientes.
- IA real (a tela de IA só simula um exemplo; não chama um modelo).
- Assinatura, cobrança recorrente, limites de plano e painel administrativo SaaS.

## Próximo passo recomendado
Use esta demo com o advogado como prévia visual/interativa. Para um teste real com contas e dados, primeiro conectar Supabase Auth + banco, terminar isolamento por escritório e testar RLS. Não prometa segurança, prazos automáticos, IA ou portal funcional antes de implementar e validar essas partes.
