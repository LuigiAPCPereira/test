# Visual operacional — Controle de Frotas Nordeste

Este diretório contém a camada visual segura para a pasta de trabalho operacional.

## Por que Office Script?

A pasta de trabalho usa Power Query, conexões e DataMashup. Reexportar o `.xlsx` por um editor externo remove essas partes internas. O Office Script aplica o layout **dentro do próprio Excel**, preservando as consultas e conexões existentes.

## Como aplicar

1. Abra `Controle de Frotas Nordeste.xlsx` no Excel Microsoft 365.
2. Faça uma cópia de segurança.
3. Abra **Automatizar / Automate > Novo Script**.
4. Substitua o conteúdo pelo arquivo `AplicarVisualFrotasNordeste.ts`.
5. Execute o script.
6. Salve a pasta de trabalho.
7. Execute **Dados > Atualizar Tudo** e confirme que as consultas continuam funcionando.

O script pode ser executado novamente: ao reconstruir o `Painel Operacional`, ele desfaz as mesclagens antigas antes de recriar o layout.

## O que o script faz

- cria/atualiza `Painel Operacional`;
- cria cards de URGENTE, AÇÃO, ATENÇÃO, DOCUMENTAÇÃO, PREVENTIVA, OS e EXCEÇÕES;
- cria gráficos por prioridade, categoria e núcleo;
- aplica cabeçalhos, larguras e formatação condicional em `AcoesOperacionais`, `PreventivaRodante`, `SuasTrans`, `OSOperacional`, `QualidadeDados`, `AtualizacaoMae`, `MaxTrack` e `Tableu`;
- remove congelamentos existentes nas planilhas alteradas pelo script;
- usa formatos locais de data compatíveis com Excel pt-BR (`dd/mm/aaaa`);
- não altera o código das consultas Power Query.

## Validação mínima após executar

- não há linhas ou colunas congeladas nas planilhas alteradas;
- datas aparecem com ano completo, por exemplo `16/01/2027`, e não `16/01/yyyy`;
- `SuasTrans` e `AtualizacaoMae` recebem a formatação visual;
- `Painel Operacional` é reconstruído sem erro mesmo após uma execução anterior;
- `Dados > Atualizar Tudo` conclui sem erro;
- `AcoesOperacionais` continua populada;
- `PreventivaRodante` mantém KM e datas;
- `OSOperacional` mantém FROTA/PLACA;
- `QualidadeDados` continua funcionando como tabela de exceções.
