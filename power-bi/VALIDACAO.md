# Validação — Power BI Controle de Frotas Nordeste

Este documento define gates antes de avançar entre as fases do Power BI.

## Gate 2A — Fontes SharePoint — PASS

Validado no Power BI Desktop em 2026-09-01.

Resultado:

- `stg_SP_PlanilhaMae` abriu `Documentos Compartilhados/Manutenção e Disponibilidade` e encontrou `Programações Paradas Frotas.xlsm`;
- `stg_SP_SuaTrans` abriu a pasta física `Documentos Compartilhados/Dados Suastrans` e encontrou o export `Sisdocs.xlsx`;
- `stg_SP_MaxTrack` abriu a pasta correta;
- `stg_SP_Tableau` abriu a pasta correta;
- autenticação corporativa funcionou;
- não ocorreu `Formula.Firewall`;
- não foi necessário enumerar o site inteiro com `SharePoint.Files`.

Observação de nomenclatura: o projeto usa **SuaTrans**; `Suastrans` permanece apenas no nome físico da pasta SharePoint.

### Gate de segurança

Se ocorrer `Formula.Firewall`, erro de credencial, biblioteca/pasta não encontrada ou diferença estrutural em refresh futuro:

1. registrar a consulta e etapa exatas;
2. não reduzir níveis de privacidade para contornar o erro;
3. não continuar para as transformações de negócio até entender a causa.

## Gate 2B — Frota oficial — PASS

Validado no Power BI Desktop em 2026-09-01 com `stg_Frota`.

Resultado informado:

- `Mercado = Empresarial Nordeste` filtrado dinamicamente;
- nenhuma placa vazia;
- nenhuma placa duplicada;
- nenhuma frota vazia;
- nenhuma frota duplicada;
- coluna `Integridade` sem exceções;
- nenhuma quantidade de veículos foi hardcodada.

Com isso, `stg_Frota` está apta a servir de origem para a futura `DimFrota`.

## Gate 2C — SuaTrans raw e documentos — EM ANDAMENTO

### 2C.1 — `stg_SuaTransRaw` — PASS

Validado no Power BI Desktop em 2026-09-01.

Resultado:

- consulta abriu sem erro;
- export corrente `Sisdocs.xlsx` foi lido;
- estrutura esperada apareceu;
- `SourceFile`, `SourceCreated` e `SourceModified` foram preservados;
- a camada possui mais de 999 linhas, coerente com seu papel raw;
- nenhum filtro de frota Nordeste, nove documentos ou deduplicação foi aplicado nessa camada.

### 2C.2 — `stg_Documentos` — PASS ESTRUTURAL

Validado no Power BI Desktop em 2026-09-01.

A consulta:

- parte de `stg_SuaTransRaw`;
- mantém apenas registros `Tipo = Veículo`;
- mantém somente os nove documentos de negócio;
- cruza pela placa normalizada com `stg_Frota` usando `Inner Join`;
- preserva placa/frota, filial, status e validade vindos do SuaTrans;
- calcula status documental sem substituir o status de origem;
- conta ocorrências por `Placa + Tipo de Documento`;
- não executa `Table.Distinct`.

### Evidência real de multiplicidade

Amostra validada para a placa `DKZ4571` / frota `F15794`:

- os nove documentos aparecem com três ocorrências por placa + documento;
- para cada documento da amostra, as três ocorrências têm a mesma validade;
- as ocorrências vêm de `FILIAL CAUCAIA`, `FILIAL MIRAMAR` e `FILIAL SÃO LUIS`;
- a amostra não representa três renovações documentais;
- trata-se de duplicidade de negócio entre filiais para a mesma placa + documento + validade.

### 2C.3 — `stg_DocumentosAuditoria` — PASS

Validado no Power BI Desktop em 2026-09-01.

Classificações encontradas no conjunto atual:

- `ÚNICO`;
- `DUPLICIDADE ENTRE FILIAIS`.

Não foram encontradas no conjunto atual:

- `RENOVAÇÃO POSSÍVEL`;
- `DUPLICIDADE MESMA VALIDADE` sem evidência de filiais diferentes.

Também foi observado que `Requer Revisão` contém `TRUE` e `FALSE`, como esperado para distinguir linhas únicas de linhas com multiplicidade.

Exemplos de grupos de filiais observados incluem:

- `FILIAL CAUCAIA | FILIAL MIRAMAR | FILIAL SÃO LUIS`;
- `FILIAL JOÃO PESSOA | FILIAL MACEIO | FILIAL SUAPE`;
- `FILIAL CAUCAIA | FILIAL MUCURIPE`.

Conclusão do diagnóstico atual:

- multiplicidades observadas são predominantemente espelhos entre filiais;
- elas não devem multiplicar as linhas do modelo analítico;
- a evidência deve continuar disponível para auditoria e futura `FactQualidade`.

### 2C.4 — `stg_DocumentosCorrentes` — AGUARDANDO VALIDAÇÃO

Consulta canônica criada com granularidade de uma linha por `Placa + Tipo de Documento`.

Regra de seleção:

1. maior `Validade`;
2. em empate, maior `SourceModified`;
3. em novo empate, `Filial SuaTrans` em ordem alfabética apenas para obter resultado determinístico.

A seleção ocorre dentro de cada grupo, sem depender da ordem externa do Power Query.

A consulta mantém os indicadores da auditoria:

- `Qtd Registros Origem`;
- `Qtd Validades Distintas Origem`;
- `Validades Origem Agrupadas`;
- `Qtd Filiais SuaTrans Distintas`;
- `Filiais SuaTrans Origem`;
- `Classificação Multiplicidade`;
- `Requer Revisão`;
- `Seleção Canônica`.

Validar no Desktop:

- consulta abre sem erro;
- existe no máximo uma linha por `Placa + Tipo de Documento`;
- a placa `DKZ4571` passa de 27 linhas detalhadas para 9 linhas canônicas;
- as validades escolhidas são as mesmas observadas no conjunto detalhado;
- as linhas continuam indicando `DUPLICIDADE ENTRE FILIAIS` quando essa condição existia na origem.

Somente após esse teste o Gate 2C será fechado e a camada poderá servir de base para `FactDocumentos`.

## Gate 2D — MaxTrack

Validar:

- cobertura das placas oficiais;
- ausência de duplicidade não explicada por placa;
- transformação do odômetro para KM inteiro;
- amostras comparadas com o export original.

## Gate 2E — Tableau / Maximo

Validar:

- filtros de escopo equivalentes ao fluxo atual (`FILIAL = 34`, tipo de serviço `GP` e frota Nordeste);
- vínculo Frota → Placa confiável;
- unicidade real de `OS` após filtros;
- status APROG, COMP e FECHAR preservados;
- datas e responsável preservados.

Se `OS` não for única, identificar a granularidade real antes de criar `FactOS`.

## Gate 3 — Modelo relacional

Antes de DAX:

- `DimFrota` possui uma linha por veículo;
- `DimDocumento` possui uma linha por documento;
- `DimData` não possui lacunas no intervalo necessário;
- relações dimensão → fato são `1:*`;
- filtro cruzado unidirecional por padrão;
- não existem relações muitos-para-muitos não justificadas;
- não existem caminhos ambíguos de filtro.

## Gate 4 — Regras de negócio

### Preventiva

- `KM Restante = KM Próx. Prev. - KM Atual`;
- KM Próx. Prev. vem da planilha mãe;
- não assumir intervalo fixo de 20.000 km;
- situação geral usa o pior estado entre KM e data.

### Documentos

- Vencido, Expirando e Válido calculados consistentemente;
- Mano/Ter = menor validade entre 02.01, 02.03 e 02.04;
- documento Mano/Ter limitante identificado, inclusive empates;
- Medidor = 02.02.

### OS

- APROG → COBRAR MECÂNICA;
- COMP → FECHAR NO MÁXIMO;
- FECHAR → SEM AÇÃO;
- demais → REVISAR STATUS;
- `DiasDesdeSolicitacao` e `DiasEmAberto` não são tratados como sinônimos.

## Gate de regressão

Antes de cada avanço importante, comparar amostras com o fluxo Excel validado:

- veículo de NUC Bahia/Salvador;
- veículo de outro núcleo;
- documento vencido;
- documento expirando;
- OS APROG;
- OS COMP, quando existir;
- preventiva próxima do limite operacional;
- pelo menos uma exceção de qualidade, se disponível.
