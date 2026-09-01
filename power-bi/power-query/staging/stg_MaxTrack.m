let
    // ============================================================
    // STAGING — MAXTRACK / FROTA OFICIAL (SEM DEDUPLICAÇÃO)
    // Origem: stg_MaxTrackRaw + stg_Frota
    // Objetivo: normalizar placa/odômetro e preservar ocorrências
    // para auditoria antes de escolher um KM corrente.
    // ============================================================

    TextoTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    NormalizarPlaca = (valor as nullable any) as nullable text =>
        let
            T = if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),
            Limpa = if T = null then null else Text.Remove(T, {" ", "-", ".", "/"})
        in
            if Limpa = null or Limpa = "" then null else Limpa,

    OdometroKm = (valor as nullable any) as nullable number =>
        let
            T = TextoTrim(valor),
            Digitos = if T = null then null else Text.Select(T, {"0".."9"}),
            SemTresFinais =
                if Digitos = null or Text.Length(Digitos) <= 3 then null
                else Text.Start(Digitos, Text.Length(Digitos) - 3),
            N = try Number.FromText(SemTresFinais, "pt-BR") otherwise null
        in
            N,

    Fonte = stg_MaxTrackRaw,

    AddPlacaNormalizada = Table.AddColumn(
        Fonte,
        "Placa Normalizada",
        each NormalizarPlaca([PLACA_BRUTA]),
        type nullable text
    ),

    AddOdometroKm = Table.AddColumn(
        AddPlacaNormalizada,
        "Odometro KM",
        each OdometroKm([ODOMETRO_BRUTO]),
        Int64.Type
    ),

    FrotaOficial = Table.SelectColumns(
        stg_Frota,
        {"Placa Normalizada", "Núcleo", "Filial", "Placa", "Frota"}
    ),

    MergeFrota = Table.NestedJoin(
        AddOdometroKm,
        {"Placa Normalizada"},
        FrotaOficial,
        {"Placa Normalizada"},
        "FrotaOficial",
        JoinKind.Inner
    ),

    ExpandFrota = Table.ExpandTableColumn(
        MergeFrota,
        "FrotaOficial",
        {"Núcleo", "Filial", "Placa", "Frota"},
        {"Núcleo", "Filial", "Placa", "Frota"}
    ),

    ContagemPlaca = Table.Group(
        ExpandFrota,
        {"Placa Normalizada"},
        {{"Qtd Registros MaxTrack", each Table.RowCount(_), Int64.Type}}
    ),

    MergeContagem = Table.NestedJoin(
        ExpandFrota,
        {"Placa Normalizada"},
        ContagemPlaca,
        {"Placa Normalizada"},
        "Auditoria",
        JoinKind.LeftOuter
    ),

    ExpandContagem = Table.ExpandTableColumn(
        MergeContagem,
        "Auditoria",
        {"Qtd Registros MaxTrack"},
        {"Qtd Registros MaxTrack"}
    ),

    AddIntegridade = Table.AddColumn(
        ExpandContagem,
        "Integridade MaxTrack",
        each
            if [Odometro KM] = null and [Qtd Registros MaxTrack] > 1 then
                "ODOMETRO INVÁLIDO + MÚLTIPLOS REGISTROS"
            else if [Odometro KM] = null then
                "ODOMETRO INVÁLIDO"
            else if [Qtd Registros MaxTrack] > 1 then
                "MÚLTIPLOS REGISTROS"
            else
                "OK",
        type text
    ),

    Resultado = Table.Sort(
        Table.SelectColumns(
            AddIntegridade,
            {
                "Núcleo",
                "Filial",
                "Placa",
                "Frota",
                "Placa Normalizada",
                "PLACA_BRUTA",
                "ODOMETRO_BRUTO",
                "Odometro KM",
                "Qtd Registros MaxTrack",
                "Integridade MaxTrack",
                "SourceFile",
                "SourceCreated",
                "SourceModified"
            },
            MissingField.UseNull
        ),
        {
            {"Núcleo", Order.Ascending},
            {"Filial", Order.Ascending},
            {"Placa", Order.Ascending},
            {"Odometro KM", Order.Descending}
        }
    )
in
    Resultado
