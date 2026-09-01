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

A camada raw deve existir antes do recorte corrente.

Consulta inicial:

- `stg_SuaTransRaw`

Validar:

- o arquivo corrente selecionado é o export esperado;
- as colunas estruturais do export são reconhecidas;
- `SourceFile`, `SourceCreated` e `SourceModified` são preservados;
- nove códigos documentais esperados podem ser encontrados após o recorte de negócio;
- placa poderá ser normalizada sem perder o valor bruto necessário à auditoria;
- veículo fora da frota oficial não entrará no modelo de negócio;
- registros repetidos continuam disponíveis na camada usada pela qualidade;
- nenhum `Table.Distinct` impede a auditoria de duplicidades antes da classificação.

Investigar a semântica de múltiplos registros para a mesma placa/documento:

- histórico de renovação legítimo; ou
- duplicidade indevida.

Somente após essa validação definir a regra para escolher o documento corrente em `FactDocumentos`.

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
