let
    // ============================================================
    // STAGING — AUDITORIA MAXTRACK
    // Origem: stg_MaxTrackRaw + stg_Frota
    // Granularidade: 1 linha por veículo oficial
    // Objetivo: medir cobertura, validade do odômetro e duplicidades.
    //
    // Decisão arquitetural:
    // a auditoria não depende de stg_MaxTrack nem de nomes derivados.
    // Ela usa o contrato conhecido da camada raw:
    // PLACA_BRUTA + ODOMETRO_BRUTO.
    // ============================================================

    NormalizarPlaca = (valor as nullable any) as nullable text =>
        let
            T = if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),
            Limpa = if T = null then null else Text.Remove(T, {" ", "-", ".", "/"})
        in
            if Limpa = null or Limpa = "" then null else Limpa,

    OdometroKm = (valor as nullable any) as nullable number =>
        let
            T = if valor = null then null else Text.Trim(Text.From(valor)),
            Digitos = if T = null then null else Text.Select(T, {"0".."9"}),
            SemTresFinais =
                if Digitos = null or Text.Length(Digitos) <= 3 then null
                else Text.Start(Digitos, Text.Length(Digitos) - 3),
            N = try Number.FromText(SemTresFinais, "pt-BR") otherwise null
        in
            N,

    FonteRaw = stg_MaxTrackRaw,

    ColunasObrigatorias = {"PLACA_BRUTA", "ODOMETRO_BRUTO"},
    ColunasFaltantes = List.Difference(ColunasObrigatorias, Table.ColumnNames(FonteRaw)),

    ValidarEstrutura =
        if List.Count(ColunasFaltantes) > 0 then
            error Error.Record(
                "Estrutura MaxTrack Raw inválida",
                "stg_MaxTrackRaw não contém o contrato mínimo necessário para a auditoria.",
                [
                    ColunasFaltantes = ColunasFaltantes,
                    ColunasEncontradas = Table.ColumnNames(FonteRaw)
                ]
            )
        else
            FonteRaw,

    AddPlacaAudit = Table.AddColumn(
        ValidarEstrutura,
        "Placa Audit",
        each NormalizarPlaca([PLACA_BRUTA]),
        type nullable text
    ),

    AddOdometroAudit = Table.AddColumn(
        AddPlacaAudit,
        "Odometro Audit KM",
        each OdometroKm([ODOMETRO_BRUTO]),
        Int64.Type
    ),

    AddSourceFileAudit =
        if List.Contains(Table.ColumnNames(AddOdometroAudit), "SourceFile") then
            Table.AddColumn(
                AddOdometroAudit,
                "SourceFile Audit",
                each try Text.From([SourceFile]) otherwise null,
                type nullable text
            )
        else
            Table.AddColumn(
                AddOdometroAudit,
                "SourceFile Audit",
                each null,
                type nullable text
            ),

    ResumoRaw = Table.Group(
        AddSourceFileAudit,
        {"Placa Audit"},
        {
            {"Qtd Registros MaxTrack", each Table.RowCount(_), Int64.Type},
            {
                "Qtd Odometros Válidos",
                each List.Count(List.RemoveNulls(Table.Column(_, "Odometro Audit KM"))),
                Int64.Type
            },
            {
                "Qtd Odometros Distintos",
                each List.Count(List.Distinct(List.RemoveNulls(Table.Column(_, "Odometro Audit KM")))),
                Int64.Type
            },
            {
                "Odometros KM",
                each Text.Combine(
                    List.Transform(
                        List.Sort(
                            List.Distinct(List.RemoveNulls(Table.Column(_, "Odometro Audit KM"))),
                            Order.Descending
                        ),
                        each Number.ToText(_, "0", "pt-BR")
                    ),
                    " | "
                ),
                type text
            },
            {
                "Arquivos Fonte",
                each Text.Combine(
                    List.Sort(
                        List.Distinct(List.RemoveNulls(Table.Column(_, "SourceFile Audit")))
                    ),
                    " | "
                ),
                type text
            }
        }
    ),

    FrotaOficial = Table.SelectColumns(
        stg_Frota,
        {"Núcleo", "Filial", "Placa", "Frota", "Placa Normalizada"}
    ),

    MergeResumo = Table.NestedJoin(
        FrotaOficial,
        {"Placa Normalizada"},
        ResumoRaw,
        {"Placa Audit"},
        "MaxTrack",
        JoinKind.LeftOuter
    ),

    ExpandResumo = Table.ExpandTableColumn(
        MergeResumo,
        "MaxTrack",
        {
            "Qtd Registros MaxTrack",
            "Qtd Odometros Válidos",
            "Qtd Odometros Distintos",
            "Odometros KM",
            "Arquivos Fonte"
        },
        {
            "Qtd Registros MaxTrack",
            "Qtd Odometros Válidos",
            "Qtd Odometros Distintos",
            "Odometros KM",
            "Arquivos Fonte"
        }
    ),

    SubstituirContagensNulas = Table.ReplaceValue(
        ExpandResumo,
        null,
        0,
        Replacer.ReplaceValue,
        {
            "Qtd Registros MaxTrack",
            "Qtd Odometros Válidos",
            "Qtd Odometros Distintos"
        }
    ),

    AddClassificacao = Table.AddColumn(
        SubstituirContagensNulas,
        "Classificação MaxTrack",
        each
            if [Qtd Registros MaxTrack] = 0 then
                "SEM REGISTRO MAXTRACK"
            else if [Qtd Odometros Válidos] = 0 then
                "ODOMETRO AUSENTE OU INVÁLIDO"
            else if [Qtd Registros MaxTrack] > 1 and [Qtd Odometros Distintos] > 1 then
                "DUPLICIDADE COM ODOMETROS DIFERENTES"
            else if [Qtd Registros MaxTrack] > 1 then
                "DUPLICIDADE MESMO ODOMETRO"
            else
                "OK",
        type text
    ),

    AddRequerRevisao = Table.AddColumn(
        AddClassificacao,
        "Requer Revisão",
        each [Classificação MaxTrack] <> "OK",
        type logical
    ),

    Resultado = Table.Sort(
        AddRequerRevisao,
        {
            {"Classificação MaxTrack", Order.Ascending},
            {"Núcleo", Order.Ascending},
            {"Filial", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    Resultado
