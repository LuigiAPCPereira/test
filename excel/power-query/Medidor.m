let
    // ============================================================
    // MEDIDOR MÁSSICO — 02.02
    //
    // Fonte única: SuasTrans.
    // A própria SuasTrans já contém Placa, Frota, NUCLEO e Filial.
    // Isso evita consultar novamente ConsultarFrotasNordeste e reduz
    // avaliações remotas desnecessárias no refresh.
    // ============================================================

    DataReferencia = Date.From(DateTime.FixedLocalNow()),
    TipoEsperado = "02.02 - Calibração - Medidor Mássico",

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

    // A base tem somente algumas centenas de linhas. O buffer aqui evita
    // reavaliar SuasTrans quando a mesma base é usada para frota e medidor.
    Base = Table.Buffer(
        Table.SelectRows(Fonte1, each [Placa] <> null and [Placa] <> "")
    ),

    // Universo de placas derivado da própria SuasTrans. Assim uma placa
    // continua aparecendo mesmo se o 02.02 estiver faltando, desde que
    // exista qualquer outro documento dela na base.
    Frota = Table.Group(
        Base,
        {"Placa"},
        {
            {"NUCLEO", each List.First(List.RemoveNulls([NUCLEO]), null), type nullable text},
            {"Filial", each List.First(List.RemoveNulls([Filial]), null), type nullable text},
            {"Frota", each List.First(List.RemoveNulls([Frota]), null), type nullable text}
        }
    ),

    Medidores = Table.SelectRows(Base, each [Tipo de Documento] = TipoEsperado),

    AgruparDocs = Table.Group(
        Medidores,
        {"Placa"},
        {
            {"Qtd registros", each Table.RowCount(_), Int64.Type},
            {
                "Validade Medidor",
                each
                    let Datas = List.RemoveNulls([Validade])
                    in if List.Count(Datas) = 0 then null else List.Min(Datas),
                type nullable date
            }
        }
    ),

    Merge = Table.NestedJoin(
        Frota,
        {"Placa"},
        AgruparDocs,
        {"Placa"},
        "Medidor",
        JoinKind.LeftOuter
    ),

    Expandir = Table.ExpandTableColumn(
        Merge,
        "Medidor",
        {"Qtd registros", "Validade Medidor"},
        {"Qtd registros", "Validade Medidor"}
    ),

    QtdNormalizada = Table.TransformColumns(
        Expandir,
        {{"Qtd registros", each if _ = null then 0 else Int64.From(_), Int64.Type}}
    ),

    AddDias = Table.AddColumn(
        QtdNormalizada,
        "Dias para vencer",
        each if [#"Validade Medidor"] = null
            then null
            else Duration.Days([#"Validade Medidor"] - DataReferencia),
        Int64.Type
    ),

    AddStatus = Table.AddColumn(
        AddDias,
        "Status",
        each
            if [#"Validade Medidor"] = null then "Sem validade"
            else if [#"Validade Medidor"] < DataReferencia then "Vencido"
            else if [#"Dias para vencer"] <= 30 then "Expirando"
            else "Válido",
        type text
    ),

    AddPrioridade = Table.AddColumn(
        AddStatus,
        "Prioridade",
        each
            if [#"Validade Medidor"] = null then "SEM DADO"
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
        each if [#"Validade Medidor"] = null
            then null
            else Date.ToText([#"Validade Medidor"], "yyyy-MM", "pt-BR")
                & " "
                & Text.Proper(Text.Replace(Date.ToText([#"Validade Medidor"], "MMM", "pt-BR"), ".", "")),
        type nullable text
    ),

    AddIntegridade = Table.AddColumn(
        AddMesAno,
        "Integridade",
        each
            if [#"Qtd registros"] = 0 then "DOCUMENTO FALTANTE"
            else if [#"Qtd registros"] > 1 then "DOCUMENTO DUPLICADO"
            else if [#"Validade Medidor"] = null then "VALIDADE AUSENTE"
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
            "Validade Medidor",
            "Status",
            "Prioridade",
            "Dias para vencer",
            "Mês-Ano",
            "Frota",
            "Integridade",
            "Qtd registros",
            "Data referência"
        },
        MissingField.Ignore
    ),

    Ordenar = Table.Sort(
        Reordenar,
        {
            {"Validade Medidor", Order.Ascending},
            {"NUCLEO", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    Ordenar
