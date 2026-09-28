# Power BI — Controle de Frotas Nordeste

## Objetivo

Construir a camada analítica e gerencial do Controle de Frotas Nordeste sem substituir o Excel operacional.

- Excel: operação, atualização, conferência e interação com a planilha mãe.
- Power BI: gestão, análise, indicadores, acompanhamento e apresentação.

O Power BI deve consumir as mesmas fontes corporativas do fluxo Excel, e não o arquivo `Controle de Frotas Nordeste.xlsx` como fonte analítica.

## Estado

- Fase 1 — investigação do repositório e modelo de dados: **APROVADA**.
- Fase 2 — staging / Power Query para Power BI: **EM ANDAMENTO**.
  - Gate 2A — fontes SharePoint: **PASS**.
  - Gate 2B — frota oficial: **PASS**.
  - Gate 2C — SuaTrans raw/documentos: **EM ANDAMENTO**.
- Fases 3–8: ainda não iniciadas.

## Modelo V1 aprovado

Dimensões:

- `DimFrota`
- `DimDocumento`
- `DimData`

Fatos canônicos:

- `FactPreventivaAtual`
- `FactDocumentos`
- `FactOS`
- `FactQualidade`

Camada derivada de apresentação:

- `FilaOperacional`

`FilaOperacional` não será a autoridade dos KPIs. As medidas gerenciais devem ser calculadas nos fatos de domínio.

## Regras de arquitetura

1. Não alterar o XLSX operacional para construir o Power BI.
2. Não depender das abas finais do Excel como fonte do modelo.
3. Manter staging técnico separado das tabelas carregadas no modelo.
4. Usar `SharePoint.Contents(..., [ApiVersion = 15, Implementation = "2.0"])` e navegação direta até as pastas necessárias.
5. Evitar `SharePoint.Files` enumerando sites inteiros sem justificativa documentada.
6. Preservar registros antes de deduplicações para permitir auditoria real de qualidade.
7. Não usar `Table.Buffer` indiscriminadamente.
8. Não hardcodar quantidade de veículos; a frota oficial vem da planilha mãe.
9. Relacionamentos do modelo devem ser, por padrão, `1:*`, com filtro unidirecional dimensão → fato.
10. Não criar dashboard antes da validação do staging e do modelo relacional.

## Nomenclatura SuaTrans

O nome usado no modelo e na documentação nova é **SuaTrans**.

A pasta física do SharePoint continua chamada `Dados Suastrans`; esse texto é preservado apenas quando representa literalmente o caminho corporativo existente.

## Estrutura atual

```text
power-bi/
  README.md
  MODELO_DADOS.md
  FONTES.md
  VALIDACAO.md

  power-query/
    README.md
    staging/
      stg_SP_PlanilhaMae.m
      stg_SP_SuaTrans.m
      stg_SP_MaxTrack.m
      stg_SP_Tableau.m
      stg_Frota.m
      stg_SuaTransRaw.m
      ...

  dax/
    medidas.md

  theme/
    tema-frotas-nordeste.json

  pages/
    VISAO_GERAL.md
    PREVENTIVA.md
    DOCUMENTOS.md
    OS.md
    VEICULO.md
    QUALIDADE.md
```

As pastas de DAX, tema e páginas serão criadas apenas quando as fases correspondentes começarem.

## Referências do fluxo Excel

A lógica existente em `excel/power-query/` é referência funcional, inclusive quando nomes legados ainda aparecem nos arquivos históricos do Excel, principalmente:

- `ConsultarFrotasNordeste_Contents.m`
- `SuasTrans_Contents.m`
- `MaxTrack_Contents.m`
- `Tableu_Contents.m`
- `Medidor.m`
- `ManoTer.m`
- `OSOperacional.m`
- `DocumentosOperacionais.m`
- `AcoesOperacionais.m`
- `QualidadeDados.m`

O código não deve ser copiado cegamente: decisões específicas do Excel devem ser adaptadas ao modelo analítico.
