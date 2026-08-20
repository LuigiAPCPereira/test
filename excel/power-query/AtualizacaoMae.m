let
    // ============================================================
    // ATUALIZAÇÃO DA PLANILHA MÃE — DOCUMENTOS
    //
    // Objetivo: substituir, após validação, as várias consultas simples
    // (CIV, Crono, CIPP, TH, CRLV, Mássico e Medidores) por UMA tabela
    // com uma linha por placa e todas as validades necessárias.
    // ============================================================

    TiposEsperados = {
        "02.01", "02.02", "02.03", "02.04", "02.05",
        "02.06", "02.07", "02.08", "02.25"
    },

    Texto = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    TextoUpper = (valor as nullable any) as nullable text =>
        let t = Texto(valor)
        in if t = null then null else Text.Upper(t),

    DataSegura = (valor as nullable any) as nullable date =>
        if valor = null then null else try Date.From(valor) otherwise null,

    CodigoTipo = (tipo as nullable any) as nullable text =>
        let t = Texto(tipo)
        in if t = null or Text.Length(t) < 5 then null else Text.Start(t, 5),

    NomeCurto = (codigo as nullable text) as nullable text =>
        if codigo = null then null
        else if codigo = "02.01" then "Manômetro Vertical"
        else if codigo = "02.02" then "Medidor Mássico"
        else if codigo = "02.03" then "Termômetro"
        else if codigo = "02.04" then "Manômetro Horizontal"
        else if codigo = "02.05" then "CIPP"
        else if codigo = "02.06" then "CIV"
        else if codigo = "02.07" then "CRLV"
        else if codigo = "02.08" then "Cronotacógrafo"
        else if codigo = "02.25" then "Teste Hidrostático"
        else codigo,

    MenorValidade = (t as table, codigos as list) as nullable date =>
        let
            Filtrado = Table.SelectRows(t, each List.Contains(codigos, [Codigo])),
            Datas = List.RemoveNulls(Table.Column(Filtrado, "Validade"))
        in
            if List.Count(Datas) = 0 then null else List.Min(Datas),

    DocumentoDaMenorValidade = (t as table, codigos as list) as nullable text =>
        let
            DataMin = MenorValidade(t, codigos),
            Filtrado =
                if DataMin = null then #table({"Codigo", "Validade"}, {})
                else Table.SelectRows(t, each List.Contains(codigos, [Codigo]) and [Validade] = DataMin),
            Nomes = List.Sort(List.Distinct(List.Transform(List.RemoveNulls(Table.Column(Filtrado, "Codigo")), each NomeCurto(_))))
        in
            if List.Count(Nomes) = 0 then null else Text.Combine(Nomes, " + "),

    Fonte0 = Table.SelectColumns(
        SuasTrans,
        {"NUCLEO", "Filial", "Placa", "Frota", "Tipo de Documento", "Validade"},
        MissingField.UseNull
    ),

    Fonte1 = Table.TransformColumns(
        Fonte0,
        {
            {"NUCLEO", each Texto(_), type nullable text},
            {"Filial", each Texto(_), type nullable text},
            {"Placa", each TextoUpper(_), type nullable text},
            {"Frota", each TextoUpper(_), type nullable text},
            {"Tipo de Documento", each Texto(_), type nullable text},
            {"Validade", each DataSegura(_), type nullable date}
        }
    ),

    AddCodigo = Table.AddColumn(Fonte1, "Codigo", each CodigoTipo([#"Tipo de Documento"]), type nullable text),

    FiltrarEscopo = Table.SelectRows(
        AddCodigo,
        each [Placa] <> null and [Placa] <> "" and List.Contains(TiposEsperados, [Codigo])
    ),

    Base = Table.Buffer(FiltrarEscopo),

    Agrupar = Table.Group(
        Base,
        {"Placa"},
        {
            {"Linhas", each _, type table},
            {"Frota", each List.First(List.RemoveNulls([Frota]), null), type nullable text},
            {"NUCLEO", each List.First(List.RemoveNulls([NUCLEO]), null), type nullable text},
            {"Filial", each List.First(List.RemoveNulls([Filial]), null), type nullable text}
        }
    ),

    AddCIV = Table.AddColumn(Agrupar, "CIV", each MenorValidade([Linhas], {"02.06"}), type nullable date),
    AddCrono = Table.AddColumn(AddCIV, "Crono", each MenorValidade([Linhas], {"02.08"}), type nullable date),
    AddCIPP = Table.AddColumn(AddCrono, "CIPP", each MenorValidade([Linhas], {"02.05"}), type nullable date),
    AddTH = Table.AddColumn(AddCIPP, "TH", each MenorValidade([Linhas], {"02.25"}), type nullable date),
    AddMedidor = Table.AddColumn(AddTH, "Medidor", each MenorValidade([Linhas], {"02.02"}), type nullable date),
    AddManoTer = Table.AddColumn(AddMedidor, "Mano/Ter", each MenorValidade([Linhas], {"02.01", "02.03", "02.04"}), type nullable date),
    AddOrigemManoTer = Table.AddColumn(
        AddManoTer,
        "Documento Mano/Ter mais próximo",
        each DocumentoDaMenorValidade([Linhas], {"02.01", "02.03", "02.04"}),
        type nullable text
    ),
    AddCRLV = Table.AddColumn(AddOrigemManoTer, "CRLV", each MenorValidade([Linhas], {"02.07"}), type nullable date),

    AddFaltantes = Table.AddColumn(
        AddCRLV,
        "Documentos faltantes",
        each
            let
                Presentes = List.Distinct(List.RemoveNulls(Table.Column([Linhas], "Codigo"))),
                Faltantes = List.Difference(TiposEsperados, Presentes),
                Nomes = List.Transform(Faltantes, each NomeCurto(_))
            in
                if List.Count(Nomes) = 0 then null else Text.Combine(Nomes, " + "),
        type nullable text
    ),

    AddDuplicados = Table.AddColumn(
        AddFaltantes,
        "Documentos duplicados",
        each
            let
                G = Table.Group([Linhas], {"Codigo"}, {{"Qtd", each Table.RowCount(_), Int64.Type}}),
                D = Table.SelectRows(G, each [Qtd] > 1),
                Nomes = List.Transform(List.RemoveNulls(Table.Column(D, "Codigo")), each NomeCurto(_))
            in
                if List.Count(Nomes) = 0 then null else Text.Combine(Nomes, " + "),
        type nullable text
    ),

    AddIntegridade = Table.AddColumn(
        AddDuplicados,
        "Integridade",
        each
            if [#"Documentos faltantes"] <> null and [#"Documentos duplicados"] <> null then "FALTANTE + DUPLICADO"
            else if [#"Documentos faltantes"] <> null then "DOCUMENTO FALTANTE"
            else if [#"Documentos duplicados"] <> null then "DOCUMENTO DUPLICADO"
            else if [NUCLEO] = null then "NÚCLEO AUSENTE"
            else "OK",
        type text
    ),

    RemoverLinhas = Table.RemoveColumns(AddIntegridade, {"Linhas"}),

    Reordenar = Table.ReorderColumns(
        RemoverLinhas,
        {
            "NUCLEO",
            "Filial",
            "Placa",
            "Frota",
            "CIV",
            "Crono",
            "CIPP",
            "TH",
            "Medidor",
            "Mano/Ter",
            "Documento Mano/Ter mais próximo",
            "CRLV",
            "Integridade",
            "Documentos faltantes",
            "Documentos duplicados"
        },
        MissingField.Ignore
    ),

    Ordenar = Table.Sort(Reordenar, {{"NUCLEO", Order.Ascending}, {"Placa", Order.Ascending}})
in
    Ordenar
