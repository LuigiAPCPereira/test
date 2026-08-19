let
    // ============================================================
    // RESUMO OPERACIONAL — CAMADA VISUAL
    //
    // Gera uma linha por núcleo + TOTAL a partir da fila
    // AcoesOperacionais. Não lê SharePoint diretamente.
    // ============================================================

    Fonte0 = Table.TransformColumns(
        AcoesOperacionais,
        {
            {"NUCLEO", each if _ = null or Text.Trim(Text.From(_)) = "" then "SEM NÚCLEO" else Text.Trim(Text.From(_)), type text},
            {"CATEGORIA", each if _ = null then "SEM CATEGORIA" else Text.Upper(Text.Trim(Text.From(_))), type text},
            {"AÇÃO", each if _ = null then "REVISAR" else Text.Upper(Text.Trim(Text.From(_))), type text},
            {"PRIORIDADE", each if _ = null then "REVISAR" else Text.Upper(Text.Trim(Text.From(_))), type text}
        },
        null,
        MissingField.Ignore
    ),

    Fonte = Table.Buffer(Fonte0),

    ResumoNucleo = Table.Group(
        Fonte,
        {"NUCLEO"},
        {
            {"TOTAL AÇÕES", each Table.RowCount(_), Int64.Type},
            {"URGENTES", each Table.RowCount(Table.SelectRows(_, each [PRIORIDADE] = "URGENTE")), Int64.Type},
            {"PREVENTIVAS", each Table.RowCount(Table.SelectRows(_, each [CATEGORIA] = "PREVENTIVA RODANTE")), Int64.Type},
            {"DOCUMENTOS", each Table.RowCount(Table.SelectRows(_, each [CATEGORIA] = "DOCUMENTAÇÃO")), Int64.Type},
            {"OS", each Table.RowCount(Table.SelectRows(_, each [CATEGORIA] = "ORDEM DE SERVIÇO")), Int64.Type},
            {"FECHAR NO MÁXIMO", each Table.RowCount(Table.SelectRows(_, each [AÇÃO] = "FECHAR NO MÁXIMO")), Int64.Type},
            {"COBRAR MECÂNICA", each Table.RowCount(Table.SelectRows(_, each [AÇÃO] = "COBRAR MECÂNICA")), Int64.Type},
            {"REGULARIZAR DOCUMENTO", each Table.RowCount(Table.SelectRows(_, each [AÇÃO] = "REGULARIZAR DOCUMENTO")), Int64.Type},
            {"PROGRAMAR RENOVAÇÃO", each Table.RowCount(Table.SelectRows(_, each [AÇÃO] = "PROGRAMAR RENOVAÇÃO")), Int64.Type},
            {"PROGRAMAR PREVENTIVA", each Table.RowCount(Table.SelectRows(_, each [AÇÃO] = "PROGRAMAR PREVENTIVA" or [AÇÃO] = "TRATAR PREVENTIVA")), Int64.Type}
        }
    ),

    Total = #table(
        Table.ColumnNames(ResumoNucleo),
        {{
            "TOTAL",
            Table.RowCount(Fonte),
            Table.RowCount(Table.SelectRows(Fonte, each [PRIORIDADE] = "URGENTE")),
            Table.RowCount(Table.SelectRows(Fonte, each [CATEGORIA] = "PREVENTIVA RODANTE")),
            Table.RowCount(Table.SelectRows(Fonte, each [CATEGORIA] = "DOCUMENTAÇÃO")),
            Table.RowCount(Table.SelectRows(Fonte, each [CATEGORIA] = "ORDEM DE SERVIÇO")),
            Table.RowCount(Table.SelectRows(Fonte, each [AÇÃO] = "FECHAR NO MÁXIMO")),
            Table.RowCount(Table.SelectRows(Fonte, each [AÇÃO] = "COBRAR MECÂNICA")),
            Table.RowCount(Table.SelectRows(Fonte, each [AÇÃO] = "REGULARIZAR DOCUMENTO")),
            Table.RowCount(Table.SelectRows(Fonte, each [AÇÃO] = "PROGRAMAR RENOVAÇÃO")),
            Table.RowCount(Table.SelectRows(Fonte, each [AÇÃO] = "PROGRAMAR PREVENTIVA" or [AÇÃO] = "TRATAR PREVENTIVA"))
        }}
    ),

    Combinar = Table.Combine({ResumoNucleo, Total}),

    AddOrdem = Table.AddColumn(
        Combinar,
        "ORDEM",
        each if [NUCLEO] = "TOTAL" then 0 else 1,
        Int64.Type
    ),

    Ordenar = Table.Sort(AddOrdem, {{"ORDEM", Order.Ascending}, {"TOTAL AÇÕES", Order.Descending}, {"NUCLEO", Order.Ascending}}),
    Resultado = Table.RemoveColumns(Ordenar, {"ORDEM"})
in
    Resultado
