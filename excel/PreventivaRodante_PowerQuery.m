let
    // ============================================================
    // PREVENTIVA RODANTE — FROTA NORDESTE
    // Fonte oficial da preventiva: planilha mãe da Ultragaz
    // KM atual: consulta MaxTrack já existente na pasta de trabalho
    // ============================================================

    DataReferencia = Date.From(DateTime.FixedLocalNow()),

    TextoLimpo = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    NumeroBR = (valor as nullable any) as nullable number =>
        if valor = null then null
        else if Value.Is(valor, type number) then Number.From(valor)
        else
            let
                txt = Text.Trim(Text.From(valor)),
                convertido = try Number.FromText(txt, "pt-BR") otherwise try Number.FromText(txt, "en-US") otherwise null
            in
                convertido,

    DataBR = (valor as nullable any) as nullable date =>
        if valor = null then null
        else if Value.Is(valor, type date) then Date.From(valor)
        else if Value.Is(valor, type datetime) or Value.Is(valor, type datetimezone) then Date.From(valor)
        else
            let
                txt = Text.Trim(Text.From(valor)),
                convertido = try Date.FromText(txt, "pt-BR") otherwise try Date.From(valor) otherwise null
            in
                convertido,

    EncontrarColuna = (nomesDisponiveis as list, candidatos as list) as nullable text =>
        List.First(List.Select(candidatos, each List.Contains(nomesDisponiveis, _)), null),

    // -------- Planilha mãe / fonte otimizada --------
    FonteMae = FontePlanilhaMae_Contents,

    ArquivoMae = Table.SelectRows(
        FonteMae,
        each [Name] = "Programações Paradas Frotas.xlsm"
            and Text.Contains([Folder Path], "Manutenção e Disponibilidade")
    ),

    ConteudoMae =
        if Table.RowCount(ArquivoMae) = 0
        then error "Arquivo Programações Paradas Frotas.xlsm não encontrado na pasta Manutenção e Disponibilidade."
        else ArquivoMae{0}[Content],

    PastaExcel = Excel.Workbook(ConteudoMae, false, true),
    BaseDados0 = PastaExcel{[Item = "Base de Dados", Kind = "Sheet"]}[Data],

    BaseDados = Table.ReplaceErrorValues(
        BaseDados0,
        List.Transform(Table.ColumnNames(BaseDados0), each {_, null})
    ),

    Coluna1Tratada = List.Transform(
        Table.Column(BaseDados, "Column1"),
        each if _ = null then null else Text.Trim(Text.From(_))
    ),

    LinhaCabecalho = List.PositionOf(Coluna1Tratada, "Placa"),

    LinhasAposCabecalho =
        if LinhaCabecalho < 0
        then error "Cabeçalho Placa não encontrado na coluna inicial da aba Base de Dados."
        else Table.Skip(BaseDados, LinhaCabecalho),

    CabecalhosPromovidos0 = Table.PromoteHeaders(LinhasAposCabecalho, [PromoteAllScalars = true]),

    CabecalhosPromovidos = Table.ReplaceErrorValues(
        CabecalhosPromovidos0,
        List.Transform(Table.ColumnNames(CabecalhosPromovidos0), each {_, null})
    ),

    FiltrarNordeste = Table.SelectRows(
        CabecalhosPromovidos,
        each try Text.Trim(Text.From([Mercado])) = "Empresarial Nordeste" otherwise false
    ),

    NomesColunas = Table.ColumnNames(FiltrarNordeste),

    ColKmUltPrev = EncontrarColuna(NomesColunas, {"KM Ult. Prev.", "KM Últ. Prev.", "KM Ult Prev", "KM Últ Prev"}),
    ColKmProxPrev = EncontrarColuna(NomesColunas, {"Km Prox Prev.", "KM Prox Prev.", "KM Próx. Prev.", "Km Próx. Prev.", "KM Prox Prev", "KM Próx Prev"}),
    ColDataProxPrev = EncontrarColuna(NomesColunas, {"Data Próx. Prev.", "Data Prox. Prev.", "Data Próx Prev", "Data Prox Prev"}),

    AddKmUltPrev = Table.AddColumn(
        FiltrarNordeste,
        "KM Últ. Prev. (Normalizado)",
        each if ColKmUltPrev = null then null else NumeroBR(Record.FieldOrDefault(_, ColKmUltPrev, null)),
        type nullable number
    ),

    AddKmProxPrev = Table.AddColumn(
        AddKmUltPrev,
        "KM Próx. Prev. (Normalizado)",
        each if ColKmProxPrev = null then null else NumeroBR(Record.FieldOrDefault(_, ColKmProxPrev, null)),
        type nullable number
    ),

    AddDataProxPrev = Table.AddColumn(
        AddKmProxPrev,
        "Data Próx. Prev. (Normalizada)",
        each if ColDataProxPrev = null then null else DataBR(Record.FieldOrDefault(_, ColDataProxPrev, null)),
        type nullable date
    ),

    SelecionarMae = Table.SelectColumns(
        AddDataProxPrev,
        {
            "Núcleo",
            "Filial",
            "Placa",
            "Frota",
            "KM Últ. Prev. (Normalizado)",
            "KM Próx. Prev. (Normalizado)",
            "Data Próx. Prev. (Normalizada)"
        },
        MissingField.UseNull
    ),

    RenomearMae = Table.RenameColumns(
        SelecionarMae,
        {
            {"KM Últ. Prev. (Normalizado)", "KM Últ. Prev."},
            {"KM Próx. Prev. (Normalizado)", "KM Próx. Prev."},
            {"Data Próx. Prev. (Normalizada)", "Data Próx. Prev."}
        }
    ),

    NormalizarPlacaMae = Table.TransformColumns(RenomearMae, {{"Placa", each TextoLimpo(_), type text}}),
    FiltrarPlacasValidas = Table.SelectRows(NormalizarPlacaMae, each [Placa] <> null and [Placa] <> ""),
    OrdenarMae = Table.Sort(FiltrarPlacasValidas, {{"Placa", Order.Ascending}}),
    MaeUmaLinhaPorPlaca = Table.Distinct(Table.Buffer(OrdenarMae), {"Placa"}),

    MaxTrackBase = Table.SelectColumns(MaxTrack, {"PLACA", "ODOMETRO"}, MissingField.UseNull),

    NormalizarMaxTrack = Table.TransformColumns(
        MaxTrackBase,
        {
            {"PLACA", each TextoLimpo(_), type text},
            {"ODOMETRO", each NumeroBR(_), type nullable number}
        }
    ),

    MaxTrackValido = Table.SelectRows(NormalizarMaxTrack, each [PLACA] <> null and [PLACA] <> ""),
    MaxTrackUmaLinhaPorPlaca = Table.Distinct(Table.Buffer(Table.Sort(MaxTrackValido, {{"PLACA", Order.Ascending}})), {"PLACA"}),

    MergeMaxTrack = Table.NestedJoin(MaeUmaLinhaPorPlaca, {"Placa"}, MaxTrackUmaLinhaPorPlaca, {"PLACA"}, "MaxTrack", JoinKind.LeftOuter),
    ExpandirMaxTrack = Table.ExpandTableColumn(MergeMaxTrack, "MaxTrack", {"ODOMETRO"}, {"KM Atual"}),

    AddKmPercorrido = Table.AddColumn(
        ExpandirMaxTrack,
        "KM desde Últ. Prev.",
        each if [KM Atual] = null or [#"KM Últ. Prev."] = null then null else [KM Atual] - [#"KM Últ. Prev."],
        type nullable number
    ),

    AddIntervaloPlanejado = Table.AddColumn(
        AddKmPercorrido,
        "Intervalo Planejado",
        each if [#"KM Próx. Prev."] = null or [#"KM Últ. Prev."] = null then null else [#"KM Próx. Prev."] - [#"KM Últ. Prev."],
        type nullable number
    ),

    AddKmRestante = Table.AddColumn(
        AddIntervaloPlanejado,
        "KM Restante",
        each if [#"KM Próx. Prev."] = null or [KM Atual] = null then null else [#"KM Próx. Prev."] - [KM Atual],
        type nullable number
    ),

    AddFaixaKm = Table.AddColumn(
        AddKmRestante,
        "Faixa KM",
        each
            if [KM Restante] = null then "SEM DADO"
            else if [KM Restante] < -2000 then "CRÍTICA - fora tolerância"
            else if [KM Restante] <= 0 then "VENCIDA - tolerância"
            else if [KM Restante] <= 2000 then "PROGRAMAR - ≤2.000 km"
            else if [KM Restante] <= 3000 then "ATENÇÃO - 2.001–3.000 km"
            else if [KM Restante] <= 5000 then "MONITORAR - 3.001–5.000 km"
            else "OK - >5.000 km",
        type text
    ),

    AddDiasData = Table.AddColumn(
        AddFaixaKm,
        "Dias para a data",
        each if [#"Data Próx. Prev."] = null then null else Duration.Days([#"Data Próx. Prev."] - DataReferencia),
        Int64.Type
    ),

    AddStatusData = Table.AddColumn(
        AddDiasData,
        "Status por data",
        each
            if [#"Data Próx. Prev."] = null then "SEM DADO"
            else if DataReferencia > Date.AddMonths([#"Data Próx. Prev."], 2) then "CRÍTICA - fora tolerância"
            else if DataReferencia > [#"Data Próx. Prev."] then "VENCIDA - tolerância"
            else if [Dias para a data] <= 30 then "PROGRAMAR - ≤30 dias"
            else if [Dias para a data] <= 60 then "ATENÇÃO - 31–60 dias"
            else "OK - >60 dias",
        type text
    ),

    AddSituacaoGeral = Table.AddColumn(
        AddStatusData,
        "Situação Geral",
        each
            if [KM Atual] = null or [#"KM Próx. Prev."] = null or [#"Data Próx. Prev."] = null then "DADOS INCOMPLETOS"
            else if Text.StartsWith([Faixa KM], "CRÍTICA") or Text.StartsWith([Status por data], "CRÍTICA") then "CRÍTICA"
            else if Text.StartsWith([Faixa KM], "VENCIDA") or Text.StartsWith([Status por data], "VENCIDA") then "VENCIDA"
            else if Text.StartsWith([Faixa KM], "PROGRAMAR") or Text.StartsWith([Status por data], "PROGRAMAR") then "PROGRAMAR"
            else if Text.StartsWith([Faixa KM], "ATENÇÃO") or Text.StartsWith([Status por data], "ATENÇÃO") then "ATENÇÃO"
            else if Text.StartsWith([Faixa KM], "MONITORAR") then "MONITORAR"
            else "OK",
        type text
    ),

    AddPrioridade = Table.AddColumn(
        AddSituacaoGeral,
        "Ordem Prioridade",
        each
            if [Situação Geral] = "CRÍTICA" then 1
            else if [Situação Geral] = "VENCIDA" then 2
            else if [Situação Geral] = "PROGRAMAR" then 3
            else if [Situação Geral] = "ATENÇÃO" then 4
            else if [Situação Geral] = "MONITORAR" then 5
            else if [Situação Geral] = "OK" then 6
            else 7,
        Int64.Type
    ),

    AddMesAno = Table.AddColumn(
        AddPrioridade,
        "Mês-Ano",
        each if [#"Data Próx. Prev."] = null then null
             else Date.ToText([#"Data Próx. Prev."], "yyyy-MM", "pt-BR")
                  & " "
                  & Text.Proper(Text.Replace(Date.ToText([#"Data Próx. Prev."], "MMM", "pt-BR"), ".", "")),
        type nullable text
    ),

    AddIntegridade = Table.AddColumn(
        AddMesAno,
        "Integridade",
        each
            if [KM Atual] = null then "KM AUSENTE NO MAXTRACK"
            else if [#"KM Últ. Prev."] = null then "KM ÚLT. PREV. AUSENTE"
            else if [#"KM Próx. Prev."] = null then "KM PRÓX. PREV. AUSENTE"
            else if [#"Data Próx. Prev."] = null then "DATA PRÓX. PREV. AUSENTE"
            else if [#"KM Próx. Prev."] <= [#"KM Últ. Prev."] then "KM PRÓX. PREV. INVÁLIDO"
            else "OK",
        type text
    ),

    AddDataReferencia = Table.AddColumn(AddIntegridade, "Data referência", each DataReferencia, type date),

    Reordenar = Table.ReorderColumns(
        AddDataReferencia,
        {
            "Núcleo",
            "Filial",
            "Placa",
            "Frota",
            "KM Atual",
            "KM Últ. Prev.",
            "KM desde Últ. Prev.",
            "KM Próx. Prev.",
            "Intervalo Planejado",
            "KM Restante",
            "Faixa KM",
            "Data Próx. Prev.",
            "Dias para a data",
            "Status por data",
            "Situação Geral",
            "Ordem Prioridade",
            "Mês-Ano",
            "Integridade",
            "Data referência"
        },
        MissingField.Ignore
    ),

    OrdenarFinal = Table.Sort(
        Reordenar,
        {
            {"Ordem Prioridade", Order.Ascending},
            {"KM Restante", Order.Ascending},
            {"Data Próx. Prev.", Order.Ascending},
            {"Núcleo", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    OrdenarFinal