let
    // ============================================================
    // OS OPERACIONAL — TABLEAU / MÁXIMO
    // ============================================================

    DataReferencia = Date.From(DateTime.FixedLocalNow()),
    InicioMesAtual = Date.StartOfMonth(DataReferencia),
    InicioMesAnterior = Date.AddMonths(InicioMesAtual, -1),

    Fonte = Table.TransformColumns(
        Tableu,
        {
            {"PLACA", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type nullable text},
            {"STATUS", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type nullable text},
            {"NUCLEO", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"DATA_DA_SOLICITACAO", each try DateTime.From(_) otherwise null, type nullable datetime}
        },
        null,
        MissingField.Ignore
    ),

    AddAcao = Table.AddColumn(
        Fonte,
        "AÇÃO OPERACIONAL",
        each
            if [STATUS] = "COMP" then "FECHAR NO MÁXIMO"
            else if [STATUS] = "APROG" then "COBRAR MECÂNICA"
            else if [STATUS] = "FECHAR" then "SEM AÇÃO"
            else "REVISAR STATUS",
        type text
    ),

    AddPrioridade = Table.AddColumn(
        AddAcao,
        "ORDEM AÇÃO",
        each
            if [#"AÇÃO OPERACIONAL"] = "FECHAR NO MÁXIMO" then 1
            else if [#"AÇÃO OPERACIONAL"] = "COBRAR MECÂNICA" then 2
            else if [#"AÇÃO OPERACIONAL"] = "REVISAR STATUS" then 3
            else 4,
        Int64.Type
    ),

    AddDataSolicitacao = Table.AddColumn(
        AddPrioridade,
        "DATA OS",
        each if [DATA_DA_SOLICITACAO] = null then null else Date.From([DATA_DA_SOLICITACAO]),
        type nullable date
    ),

    AddMesAno = Table.AddColumn(
        AddDataSolicitacao,
        "MÊS-ANO OS",
        each if [#"DATA OS"] = null
            then null
            else Date.ToText([#"DATA OS"], "yyyy-MM", "pt-BR")
                & " "
                & Text.Proper(Text.Replace(Date.ToText([#"DATA OS"], "MMM", "pt-BR"), ".", "")),
        type nullable text
    ),

    AddPeriodo = Table.AddColumn(
        AddMesAno,
        "PERÍODO",
        each
            if [#"DATA OS"] = null then "SEM DATA"
            else if [#"DATA OS"] >= InicioMesAtual then "MÊS ATUAL"
            else if [#"DATA OS"] >= InicioMesAnterior then "MÊS ANTERIOR"
            else "ANTERIOR AO MÊS PASSADO",
        type text
    ),

    AddDias = Table.AddColumn(
        AddPeriodo,
        "DIAS DESDE SOLICITAÇÃO",
        each if [#"DATA OS"] = null then null else Duration.Days(DataReferencia - [#"DATA OS"]),
        Int64.Type
    ),

    AddReferencia = Table.AddColumn(AddDias, "DATA REFERÊNCIA", each DataReferencia, type date),

    Reordenar = Table.ReorderColumns(
        AddReferencia,
        {"NUCLEO", "FILIAL", "PLACA"},
        MissingField.Ignore
    ),

    Ordenar = Table.Sort(
        Reordenar,
        {
            {"ORDEM AÇÃO", Order.Ascending},
            {"DATA OS", Order.Ascending},
            {"NUCLEO", Order.Ascending},
            {"PLACA", Order.Ascending}
        }
    )
in
    Ordenar
