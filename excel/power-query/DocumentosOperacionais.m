let
    // ============================================================
    // DOCUMENTOS OPERACIONAIS — SUASTRANS
    //
    // Reaproveita a consulta SuasTrans já existente e acrescenta
    // campos de apoio para execução diária e segmentação.
    // Não altera o Status original calculado pela consulta SuasTrans.
    // ============================================================

    DataReferencia = Date.From(DateTime.FixedLocalNow()),
    InicioMesAtual = Date.StartOfMonth(DataReferencia),
    InicioProximoMes = Date.AddMonths(InicioMesAtual, 1),
    InicioMesSeguinte = Date.AddMonths(InicioMesAtual, 2),

    Texto = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    TextoUpper = (valor as nullable any) as nullable text =>
        let t = Texto(valor)
        in if t = null then null else Text.Upper(t),

    DataSegura = (valor as nullable any) as nullable date =>
        if valor = null then null else try Date.From(valor) otherwise null,

    EncontrarColuna = (nomes as list, candidatos as list) as nullable text =>
        List.First(List.Select(candidatos, each List.Contains(nomes, _)), null),

    Fonte = SuasTrans,
    Nomes = Table.ColumnNames(Fonte),

    ColPlaca = EncontrarColuna(Nomes, {"Placa", "PLACA"}),
    ColFrota = EncontrarColuna(Nomes, {"Frota", "FROTA"}),
    ColNucleo = EncontrarColuna(Nomes, {"NUCLEO", "Núcleo", "Nucleo"}),
    ColFilial = EncontrarColuna(Nomes, {"Filial", "FILIAL"}),
    ColTipo = EncontrarColuna(Nomes, {"Tipo de Documento", "TIPO DE DOCUMENTO", "TIPO_DOCUMENTO"}),
    ColValidade = EncontrarColuna(Nomes, {"Validade", "VALIDADE"}),
    ColStatus = EncontrarColuna(Nomes, {"Status", "STATUS"}),

    AddPlaca = Table.AddColumn(
        Fonte,
        "OP_PLACA",
        each if ColPlaca = null then null else TextoUpper(Record.FieldOrDefault(_, ColPlaca, null)),
        type nullable text
    ),

    AddFrota = Table.AddColumn(
        AddPlaca,
        "OP_FROTA",
        each if ColFrota = null then null else TextoUpper(Record.FieldOrDefault(_, ColFrota, null)),
        type nullable text
    ),

    AddNucleo = Table.AddColumn(
        AddFrota,
        "OP_NUCLEO",
        each if ColNucleo = null then null else Texto(Record.FieldOrDefault(_, ColNucleo, null)),
        type nullable text
    ),

    AddFilial = Table.AddColumn(
        AddNucleo,
        "OP_FILIAL",
        each if ColFilial = null then null else Texto(Record.FieldOrDefault(_, ColFilial, null)),
        type nullable text
    ),

    AddTipo = Table.AddColumn(
        AddFilial,
        "OP_TIPO",
        each if ColTipo = null then null else Texto(Record.FieldOrDefault(_, ColTipo, null)),
        type nullable text
    ),

    AddValidade = Table.AddColumn(
        AddTipo,
        "OP_VALIDADE",
        each if ColValidade = null then null else DataSegura(Record.FieldOrDefault(_, ColValidade, null)),
        type nullable date
    ),

    AddStatus = Table.AddColumn(
        AddValidade,
        "OP_STATUS",
        each if ColStatus = null then null else TextoUpper(Record.FieldOrDefault(_, ColStatus, null)),
        type nullable text
    ),

    AddDias = Table.AddColumn(
        AddStatus,
        "DIAS PARA VENCER",
        each if [OP_VALIDADE] = null then null else Duration.Days([OP_VALIDADE] - DataReferencia),
        Int64.Type
    ),

    AddAcao = Table.AddColumn(
        AddDias,
        "AÇÃO OPERACIONAL",
        each
            if [OP_STATUS] = "VENCIDO" then "REGULARIZAR DOCUMENTO"
            else if [OP_STATUS] = "EXPIRANDO" then "PROGRAMAR RENOVAÇÃO"
            else if [OP_STATUS] = "VÁLIDO" or [OP_STATUS] = "VALIDO" then "SEM AÇÃO"
            else if [OP_VALIDADE] = null then "REVISAR DADO"
            else "REVISAR STATUS",
        type text
    ),

    AddOrdem = Table.AddColumn(
        AddAcao,
        "ORDEM AÇÃO",
        each
            if [#"AÇÃO OPERACIONAL"] = "REGULARIZAR DOCUMENTO" then 1
            else if [#"AÇÃO OPERACIONAL"] = "REVISAR DADO" or [#"AÇÃO OPERACIONAL"] = "REVISAR STATUS" then 2
            else if [#"AÇÃO OPERACIONAL"] = "PROGRAMAR RENOVAÇÃO" then 3
            else 4,
        Int64.Type
    ),

    AddPeriodo = Table.AddColumn(
        AddOrdem,
        "PERÍODO VALIDADE",
        each
            if [OP_VALIDADE] = null then "SEM DATA"
            else if [OP_VALIDADE] < DataReferencia then "VENCIDO"
            else if [OP_VALIDADE] < InicioProximoMes then "MÊS ATUAL"
            else if [OP_VALIDADE] < InicioMesSeguinte then "PRÓXIMO MÊS"
            else "FUTURO",
        type text
    ),

    AddMesAno = Table.AddColumn(
        AddPeriodo,
        "MÊS-ANO",
        each if [OP_VALIDADE] = null then null
            else Date.ToText([OP_VALIDADE], "yyyy-MM", "pt-BR")
                & " "
                & Text.Proper(Text.Replace(Date.ToText([OP_VALIDADE], "MMM", "pt-BR"), ".", "")),
        type nullable text
    ),

    AddIntegridade = Table.AddColumn(
        AddMesAno,
        "INTEGRIDADE",
        each
            if [OP_PLACA] = null or [OP_PLACA] = "" then "PLACA AUSENTE"
            else if [OP_TIPO] = null or [OP_TIPO] = "" then "TIPO AUSENTE"
            else if [OP_VALIDADE] = null then "VALIDADE AUSENTE"
            else if [OP_STATUS] = null or [OP_STATUS] = "" then "STATUS AUSENTE"
            else "OK",
        type text
    ),

    AddReferencia = Table.AddColumn(
        AddIntegridade,
        "DATA REFERÊNCIA",
        each DataReferencia,
        type date
    ),

    Selecionar = Table.SelectColumns(
        AddReferencia,
        {
            "OP_PLACA", "OP_FROTA", "OP_NUCLEO", "OP_FILIAL", "OP_TIPO",
            "OP_VALIDADE", "OP_STATUS", "DIAS PARA VENCER", "AÇÃO OPERACIONAL",
            "ORDEM AÇÃO", "PERÍODO VALIDADE", "MÊS-ANO", "INTEGRIDADE", "DATA REFERÊNCIA"
        },
        MissingField.UseNull
    ),

    Renomear = Table.RenameColumns(
        Selecionar,
        {
            {"OP_PLACA", "PLACA"},
            {"OP_FROTA", "FROTA"},
            {"OP_NUCLEO", "NUCLEO"},
            {"OP_FILIAL", "FILIAL"},
            {"OP_TIPO", "TIPO DE DOCUMENTO"},
            {"OP_VALIDADE", "VALIDADE"},
            {"OP_STATUS", "STATUS"}
        }
    ),

    Ordenar = Table.Sort(
        Renomear,
        {
            {"ORDEM AÇÃO", Order.Ascending},
            {"VALIDADE", Order.Ascending},
            {"NUCLEO", Order.Ascending},
            {"PLACA", Order.Ascending}
        }
    )
in
    Ordenar
