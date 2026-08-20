# Performance — Controle de Frotas Nordeste

## Diagnóstico confirmado no arquivo original

O arquivo original possui 11 consultas carregadas em abas separadas:

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

A inspeção do DataMashup confirmou que `CIV`, `Crono`, `CIPP`, `TH`, `Medidores`, `Mássico` e `CRLV` são filtros simples de `SuasTrans` por meio da função `FiltrarTidoDoc`.

O caso `Medidores` é especialmente importante: no arquivo original ele filtra somente `02.03 - Calibração - Termometro Analógico`. Portanto, não implementava a regra real de Mano/Ter.

Também foi confirmado nas conexões do workbook que `ConsultarFrotasNordeste`, `SuasTrans`, `MaxTrack` e `Tableu` estão configuradas com:

- refresh em segundo plano;
- refresh ao abrir;
- intervalo automático de 60 minutos.

No Power Query, uma consulta que referencia outra não funciona como um cache persistente. Cada consulta derivada pode provocar uma nova avaliação da árvore da consulta-pai. `Table.Buffer` só ajuda dentro da mesma execução da consulta e não transforma uma consulta compartilhada em cache global.

Isso é especialmente caro aqui porque as quatro bases usam fontes SharePoint e três delas (`SuasTrans`, `MaxTrack` e `Tableu`) também dependem do mapeamento `ConsultarFrotasNordeste`.

## Objetivo

Reduzir o refresh sem mudar o processo operacional de uma vez.

A ordem segura é:

1. corrigir consultas derivadas desnecessariamente caras;
2. consolidar as páginas simples usadas só para PROCV/XLOOKUP;
3. reduzir cargas redundantes e refresh automático;
4. descobrir os caminhos exatos das quatro fontes SharePoint;
5. migrar as fontes remotas de `SharePoint.Files` para navegação direta com `SharePoint.Contents`;
6. somente depois remover cargas/abas antigas que já tenham substituto validado.

## Etapa 1 — concluída

`Medidor` e `ManoTer` usam somente `SuasTrans` como fonte operacional.

Isso remove uma referência adicional a `ConsultarFrotasNordeste` nessas duas consultas e corrige o problema `Núcleo` x `NUCLEO` que causava valores nulos.

## Etapa 2 — AtualizacaoMae

A consulta `AtualizacaoMae.m` entrega uma linha por placa com:

- CIV
- Crono
- CIPP
- TH
- Medidor (02.02 — Medidor Mássico)
- Mano/Ter (menor validade entre 02.01, 02.03 e 02.04)
- Documento Mano/Ter mais próximo
- CRLV
- integridade e documentos faltantes/duplicados

Depois da validação, essa única tabela pode substituir como fonte de PROCV/XLOOKUP as sete consultas simples antigas.

Não desligar as antigas antes de comparar os resultados.

## Etapa 3 — política de cargas e refresh

O estado original e a sequência de migração estão detalhados em `MIGRACAO_CARGAS_REFRESH.md`.

Ponto principal: depois da validação, as sete consultas documentais simples não precisam continuar carregadas separadamente.

Também é recomendável remover o intervalo automático de 60 minutos quando o fluxo adotado for: adicionar novos exports e executar `Atualizar Tudo` conscientemente. Isso evita refresh inesperado no meio do trabalho.

## Etapa 4 — caminhos SharePoint

Criar temporariamente a consulta `DiagnosticoPastasSharePoint.m`.

Ela devolve o `Folder Path` real de:

- Dados Suastrans
- Dados MaxTrack
- Dados Tableau
- Programações Paradas Frotas.xlsm

Depois de copiar esses quatro caminhos, a consulta de diagnóstico pode ser removida.

## Etapa 5 — navegação direta

A implementação final deve preferir `SharePoint.Contents` apontando/navegando diretamente à biblioteca/pasta necessária, em vez de listar todos os arquivos e subpastas do site com `SharePoint.Files` e só então filtrar.

A função `fnArquivoMaisRecenteSharePoint.m` já está preparada para receber uma URL/pasta validada e retornar o arquivo `.xlsx` mais recente.

Referências oficiais:

- https://learn.microsoft.com/pt-br/power-query/sharepoint-onedrive-files
- https://learn.microsoft.com/pt-br/powerquery-m/sharepoint-contents
- https://learn.microsoft.com/pt-br/powerquery-m/sharepoint-files
- https://learn.microsoft.com/pt-br/power-bi/guidance/power-query-referenced-queries
- https://learn.microsoft.com/pt-br/powerquery-m/table-buffer

## Etapa 6 — cargas finais

Após validação, manter visíveis apenas as páginas realmente usadas na operação.

Sugestão:

- Ações Operacionais
- Preventiva Rodante
- SuasTrans
- OS Operacional
- Atualização Mãe
- Qualidade dos Dados

`Mano-Ter` e `Medidor` podem permanecer se os segmentadores específicos forem úteis no dia a dia. Caso a `Atualização Mãe` cubra o uso real, eles podem virar visões auxiliares ou ser eliminados depois.

## Como medir

Medir separadamente, sempre usando o mesmo arquivo e a mesma rede:

1. tempo de atualização de `SuasTrans`;
2. tempo de atualização de `Medidor`;
3. tempo de `Atualizar Tudo`;
4. repetir depois de consolidar as consultas simples;
5. repetir depois de retirar refresh/cargas redundantes;
6. repetir depois de migrar as fontes para `SharePoint.Contents`.

Não usar apenas o tempo de preview no Editor como medida final; o que interessa é o refresh executado no uso normal do Excel.
