# Modelo de Dados V1

## Princípio

O Power BI não será uma reprodução visual das abas do Excel. O modelo deve separar dimensões, fatos de domínio, staging e camadas derivadas de apresentação.

## Diagrama conceitual

```text
                         DimData
                       /    |    \
                      /     |     \
                     /      |      \
            FactPreventiva  |    FactOS
                    \       |       /
                     \      |      /
                      \     |     /
                       DimFrota
                          |
                          |
                    FactDocumentos
                          |
                     DimDocumento

                       DimFrota
                          |
                   FactQualidade
```

Nome final da fato de preventiva no V1: `FactPreventivaAtual`.

## DimFrota

**Origem autoritativa:** `Programações Paradas Frotas.xlsm`, aba `Base de Dados`, filtrada para `Mercado = Empresarial Nordeste`.

**Granularidade:** 1 linha por veículo oficial.

Campos mínimos:

- `VeiculoKey`
- `Placa`
- `Frota`
- `Núcleo`
- `Filial`
- `Proprietário`
- `Mercado`

### Chave

`VeiculoKey` será baseada na placa normalizada, de forma determinística entre refreshes. A transformação deve, no mínimo:

- remover espaços externos;
- converter para maiúsculas;
- remover hífen e espaços internos de formatação.

A placa original normalizada para exibição continua disponível como atributo de negócio.

Antes de carregar `DimFrota`, validar explicitamente unicidade de `Placa` e investigar a unicidade de `Frota`.

## DimDocumento

**Granularidade:** 1 linha por tipo documental.

Catálogo inicial:

| Código | Documento | Grupo |
|---|---|---|
| 02.01 | Manômetro Analógico Vertical | Mano/Ter |
| 02.02 | Medidor Mássico | Medidor |
| 02.03 | Termômetro Analógico | Mano/Ter |
| 02.04 | Manômetro Analógico Horizontal | Mano/Ter |
| 02.05 | CIPP | Documento |
| 02.06 | CIV | Documento |
| 02.07 | CRLV | Documento |
| 02.08 | Cronotacógrafo | Documento |
| 02.25 | Teste Hidrostático - Mangueira Flexível | Documento |

Campos previstos:

- `DocumentoKey`
- `CodigoDocumento`
- `TipoDocumento`
- `GrupoDocumento`
- `EhManoTer`
- `EhMedidor`
- `OrdemExibicao`

## DimData

**Granularidade:** 1 linha por data.

Campos previstos:

- `Data`
- `Ano`
- `MesNumero`
- `Mes`
- `AnoMes`
- `AnoMesOrdem`
- `Trimestre`
- `Semestre`
- `Dia`
- `DiaSemana`

Relacionamentos de data principais:

- `DimData[Data]` → `FactDocumentos[Validade]`
- `DimData[Data]` → `FactPreventivaAtual[DataProximaPreventiva]`
- `DimData[Data]` → `FactOS[DataSolicitacao]`

Datas secundárias, como `DataAlteracao` e `DataReferencia`, devem usar relacionamentos inativos quando necessário e medidas com `USERELATIONSHIP`, em vez de criar ambiguidade.

Segmentadores de mês/data devem ser preferencialmente específicos por página, porque uma mesma data possui papéis diferentes em documentos, preventiva e OS.

## FactDocumentos

**Granularidade V1:** 1 veículo + 1 tipo de documento corrente.

Campos previstos:

- `VeiculoKey`
- `DocumentoKey`
- `Validade`
- `Status`
- `DiasParaVencer`
- `DataReferencia`
- metadados de origem úteis à rastreabilidade

A camada raw/normalizada anterior a esta fato deve preservar registros duplicados. A escolha do registro documental corrente só ocorre depois que a qualidade puder avaliar os registros originais.

### Mano/Ter

Não criar `FactManoTer`.

Mano/Ter é uma derivação de `FactDocumentos`: menor validade entre 02.01, 02.03 e 02.04. O documento limitante é o documento cuja validade corresponde ao mínimo, incluindo empates.

### Medidor

Não criar `FactMedidor`.

Medidor é a visão do documento 02.02 dentro de `FactDocumentos`.

## FactPreventivaAtual

**Granularidade:** 1 linha por veículo oficial na fotografia do último refresh.

Campos previstos:

- `VeiculoKey`
- `KMAtual`
- `KMUltimaPreventiva`
- `KMProximaPreventiva`
- `KMDesdeUltimaPreventiva`
- `IntervaloPlanejado`
- `KMRestante`
- `FaixaKM`
- `DataProximaPreventiva`
- `DiasParaPreventiva`
- `SituacaoData`
- `SituacaoGeral`
- `DataReferencia`
- `Integridade`

Regra de KM:

`KMRestante = KMProximaPreventiva - KMAtual`

A fonte de verdade do próximo KM é a planilha mãe. Não assumir +20.000 km porque existem intervalos diferentes, incluindo casos de 30.000 km.

Faixas atuais:

- `< -2000` → CRÍTICA
- `<= 0` → VENCIDA
- `<= 2000` → PROGRAMAR
- `<= 3000` → ATENÇÃO
- `<= 5000` → MONITORAR
- `> 5000` → OK

A situação geral considera o pior estado entre KM e data.

## FactOS

**Granularidade desejada:** 1 linha por ordem de serviço.

Antes de fixar a granularidade, validar se `OS` é realmente única após os filtros do export Tableau/Maximo.

Campos previstos:

- `VeiculoKey`
- `OS`
- `StatusOS`
- `Descricao`
- `Recorrencia`
- `TipoServico`
- `Responsavel`
- `DataSolicitacao`
- `DataAlteracao`
- `DiasDesdeSolicitacao`
- `DiasEmAberto`
- `AcaoOperacional`

Mapeamento operacional:

- `APROG` → `COBRAR MECÂNICA`
- `COMP` → `FECHAR NO MÁXIMO`
- `FECHAR` → `SEM AÇÃO`
- outros → `REVISAR STATUS`

`DiasEmAberto` não deve tratar OS já encerrada como se continuasse aberta. Enquanto não houver uma data de fechamento confiável, manter separação entre `DiasDesdeSolicitacao` e `DiasEmAberto`.

## FactQualidade

**Granularidade:** 1 linha por problema detectado.

Campos previstos:

- `VeiculoKey`
- `Gravidade`
- `Origem`
- `Problema`
- `Detalhe`
- `DataReferencia`

Exemplos:

- placa sem KM;
- placa duplicada;
- documento faltante;
- documento duplicado;
- preventiva sem dados suficientes;
- status de OS fora do fluxo esperado.

## FilaOperacional

`FilaOperacional` será uma tabela derivada de apresentação, não um fato canônico.

Ela poderá combinar itens acionáveis de:

- `FactPreventivaAtual`
- `FactDocumentos`
- `FactOS`

Os KPIs de gestão devem ser calculados diretamente nas fatos de domínio. A fila serve para navegação, priorização e exibição integrada.

## Relacionamentos

Padrão:

```text
DimFrota      1 -> * FactPreventivaAtual
DimFrota      1 -> * FactDocumentos
DimFrota      1 -> * FactOS
DimFrota      1 -> * FactQualidade
DimDocumento  1 -> * FactDocumentos
DimData       1 -> * fatos por suas datas principais
```

Filtro cruzado padrão: unidirecional, dimensão → fato.

Evitar relacionamentos bidirecionais por padrão.