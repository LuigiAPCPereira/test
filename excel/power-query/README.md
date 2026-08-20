# Power Query — Controle de Frotas Nordeste

Consultas auxiliares para evoluir a planilha sem substituir o que já funciona antes de validar no Excel corporativo.

Documentação complementar:

- `../CAMADA_VISUAL.md`
- `../CAMADA_VISUAL_IMPLEMENTACAO.md`
- `../PERFORMANCE.md`
- `../MIGRACAO_CARGAS_REFRESH.md`

## Ordem de criação no Excel

1. `PreventivaRodante` — `../PreventivaRodante_PowerQuery.m`
2. `ManoTer` — `ManoTer.m`
3. `Medidor` — `Medidor.m`
4. `OSOperacional` — `OSOperacional.m`
5. `DocumentosOperacionais` — `DocumentosOperacionais.m`
6. `AcoesOperacionais` — `AcoesOperacionais.m`
7. `ResumoOperacional` — `ResumoOperacional.m`
8. `AtualizacaoMae` — `AtualizacaoMae.m`
9. `QualidadeDados` — `QualidadeDados.m`

`DiagnosticoPastasSharePoint.m` é temporária e só deve ser criada quando formos medir/migrar as fontes SharePoint.

## Carregamento recomendado na validação

Carregar em tabela:

- `PreventivaRodante` → **Preventiva Rodante**
- `ManoTer` → **Mano-Ter**
- `Medidor` → **Medidor**
- `AcoesOperacionais` → **Ações Operacionais**
- `AtualizacaoMae` → **Atualização Mãe**
- `QualidadeDados` → **Qualidade dos Dados**

Somente conexão inicialmente:

- `OSOperacional` — ou aba separada durante comparação
- `DocumentosOperacionais`
- `ResumoOperacional`

Depois da validação, `ManoTer` e `Medidor` também podem deixar de ser carregadas se `AtualizacaoMae` cobrir o uso real dos segmentadores/PROCVs.

## Dependências

- `PreventivaRodante` → planilha mãe no SharePoint + `MaxTrack`.
- `ManoTer` → `SuasTrans`.
- `Medidor` → `SuasTrans`.
- `OSOperacional` → consulta `Tableu`.
- `DocumentosOperacionais` → `SuasTrans`.
- `AcoesOperacionais` → `PreventivaRodante` + `DocumentosOperacionais` + `OSOperacional`.
- `ResumoOperacional` → `AcoesOperacionais`.
- `AtualizacaoMae` → `SuasTrans`.
- `QualidadeDados` → bases existentes e consultas novas.

## Consulta não é a mesma coisa que aba

`OSOperacional` usa a **consulta Power Query** chamada `Tableu` como fonte. Ela não precisa da aba carregada `Tableu` para funcionar.

Depois da validação é possível deixar `Tableu` como **Somente Criar Conexão** e usar apenas `OSOperacional` como página visível. Não excluir a consulta `Tableu` enquanto houver dependência.

O mesmo princípio vale para outras consultas auxiliares.

## Estado original confirmado

A pasta de trabalho original possui 11 consultas carregadas em tabelas visíveis:

- ConsultarFrotasNordeste
- SuasTrans
- MaxTrack
- Tableu
- CIV
- Crono
- CIPP
- TH
- Medidores
- Mássico
- CRLV

As sete últimas consultas documentais são filtros simples de `SuasTrans`.

Também foi confirmado que `ConsultarFrotasNordeste`, `SuasTrans`, `MaxTrack` e `Tableu` estavam configuradas com refresh ao abrir + intervalo de 60 minutos + atualização em segundo plano.

A migração dessas cargas está detalhada em `../MIGRACAO_CARGAS_REFRESH.md`.

## AtualizacaoMae

`AtualizacaoMae` consolida em uma única linha por placa as datas usadas para atualizar a planilha mãe:

- CIV
- Crono
- CIPP
- TH
- Medidor — 02.02 Medidor Mássico
- Mano/Ter — menor validade entre 02.01, 02.03 e 02.04
- Documento Mano/Ter mais próximo
- CRLV

Também informa integridade, documentos faltantes e duplicados.

Depois de comparar os resultados, ela pode substituir como fonte dos PROCV/XLOOKUP as consultas simples antigas `CIV`, `Crono`, `CIPP`, `TH`, `Mássico`, `Medidores` e `CRLV`.

O segmentador `Documento Mano/Ter mais próximo` pode ser colocado diretamente nessa página, evitando uma aba adicional se o fluxo ficar confortável.

## Medidor

`Medidor` representa exclusivamente:

- 02.02 — Calibração — Medidor Mássico

NUCLEO, Filial e Frota são lidos diretamente da própria `SuasTrans`, corrigindo a incompatibilidade `Núcleo` x `NUCLEO` que gerou `null` anteriormente.

## Mano/Ter

Para cada placa considera:

- 02.01 — Manômetro Analógico Vertical
- 02.03 — Termômetro Analógico
- 02.04 — Manômetro Analógico Horizontal

A validade é a menor das três. `Documento mais próximo` informa qual item originou a data e exibe empates em conjunto.

## Ações Operacionais

`AcoesOperacionais` é a fila única do que merece atenção. Ela reúne:

- preventiva rodante fora de `OK`;
- documentos vencidos, expirando ou inconsistentes;
- OS `APROG`, `COMP` ou status não reconhecido.

`FECHAR` e documentos válidos não poluem a fila.

Segmentadores recomendados:

- NUCLEO
- PRIORIDADE
- CATEGORIA
- AÇÃO
- MÊS-ANO
- PLACA

## Resumo Operacional

Uma linha por núcleo + `TOTAL` com:

- total de ações;
- urgentes;
- preventivas;
- documentos;
- OS;
- fechar no Máximo;
- cobrar mecânica;
- regularizar documento;
- programar renovação;
- programar preventiva.

Para alimentar cartões comuns de célula no Excel, carregar essa tabela em uma pequena aba `_Apoio` que pode ficar oculta.

## Performance

As otimizações já feitas:

- `Medidor` e `ManoTer` não consultam novamente `ConsultarFrotasNordeste`;
- `AtualizacaoMae` cria um caminho para substituir sete cargas documentais simples;
- foi identificado o refresh automático ao abrir/a cada 60 min nas quatro consultas-base;
- `DiagnosticoPastasSharePoint` captura os caminhos exatos das pastas para a próxima migração;
- `fnArquivoMaisRecenteSharePoint` já está preparada para usar navegação direta depois da validação dos caminhos.

Próxima otimização pesada: trocar a enumeração ampla de `SharePoint.Files` por navegação direta com `SharePoint.Contents`, depois que os quatro `Folder Path` forem confirmados no Excel corporativo.

## DiagnosticoPastasSharePoint

Consulta temporária que retorna o arquivo mais recente e o `Folder Path` de:

- Dados Suastrans
- Dados MaxTrack
- Dados Tableau
- Programações Paradas Frotas.xlsm

Não é uma consulta operacional e pode ser removida depois que os caminhos forem copiados.

## Qualidade dos Dados

Tabela de exceções. Quando tudo estiver consistente, deve ficar vazia ou quase vazia.

Ela verifica ausência/duplicidade de KM, documentos esperados, Mano/Ter, Medidor, Preventiva Rodante e status de OS fora do fluxo conhecido.

## Princípio de segurança

Nenhuma consulta nova deve substituir uma página existente antes do primeiro `Atualizar Tudo` ser validado no Excel conectado ao SharePoint. A migração é incremental: primeiro comparar, depois substituir somente o que realmente melhorar o trabalho.
