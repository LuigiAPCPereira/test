let
    // ============================================================
    // MANO/TER — MENOR VALIDADE ENTRE:
    // 02.01 Manômetro Vertical
    // 02.03 Termômetro Analógico
    // 02.04 Manômetro Horizontal
    //
    // Fonte única: SuasTrans.
    // A SuasTrans já contém Placa, Frota, NUCLEO e Filial, então não
    // é necessário consultar novamente ConsultarFrotasNordeste.
    // ============================================================

    DataReferencia = Date.From(DateTime.FixedLocalNow()),

    TiposEsperados = {
        "02.01 - Calibração - Manômetro Analógico Vertical",
        "02.03 - Calibração - Termometro Analógico",
        "02.04 - Calibração - Manômetro Analógico Horizontal"
    },

    NomeCurto = (tipo as nullable text) as nullable text =>
        if tipo = null then null
        else if Text.StartsWith(tipo, "02.01") then "Manômetro Vertical"
        else if Text.StartsWith(tipo, "02.03") then "Termômetro"
        else if Text.StartsWith(tipo, "02.04") then "Manômetro Horizontal"
        else tipo,

    Fonte0 = Table.SelectColumns(
        SuasTrans,
        {"NUCLEO", "Filial", "Placa", "Frota", "Tipo de Documento", "Validade"},
        MissingField.UseNull
    ),

    Fonte1 = Table.TransformColumns(
        Fonte0,
        {
            {"NUCLEO", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"Filial", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"Placa", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type nullable text},
            {"Frota", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type nullable text},
            {"Tipo de Documento", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"Validade", each try Date.From(_) otherwise null, type nullable date}
        }
    ),

    Base = Table.Buffer(
        Table.SelectRows(Fonte1, each [Placa] <> null and [Placa] <> "")
    ),

    Frota = Table.Group(
        Base,
        {"Placa"},
        {
            {"NUCLEO", each List.First(List.RemoveNulls([NUCLEO]), null), type nullable text},
            {"Filial", each List.First(List.RemoveNulls([Filial]), null), type nullable text},
            {"Frota", each List.First(List.RemoveNulls([Frota]), null), type nullable text}
        }
    ),

    Filtrar = Table.SelectRows(
        Base,
        each List.Contains(TiposEsperados, [Tipo de Documento])
    ),

    AgruparDocs = Table.Group(
        Filtrar,
        {"Placa"},
        {{"Linhas", each _, type table}}
    ),

    Merge = Table.NestedJoin(
        Frota,
        {"Placa"},
        AgruparDocs,
        {"Placa"},
        "Docs",
        JoinKind.LeftOuter
    ),

    AddLinhas = Table.AddColumn(
        Merge,
        "Linhas",
        each if Table.RowCount([Docs]) = 0
            then #table({"Placa", "Tipo de Documento", "Validade"}, {})
            else [Docs]{0}[Linhas],
        type table
    ),

    RemoverDocs = Table.RemoveColumns(AddLinhas, {"Docs"}),

    AddValidade = Table.AddColumn(
        RemoverDocs,
        "Validade Mano/Ter",
        each
            let Datas = List.RemoveNulls(Table.Column([Linhas], "Validade"))
            in if List.Count(Datas) = 0 then null else List.Min(Datas),
        type nullable date
    ),

    AddDocumento = Table.AddColumn(
        AddValidade,
        "Documento mais próximo",
        each
            let
                DataMin = [#"Validade Mano/Ter"],
                T = if DataMin = null
                    then #table({"Tipo de Documento"}, {})
                    else Table.SelectRows([Linhas], each [Validade] = DataMin),
                Tipos = if DataMin = null
                    then {}
                    else List.Sort(
                        List.Distinct(
                            List.Transform(
                                List.RemoveNulls(Table.Column(T, "Tipo de Documento")),
                                each NomeCurto(_)
                            )
                        )
                    )
            in
                if List.Count(Tipos) = 0 then null else Text.Combine(Tipos, " + "),
        type nullable text
    ),

    AddFaltantes = Table.AddColumn(
        AddDocumento,
        "Documentos faltantes",
        each
            let
                Presentes = List.Distinct(List.RemoveNulls(Table.Column([Linhas], "Tipo de Documento"))),
                Faltantes = List.Difference(TiposEsperados, Presentes),
                Curtos = List.Transform(Faltantes, each NomeCurto(_))
            in
                if List.Count(Curtos) = 0 then null else Text.Combine(Curtos, " + "),
        type nullable text
    ),

    AddDuplicados = Table.AddColumn(
        AddFaltantes,
        "Documentos duplicados",
        each
            let
                G = Table.Group([Linhas], {"Tipo de Documento"}, {{"Qtd", each Table.RowCount(_), Int64.Type}}),
                D = Table.SelectRows(G, each [Qtd] > 1),
                N = List.Transform(List.RemoveNulls(Table.Column(D, "Tipo de Documento")), each NomeCurto(_))
            in
                if List.Count(N) = 0 then null else Text.Combine(N, " + "),
        type nullable text
    ),

    RemoverLinhas = Table.RemoveColumns(AddDuplicados, {"Linhas"}),

    AddDias = Table.AddColumn(
        RemoverLinhas,
        "Dias para vencer",
        each if [#"Validade Mano/Ter"] = null
            then null
            else Duration.Days([#"Validade Mano/Ter"] - DataReferencia),
        Int64.Type
    ),

    AddStatus = Table.AddColumn(
        AddDias,
        "Status",
        each
            if [#"Validade Mano/Ter"] = null then "Sem validade"
            else if [#"Validade Mano/Ter"] < DataReferencia then "Vencido"
            else if [#"Dias para vencer"] <= 30 then "Expirando"
            else "Válido",
        type text
    ),

    AddPrioridade = Table.AddColumn(
        AddStatus,
        "Prioridade",
        each
            if [#"Validade Mano/Ter"] = null then "SEM DADO"
            else if [#"Dias para vencer"] < 0 then "VENCIDO"
            else if [#"Dias para vencer"] <= 30 then "≤30 dias"
            else if [#"Dias para vencer"] <= 60 then "31–60 dias"
            else if [#"Dias para vencer"] <= 90 then "61–90 dias"
            else ">90 dias",
        type text
    ),

    AddMesAno = Table.AddColumn(
        AddPrioridade,
        "Mês-Ano",
        each if [#"Validade Mano/Ter"] = null
            then null
            else Date.ToText([#"Validade Mano/Ter"], "yyyy-MM", "pt-BR")
                & " "
                & Text.Proper(Text.Replace(Date.ToText([#"Validade Mano/Ter"], "MMM", "pt-BR"), ".", "")),
        type nullable text
    ),

    AddIntegridade = Table.AddColumn(
        AddMesAno,
        "Integridade",
        each
            if [#"Documentos faltantes"] <> null and [#"Documentos duplicados"] <> null then "FALTANTE + DUPLICADO"
            else if [#"Documentos faltantes"] <> null then "DOCUMENTO FALTANTE"
            else if [#"Documentos duplicados"] <> null then "DOCUMENTO DUPLICADO"
            else if [#"Validade Mano/Ter"] = null then "VALIDADE AUSENTE"
            else if [NUCLEO] = null then "NÚCLEO AUSENTE"
            else "OK",
        type text
    ),

    AddReferencia = Table.AddColumn(
        AddIntegridade,
        "Data referência",
        each DataReferencia,
        type date
    ),

    Reordenar = Table.ReorderColumns(
        AddReferencia,
        {
            "NUCLEO",
            "Filial",
            "Placa",
            "Validade Mano/Ter",
            "Documento mais próximo",
            "Status",
            "Prioridade",
            "Dias para vencer",
            "Mês-Ano",
            "Frota",
            "Integridade",
            "Documentos faltantes",
            "Documentos duplicados",
            "Data referência"
        },
        MissingField.Ignore
    ),

    Ordenar = Table.Sort(
        Reordenar,
        {
            {"Validade Mano/Ter", Order.Ascending},
            {"NUCLEO", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    Ordenar
