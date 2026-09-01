let
    // ============================================================
    // STAGING — AUDITORIA MAXTRACK
    // Origem: stg_Frota + stg_MaxTrack
    // Granularidade: 1 linha por veículo oficial
    // Objetivo: medir cobertura, validade do odômetro e duplicidades.
    // ============================================================

    NormalizarNome = (valor as nullable any) as nullable text =>
        let
            T0 = if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),
            T1 = if T0 = null then null else
                Text.Replace(
                    Text.Replace(
                        Text.Replace(
                            Text.Replace(
                                Text.Replace(
                                    Text.Replace(
                                        Text.Replace(
                                            Text.Replace(
                                                Text.Replace(
                                                    Text.Replace(T0, "Ô", "O"),
                                                "Õ", "O"),
                                            "Ó", "O"),
                                        "Ò", "O"),
                                    "Ö", "O"),
                                "Ê", "E"),
                            "É", "E"),
                        "È", "E"),
                    "Á", "A"),
                "Í", "I"),
            T2 = if T1 = null then null else Text.Remove(T1, {" ", "_", "-", ".", "/", "º", "ª"})
        in
            T2,

    FonteMaxTrack0 = stg_MaxTrack,
    NomesColunas = Table.ColumnNames(FonteMaxTrack0),

    ColPlaca = List.First(
        List.Select(
            NomesColunas,
            each List.Contains({"PLACANORMALIZADA", "PLACA"}, NormalizarNome(_))
        ),
        null
    ),

    ColOdometro = List.First(
        List.Select(
            NomesColunas,
            each List.Contains({"ODOMETROKM", "ODOMETRO"}, NormalizarNome(_))
        ),
        null
    ),

    ColSourceFile = List.First(
        List.Select(NomesColunas, each NormalizarNome(_) = "SOURCEFILE"),
        null
    ),

    ValidarEstrutura =
        if ColPlaca = null or ColOdometro = null then
            error Error.Record(
                "Estrutura MaxTrack inválida",
                "Não foi possível identificar as colunas de placa e odômetro em stg_MaxTrack.",
                [
                    ColunaPlacaDetectada = ColPlaca,
                    ColunaOdometroDetectada = ColOdometro,
                    ColunasEncontradas = NomesColunas
                ]
            )
        else
            FonteMaxTrack0,

    Renomeacoes = List.RemoveNulls({
        if ColPlaca <> "Placa Normalizada" then {ColPlaca, "Placa Normalizada"} else null,
        if ColOdometro <> "Odometro KM" then {ColOdometro, "Odometro KM"} else null,
        if ColSourceFile <> null and ColSourceFile <> "SourceFile" then {ColSourceFile, "SourceFile"} else null
    }),

    FonteMaxTrack1 = Table.RenameColumns(ValidarEstrutura, Renomeacoes, MissingField.Ignore),

    FonteMaxTrack =
        if List.Contains(Table.ColumnNames(FonteMaxTrack1), "SourceFile") then
            FonteMaxTrack1
        else
            Table.AddColumn(FonteMaxTrack1, "SourceFile", each null, type nullable text),

    ResumoMaxTrack = Table.Group(
        FonteMaxTrack,
        {"Placa Normalizada"},
        {
            {"Qtd Registros MaxTrack", each Table.RowCount(_), Int64.Type},
            {
                "Qtd Odometros Válidos",
                each List.Count(List.RemoveNulls(Table.Column(_, "Odometro KM"))),
                Int64.Type
            },
            {
                "Qtd Odometros Distintos",
                each List.Count(List.Distinct(List.RemoveNulls(Table.Column(_, "Odometro KM")))),
                Int64.Type
            },
            {
                "Odometros KM",
                each Text.Combine(
                    List.Transform(
                        List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "Odometro KM"))), Order.Descending),
                        each Number.ToText(_, "0", "pt-BR")
                    ),
                    " | "
                ),
                type text
            },
            {
                "Arquivos Fonte",
                each Text.Combine(
                    List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "SourceFile")))),
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
        ResumoMaxTrack,
        {"Placa Normalizada"},
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
        {"Qtd Registros MaxTrack", "Qtd Odometros Válidos", "Qtd Odometros Distintos"}
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
