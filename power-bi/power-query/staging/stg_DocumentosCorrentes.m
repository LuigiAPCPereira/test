let
    // ============================================================
    // STAGING — DOCUMENTOS CORRENTES CANÔNICOS
    // Origem: stg_Documentos + stg_DocumentosAuditoria
    // Granularidade: 1 linha por Placa + Tipo de Documento
    //
    // Regra:
    // - maior validade representa o documento corrente;
    // - empates entre filiais são reduzidos deterministicamente;
    // - multiplicidade permanece visível via colunas de auditoria;
    // - nenhum problema de origem é apagado da camada detalhada.
    // ============================================================

    Fonte = stg_Documentos,

    AddValidadeOrdem = Table.AddColumn(
        Fonte,
        "Validade Ordem",
        each if [Validade] = null then #date(1900, 1, 1) else [Validade],
        type date
    ),

    OrdenarParaSelecao = Table.Sort(
        AddValidadeOrdem,
        {
            {"Placa Normalizada", Order.Ascending},
            {"Tipo de Documento", Order.Ascending},
            {"Validade Ordem", Order.Descending},
            {"SourceModified", Order.Descending},
            {"Filial SuaTrans", Order.Ascending}
        }
    ),

    AgruparDocumento = Table.Group(
        OrdenarParaSelecao,
        {"Placa Normalizada", "Tipo de Documento"},
        {
            {
                "Registro Corrente",
                each Table.FirstN(_, 1)
            }
        }
    ),

    ColunasRegistro = List.RemoveItems(
        Table.ColumnNames(OrdenarParaSelecao),
        {"Placa Normalizada", "Tipo de Documento"}
    ),

    ExpandirRegistro = Table.ExpandTableColumn(
        AgruparDocumento,
        "Registro Corrente",
        ColunasRegistro,
        ColunasRegistro
    ),

    RemoverValidadeOrdem = Table.RemoveColumns(
        ExpandirRegistro,
        {"Validade Ordem"},
        MissingField.Ignore
    ),

    Auditoria = Table.SelectColumns(
        stg_DocumentosAuditoria,
        {
            "Placa Normalizada",
            "Tipo de Documento",
            "Qtd Registros",
            "Qtd Validades Distintas",
            "Validades",
            "Qtd Filiais SuaTrans Distintas",
            "Filiais SuaTrans",
            "Classificação Multiplicidade",
            "Requer Revisão"
        }
    ),

    MergeAuditoria = Table.NestedJoin(
        RemoverValidadeOrdem,
        {"Placa Normalizada", "Tipo de Documento"},
        Auditoria,
        {"Placa Normalizada", "Tipo de Documento"},
        "Auditoria",
        JoinKind.LeftOuter
    ),

    ExpandAuditoria = Table.ExpandTableColumn(
        MergeAuditoria,
        "Auditoria",
        {
            "Qtd Registros",
            "Qtd Validades Distintas",
            "Validades",
            "Qtd Filiais SuaTrans Distintas",
            "Filiais SuaTrans",
            "Classificação Multiplicidade",
            "Requer Revisão"
        },
        {
            "Qtd Registros Origem",
            "Qtd Validades Distintas Origem",
            "Validades Origem Agrupadas",
            "Qtd Filiais SuaTrans Distintas",
            "Filiais SuaTrans Origem",
            "Classificação Multiplicidade",
            "Requer Revisão"
        }
    ),

    AddSelecaoCanonica = Table.AddColumn(
        ExpandAuditoria,
        "Seleção Canônica",
        each
            if [Classificação Multiplicidade] = "ÚNICO" then "REGISTRO ÚNICO"
            else if [Classificação Multiplicidade] = "DUPLICIDADE ENTRE FILIAIS" then "MAIOR VALIDADE + DESEMPATE DETERMINÍSTICO"
            else if [Classificação Multiplicidade] = "RENOVAÇÃO POSSÍVEL" then "MAIOR VALIDADE — REVISAR HISTÓRICO"
            else "MAIOR VALIDADE — REVISAR DUPLICIDADE",
        type text
    ),

    Resultado = Table.Sort(
        AddSelecaoCanonica,
        {
            {"Núcleo", Order.Ascending},
            {"Filial", Order.Ascending},
            {"Placa", Order.Ascending},
            {"Código Documento", Order.Ascending}
        }
    )
in
    Resultado
