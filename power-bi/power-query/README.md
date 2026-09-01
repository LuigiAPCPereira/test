# Power Query — Power BI

## Estratégia

O Power Query do Power BI será dividido em camadas para separar acesso remoto, normalização e tabelas carregadas no modelo.

```text
SharePoint
  ↓
stg_SP_*
  ↓
stg_*Raw / stg_*Normalizado
  ↓
Dim* / Fact*
```

## Camada 1 — staging remoto

Consultas:

- `stg_SP_PlanilhaMae`
- `stg_SP_SuaTrans`
- `stg_SP_MaxTrack`
- `stg_SP_Tableau`

Responsabilidade:

- conectar ao site;
- navegar diretamente até a pasta correta;
- preservar metadados dos arquivos;
- não aplicar regra de negócio.

Observação de nomenclatura: o sistema/modelo é tratado como **SuaTrans**. A pasta física do SharePoint permanece `Dados Suastrans`, pois esse é o nome real no ambiente corporativo.

Configuração recomendada no Power BI Desktop:

- **Enable load: off**;
- manter como consultas auxiliares;
- não criar visuais ou medidas diretamente sobre elas.

## Camada 2 — staging de conteúdo

Consultas em construção:

- `stg_Frota`
- `stg_SuaTransRaw`
- `stg_DocumentosNormalizados`
- `stg_MaxTrackRaw`
- `stg_OSRaw`

A camada raw deve preservar informação suficiente para auditoria. Em especial, `stg_SuaTransRaw` não deve deduplicar placa + documento antes que a qualidade possa inspecionar repetições.

`stg_SuaTransRaw` seleciona o export corrente para a V1, abre a primeira planilha válida, preserva os registros antes de filtros de negócio e adiciona metadados `SourceFile`, `SourceCreated` e `SourceModified` para rastreabilidade.

## Camada 3 — modelo

Planejada para as fases seguintes:

- `DimFrota`
- `DimDocumento`
- `DimData`
- `FactDocumentos`
- `FactPreventivaAtual`
- `FactOS`
- `FactQualidade`

## Arquivo corrente versus histórico

Na primeira versão, as consultas de negócio ainda usarão o arquivo corrente após validar a regra de seleção.

Os arquivos antigos permanecerão visíveis no staging para futura avaliação histórica, mas não serão combinados automaticamente até existir evidência de timestamp confiável.

## Performance

Prioridades:

1. navegação direta com `SharePoint.Contents`;
2. evitar reenumeração ampla do site;
3. staging remoto reutilizável;
4. desligar carga de consultas auxiliares;
5. preservar clareza do fluxo antes de micro-otimizações;
6. usar `Table.Buffer` somente após medição e justificativa.

## Segurança

Não alterar níveis de privacidade corporativos para contornar `Formula.Firewall`.

Qualquer erro de firewall deve ser tratado como problema de arquitetura/combinação de fontes e documentado antes de continuar.
