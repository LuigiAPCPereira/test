# Validação — Power BI Controle de Frotas Nordeste

Este documento define gates antes de avançar entre as fases do Power BI.

## Gate 2A — Fontes SharePoint

Validar no Power BI Desktop cada consulta `stg_SP_*` isoladamente.

### stg_SP_PlanilhaMae

Esperado:

- navegar somente até `Documentos Compartilhados/Manutenção e Disponibilidade`;
- encontrar `Programações Paradas Frotas.xlsm`;
- preservar `Content`, `Name`, `Date created`, `Date modified`, `Folder Path` e `Extension` quando disponíveis.

### stg_SP_SuasTrans

Esperado:

- navegar somente até `Documentos Compartilhados/Dados Suastrans`;
- listar os exports válidos da pasta;
- não enumerar o site inteiro.

### stg_SP_MaxTrack

Esperado:

- navegar somente até `Documentos Compartilhados/Dados MaxTrack`;
- listar os exports válidos da pasta;
- não enumerar o site inteiro.

### stg_SP_Tableau

Esperado:

- navegar somente até `Documentos Compartilhados/Dados Tableau`;
- listar os exports válidos da pasta;
- não enumerar o site inteiro.

### Gate de segurança

Se ocorrer `Formula.Firewall`, erro de credencial, biblioteca/pasta não encontrada ou diferença estrutural:

1. registrar a consulta e etapa exatas;
2. não reduzir níveis de privacidade para contornar o erro;
3. não continuar para as transformações de negócio até entender a causa.

## Gate 2B — Frota oficial

Antes de criar `DimFrota`:

- filtrar `Mercado = Empresarial Nordeste` dinamicamente;
- nenhuma placa vazia;
- validar `COUNT(Placa) = DISTINCTCOUNT(Placa)`;
- validar se `Frota` é única e documentar exceções;
- não hardcodar 57 veículos;
- comparar amostras com a planilha mãe.

## Gate 2C — SuasTrans raw e documentos

A camada raw deve existir antes do recorte corrente.

Validar:

- nove códigos documentais esperados;
- placa normalizada;
- veículo fora da frota oficial não entra no modelo de negócio;
- registros repetidos ainda estão disponíveis na camada usada pela qualidade;
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