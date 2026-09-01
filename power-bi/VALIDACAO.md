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

Resultado informado:

- consulta abriu sem erro;
- export corrente `Sisdocs.xlsx` foi lido;
- estrutura esperada apareceu;
- `SourceFile`, `SourceCreated` e `SourceModified` foram preservados;
- a camada possui mais de 999 linhas, coerente com seu papel raw;
- nenhum filtro de frota Nordeste, nove documentos ou deduplicação foi aplicado nessa camada.

### 2C.2 — `stg_Documentos` — AGUARDANDO VALIDAÇÃO

Objetivo:

- partir de `stg_SuaTransRaw`;
- manter apenas registros `Tipo = Veículo`;
- manter somente os nove documentos de negócio;
- cruzar pela placa normalizada com `stg_Frota` usando `Inner Join`, excluindo do modelo de negócio entidades fora da frota oficial;
- preservar valor bruto de placa/frota, status de origem e validade de origem;
- calcular status documental sem substituir o status de origem;
- contar ocorrências por `Placa + Tipo de Documento`;
- **não** executar `Table.Distinct`.

Nove tipos esperados:

1. `02.01 - Calibração - Manômetro Analógico Vertical`
2. `02.02 - Calibração - Medidor Mássico`
3. `02.03 - Calibração - Termometro Analógico`
4. `02.04 - Calibração - Manômetro Analógico Horizontal`
5. `02.05 - CIPP`
6. `02.06 - CIV`
7. `02.07 - CRLV`
8. `02.08 - Cronotacógrafo`
9. `02.25 - Teste Hidrostático - Mangueira Flexível`

Validar no Desktop:

- consulta abre sem erro;
- apenas placas oficiais aparecem;
- códigos documentais estão restritos aos nove esperados;
- `Status Fonte` e `Status Calculado` coexistem;
- `Qtd Registros Placa Documento` é calculada;
- linhas com `Multiplicidade = MÚLTIPLOS REGISTROS` continuam presentes.

### Decisão pendente antes da FactDocumentos

`MÚLTIPLOS REGISTROS` ainda não significa automaticamente erro.

Investigar amostras para determinar se representam:

- histórico/renovação legítima do mesmo documento; ou
- repetição indevida do mesmo registro.

Somente depois dessa análise será definida a seleção do documento corrente. Nenhuma deduplicação poderá ser aplicada antes dessa decisão.

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
