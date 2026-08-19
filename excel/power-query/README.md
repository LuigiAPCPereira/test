# Power Query — Controle de Frotas Nordeste

Consultas auxiliares para evoluir a planilha sem substituir o que já funciona antes de validar no Excel corporativo.

A especificação de layout está em `../CAMADA_VISUAL.md` e o plano de performance em `../PERFORMANCE.md`.

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

- `OSOperacional` (ou aba separada durante a comparação)
- `DocumentosOperacionais`
- `ResumoOperacional`

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

Isso é importante também para performance: várias consultas carregadas que referenciam `SuasTrans` podem causar novas avaliações da árvore da fonte.

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

Deve ficar como **somente conexão** e servir de apoio à camada visual.

## Performance

A planilha original possui várias consultas carregadas que derivam de `SuasTrans`, além de fontes baseadas em `SharePoint.Files`.

As otimizações já feitas:

- `Medidor` e `ManoTer` não consultam novamente `ConsultarFrotasNordeste`;
- `AtualizacaoMae` cria um caminho para consolidar sete consultas simples em uma única saída;
- `DiagnosticoPastasSharePoint` captura os caminhos exatos das pastas para a próxima migração.

Próxima etapa: trocar a enumeração ampla de `SharePoint.Files` por navegação direta com `SharePoint.Contents`, depois que os quatro `Folder Path` forem confirmados no Excel corporativo.

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
