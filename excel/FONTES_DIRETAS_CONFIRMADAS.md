# Fontes SharePoint diretas — caminhos confirmados

Caminhos confirmados visualmente no Excel em 20/08/2026.

## Teste728

- SuasTrans: `https://grupoultracloud.sharepoint.com/teams/Teste728/Documentos Compartilhados/Dados Suastrans/`
- MaxTrack: `https://grupoultracloud.sharepoint.com/teams/Teste728/Documentos Compartilhados/Dados MaxTrack/`
- Tableau: `https://grupoultracloud.sharepoint.com/teams/Teste728/Documentos Compartilhados/Dados Tableau/`

## Planilha mãe

- `https://grupoultracloud.sharepoint.com/teams/UG-ExcelnciaemFrotas/Documentos Compartilhados/Manutenção e Disponibilidade/`
- arquivo esperado: `Programações Paradas Frotas.xlsm`

## Implementação preparada

Consultas de substituição que usam `SharePoint.Contents(..., [ApiVersion = 15, Implementation = "2.0"])` diretamente na pasta:

- `power-query/ConsultarFrotasNordeste_Direto.m`
- `power-query/SuasTrans_Direto.m`
- `power-query/MaxTrack_Direto.m`
- `power-query/Tableu_Direto.m`

O restante da lógica das consultas foi preservado; a mudança principal é a forma de alcançar o arquivo mais recente.

## Ordem segura de teste

1. Fazer uma cópia do arquivo Excel de trabalho.
2. Substituir primeiro o código de `ConsultarFrotasNordeste` por `ConsultarFrotasNordeste_Direto.m`.
3. Atualizar apenas essa consulta e conferir que continuam existindo 57 placas e que `Placa`, `Frota`, `Filial` e `Núcleo` permanecem corretos.
4. Substituir `SuasTrans` por `SuasTrans_Direto.m`.
5. Atualizar apenas `SuasTrans` e comparar quantidade de linhas, placas, tipos de documento e status com a consulta anterior.
6. Medir o tempo de `Medidor` e `ManoTer` novamente, pois ambos dependem de `SuasTrans`.
7. Só depois substituir `MaxTrack` e `Tableu` pelas versões diretas.
8. Por último executar `Atualizar Tudo` e comparar o tempo total.

Não remover as consultas antigas `CIV`, `Crono`, `CIPP`, `TH`, `Medidores`, `Mássico` e `CRLV` até `AtualizacaoMae` ser validada.

## Formula.Firewall

O erro observado no diagnóstico ocorreu porque uma única consulta combinava dois sites SharePoint distintos no workbook de teste. A migração de produção não depende de combinar os diagnósticos: cada consulta de origem acessa sua própria pasta e as consultas são testadas separadamente.

Se o `Formula.Firewall` aparecer dentro do arquivo operacional ao substituir uma consulta existente, parar a migração daquela consulta e revisar as configurações de privacidade/origem do workbook antes de alterar qualquer política corporativa.
