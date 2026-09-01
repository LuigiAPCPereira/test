# Fontes — Power BI Controle de Frotas Nordeste

## Princípio

O Power BI deve consumir as mesmas fontes corporativas utilizadas pelo Excel operacional, mas com staging próprio. O arquivo `Controle de Frotas Nordeste.xlsx` não é fonte analítica do Power BI.

## SharePoint — Teste728

Site:

`https://grupoultracloud.sharepoint.com/teams/Teste728`

### MaxTrack

Pasta:

`Documentos Compartilhados/Dados MaxTrack`

Uso:

- KM atual / odômetro.

Staging inicial:

- `stg_SP_MaxTrack`

### SuasTrans

Pasta:

`Documentos Compartilhados/Dados Suastrans`

Uso:

- documentos;
- validade;
- situação documental.

Staging inicial:

- `stg_SP_SuasTrans`

A transformação de negócio deve preservar uma camada raw antes de qualquer deduplicação para permitir auditoria real de documentos faltantes/duplicados.

### Tableau / Maximo

Pasta:

`Documentos Compartilhados/Dados Tableau`

Uso:

- ordens de serviço;
- status;
- datas;
- responsável;
- tipo de serviço.

Staging inicial:

- `stg_SP_Tableau`

## SharePoint — Excelência em Frotas

Site:

`https://grupoultracloud.sharepoint.com/teams/UG-ExcelnciaemFrotas`

Pasta:

`Documentos Compartilhados/Manutenção e Disponibilidade`

Arquivo autoritativo:

`Programações Paradas Frotas.xlsm`

Uso:

- universo oficial da frota Nordeste;
- placa;
- frota;
- núcleo;
- filial;
- proprietário;
- mercado;
- KM da última preventiva;
- KM da próxima preventiva;
- data da próxima preventiva.

Staging inicial:

- `stg_SP_PlanilhaMae`

## Conector

Padrão aprovado:

```powerquery
SharePoint.Contents(
    SiteUrl,
    [ApiVersion = 15, Implementation = "2.0"]
)
```

A consulta deve navegar pela hierarquia `[Content]` até a biblioteca e pasta necessárias.

Não usar `SharePoint.Files` para enumerar o site inteiro sem justificativa técnica documentada.

## Metadados de origem

Sempre que disponíveis, preservar no staging:

- `Name`;
- `Content`;
- `Extension`;
- `Folder Path`;
- `Date created`;
- `Date modified`.

Esses campos são importantes para:

- rastreabilidade;
- escolha do arquivo corrente;
- diagnóstico de refresh;
- futura avaliação de snapshots históricos.

## Histórico

A existência de múltiplos exports nas pastas não é suficiente para assumir histórico confiável.

Antes de criar fatos históricos, validar se existe timestamp confiável em pelo menos uma destas formas:

- nome do arquivo;
- data de geração dentro do arquivo;
- coluna de exportação;
- metadado de criação do SharePoint com semântica estável.

`Date modified` isoladamente não deve ser assumido como data do snapshot sem validação.