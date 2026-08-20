# Power Query — Controle de Frotas Nordeste

Objetivo: evoluir a planilha sem quebrar o fluxo atual e reduzir o custo do refresh.

Documentação principal:

- `../MIGRACAO_SHAREPOINT_CONTENTS.md`
- `../MIGRACAO_CARGAS_REFRESH.md`
- `../PERFORMANCE.md`
- `../CAMADA_VISUAL.md`

## Fontes SharePoint otimizadas

Criar como **Somente Criar Conexão**:

1. `FontePlanilhaMae_Contents`
2. `FonteSuasTrans_Contents`
3. `FonteMaxTrack_Contents`
4. `FonteTableu_Contents`

Essas consultas usam `SharePoint.Contents` a partir da URL do site e navegam pela hierarquia `Documentos Compartilhados -> pasta`.

A intenção é preservar as transformações originais e trocar somente a etapa de origem das consultas existentes.

Os caminhos confirmados no Excel são:

- `Dados Suastrans`
- `Dados MaxTrack`
- `Dados Tableau`
- `Manutenção e Disponibilidade`

## Consultas novas de negócio

- `PreventivaRodante` — preventiva por KM/data.
- `ManoTer` — menor validade entre 02.01, 02.03 e 02.04.
- `Medidor` — 02.02 Medidor Mássico.
- `AtualizacaoMae` — tabela única para PROCV/XLOOKUP documental.
- `OSOperacional` — complementa `Tableu` com ação operacional.
- `DocumentosOperacionais` — camada auxiliar da SuasTrans.
- `AcoesOperacionais` — fila única do que exige ação.
- `QualidadeDados` — exceções/auditoria.
- `ValidacaoMigracao_v2` — validação manual depois de mudanças estruturais.

## Dependências

- `ManoTer` -> `SuasTrans`
- `Medidor` -> `SuasTrans`
- `AtualizacaoMae` -> `SuasTrans`
- `DocumentosOperacionais` -> `SuasTrans`
- `OSOperacional` -> `Tableu`
- `AcoesOperacionais` -> `PreventivaRodante` + `DocumentosOperacionais` + `OSOperacional`
- `QualidadeDados` -> várias bases; usar como auditoria, não como consulta leve de rotina

## Carregamento recomendado

### Visíveis

- Ações Operacionais
- Preventiva Rodante
- SuasTrans
- OS Operacional — após comparação
- Atualização Mãe
- Qualidade dos Dados

### Opcionais durante transição

- Mano-Ter
- Medidor

### Somente conexão / staging

- FontePlanilhaMae_Contents
- FonteSuasTrans_Contents
- FonteMaxTrack_Contents
- FonteTableu_Contents
- ConsultarFrotasNordeste
- Tableu
- DocumentosOperacionais

`QualidadeDados` e `ValidacaoMigracao_v2` não devem participar de refresh automático frequente depois da estabilização.

## Atualização Mãe

Uma linha por placa com:

- CIV
- Crono
- CIPP
- TH
- Medidor — 02.02
- Mano/Ter — pior/menor validade entre 02.01, 02.03 e 02.04
- Documento Mano/Ter mais próximo
- CRLV
- integridade

Depois de comparar os resultados, ela pode substituir como fonte de PROCV/XLOOKUP as cargas simples antigas:

- CIV
- Crono
- CIPP
- TH
- Medidores
- Mássico
- CRLV

## Medidor

`Medidor` representa exclusivamente `02.02 - Calibração - Medidor Mássico`.

NUCLEO, Filial e Frota são obtidos da própria `SuasTrans`, eliminando o problema anterior de `NUCLEO = null` causado pela diferença entre `Núcleo` e `NUCLEO`.

## Mano/Ter

Considera:

- 02.01 — Manômetro Vertical
- 02.03 — Termômetro
- 02.04 — Manômetro Horizontal

A coluna `Mano/Ter` usa a menor validade das três. `Documento mais próximo` identifica qual item determinou a data e mostra empates.

## OS Operacional

A consulta `Tableu` continua sendo staging.

- COMP -> FECHAR NO MÁXIMO
- APROG -> COBRAR MECÂNICA
- FECHAR -> SEM AÇÃO

A aba `Tableu` pode deixar de ser carregada depois da validação, mas a consulta não pode ser excluída enquanto `OSOperacional` depender dela.

## Camada visual

Não existe mais `ResumoOperacional`.

Os cartões da página Ações Operacionais devem ser fórmulas sobre a própria `tbAcoesOperacionais`. Assim o visual não cria uma segunda avaliação da árvore de Power Query apenas para contar linhas.

## Performance

Ganho esperado vem de três frentes:

1. reduzir enumeração ampla de SharePoint com as fontes `SharePoint.Contents`;
2. substituir sete cargas documentais simples por `AtualizacaoMae`;
3. evitar consultas auxiliares de visual e refresh automático desnecessário.

O arquivo original tinha atualização ao abrir, intervalo de 60 minutos e atualização em segundo plano nas consultas-base. A política final deve ser definida depois da medição no Excel corporativo.

## Segurança

Não alterar níveis de privacidade corporativos para contornar `Formula.Firewall`.

Se ocorrer firewall, registrar consulta e etapa e tratar a arquitetura da combinação de fontes.
