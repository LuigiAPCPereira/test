let
    // ============================================================
    // STAGING — AUDITORIA MAXTRACK
    // Origem: stg_Frota + stg_MaxTrack
    // Granularidade: 1 linha por veículo oficial
    // Objetivo: medir cobertura, validade do odômetro e duplicidades.
    //
    // A detecção abaixo é tolerante às variações reais de cabeçalho.
    // Se a camada anterior expuser apenas ODOMETRO_BRUTO, a própria
    // auditoria converte o valor para KM antes de agrupar.
    // ============================================================

    NormalizarNome = (valor as nullable any) as nullable text =>
        let
            T0 = if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),
            T1 = if T0 = null then null else
                List.Accumulate(
                    {
                        {"Á", "A"}, {"À", "A"}, {"Â", "A"}, {"Ã", "A"}, {"Ä", "A"},
                        {"É", "E"}, {"È", "E"}, {"Ê", "E"}, {"Ë", "E"},
                        {"Í", "I"}, {"Ì", "I"}, {"Î", "I"}, {"Ï", "I"},
                        {"Ó", "O"}, {"Ò", "O"}, {"Ô", "O"}, {"Õ", "O"}, {"Ö", "O"},
                        {"Ú", "U"}, {"Ù", "U"}, {"Û", "U"}, {"Ü", "U"},
                        {"Ç", "C"}
                    },
                    T0,
                    (estado, par) => Text.Replace(estado, par{0}, par{1})
                ),
            T2 = if T1 = null then null else Text.Remove(T1, {" ", "_", "-", ".", "/", "º", "ª", "(" , ")"})
        in
            T2,

    NormalizarPlaca = (valor as nullable any) as nullable text =>
        let
            T = if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),
            Limpa = if T = null then null else Text.Remove(T, {" ", "-", ".", "/"})
        in
            if Limpa = null or Limpa = "" then null else Limpa,

    ConverterOdometro = (valor as nullable any, nomeColuna as text) as nullable number =>
        let
            NomeNormalizado = NormalizarNome(nomeColuna),
            TextoValor = if valor = null then null else Text.Trim(Text.From(valor)),
            Digitos = if TextoValor = null then null else Text.Select(TextoValor, {"0".."9"}),
            Resultado =
                if valor = null then
                    null
                else if Text.Contains(NomeNormalizado, "BRUTO") then
                    let
                        SemTresFinais =
                            if Digitos = null or Text.Length(Digitos) <= 3 then null
                            else Text.Start(Digitos, Text.Length(Digitos) - 3)
                    in
                        try Number.FromText(SemTresFinais, "pt-BR") otherwise null
                else
                    try Number.From(valor)
                    otherwise try Number.FromText(TextoValor, "pt-BR")
                    otherwise try Number.FromText(Digitos, "pt-BR")
                    otherwise null
        in
            Resultado,

    FonteMaxTrack = stg_MaxTrack,
    NomesColunas = Table.ColumnNames(FonteMaxTrack),

    CandidatosPlacaNormalizada = List.Select(NomesColunas, each NormalizarNome(_) = "PLACANORMALIZADA"),
    CandidatosPlaca = List.Select(NomesColunas, each NormalizarNome(_) = "PLACA"),
    ColPlaca = List.First(List.Combine({CandidatosPlacaNormalizada, CandidatosPlaca}), null),

    CandidatosOdometroKM = List.Select(NomesColunas, each NormalizarNome(_) = "ODOMETROKM"),
    CandidatosOdometroComKM = List.Select(
        NomesColunas,
        each Text.Contains(NormalizarNome(_), "ODOMETRO")
            and Text.Contains(NormalizarNome(_), "KM")
            and not Text.Contains(NormalizarNome(_), "BRUTO")
    ),
    CandidatosOdometroExato = List.Select(NomesColunas, each NormalizarNome(_) = "ODOMETRO"),
    CandidatosOdometroBruto = List.Select(NomesColunas, each Text.Contains(NormalizarNome(_), "ODOMETRO") and Text.Contains(NormalizarNome(_), "BRUTO")),
    CandidatosOdometroQualquer = List.Select(NomesColunas, each Text.Contains(NormalizarNome(_), "ODOMETRO")),

    ColOdometro = List.First(
        List.Distinct(
            List.Combine({
                CandidatosOdometroKM,
                CandidatosOdometroComKM,
                CandidatosOdometroExato,
                CandidatosOdometroBruto,
                CandidatosOdometroQualquer
            })
        ),
        null
    ),

    ColSourceFile = List.First(List.Select(NomesColunas, each NormalizarNome(_) = "SOURCEFILE"), null),

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
            FonteMaxTrack,

    AddPlacaAudit = Table.AddColumn(
        ValidarEstrutura,
        "Placa Audit",
        each NormalizarPlaca(Record.Field(_, ColPlaca)),
        type nullable text
    ),

    AddOdometroAudit = Table.AddColumn(
        AddPlacaAudit,
        "Odometro Audit KM",
        each ConverterOdometro(Record.Field(_, ColOdometro), ColOdometro),
        Int64.Type
    ),

    AddSourceFileAudit =
        if ColSourceFile <> null then
            Table.AddColumn(
                AddOdometroAudit,
                "SourceFile Audit",
                each try Text.From(Record.Field(_, ColSourceFile)) otherwise null,
                type nullable text
            )
        else
            Table.AddColumn(AddOdometroAudit, "SourceFile Audit", each null, type nullable text),

    ResumoMaxTrack = Table.Group(
        AddSourceFileAudit,
        {"Placa Audit"},
        {
            {"Qtd Registros MaxTrack", each Table.RowCount(_), Int64.Type},
            {"Qtd Odometros Válidos", each List.Count(List.RemoveNulls(Table.Column(_, "Odometro Audit KM"))), Int64.Type},
            {"Qtd Odometros Distintos", each List.Count(List.Distinct(List.RemoveNulls(Table.Column(_, "Odometro Audit KM")))), Int64.Type},
            {
                "Odometros KM",
                each Text.Combine(
                    List.Transform(
                        List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "Odometro Audit KM"))), Order.Descending),
                        each Number.ToText(_, "0", "pt-BR")
                    ),
                    " | "
                ),
                type text
            },
            {
                "Arquivos Fonte",
                each Text.Combine(List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "SourceFile Audit")))), " | "),
                type text
            }
        }
    ),

    FrotaOficial0 = Table.SelectColumns(
        stg_Frota,
        {"Núcleo", "Filial", "Placa", "Frota", "Placa Normalizada"}
    ),

    FrotaOficial = Table.AddColumn(
        FrotaOficial0,
        "Placa Audit",
        each NormalizarPlaca([Placa Normalizada]),
        type nullable text
    ),

    MergeResumo = Table.NestedJoin(
        FrotaOficial,
        {"Placa Audit"},
        ResumoMaxTrack,
        {"Placa Audit"},
        "MaxTrack",
        JoinKind.LeftOuter
    ),

    ExpandResumo = Table.ExpandTableColumn(
        MergeResumo,
        "MaxTrack",
        {"Qtd Registros MaxTrack", "Qtd Odometros Válidos", "Qtd Odometros Distintos", "Odometros KM", "Arquivos Fonte"},
        {"Qtd Registros MaxTrack", "Qtd Odometros Válidos", "Qtd Odometros Distintos", "Odometros KM", "Arquivos Fonte"}
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
            if [Qtd Registros MaxTrack] = 0 then "SEM REGISTRO MAXTRACK"
            else if [Qtd Odometros Válidos] = 0 then "ODOMETRO AUSENTE OU INVÁLIDO"
            else if [Qtd Registros MaxTrack] > 1 and [Qtd Odometros Distintos] > 1 then "DUPLICIDADE COM ODOMETROS DIFERENTES"
            else if [Qtd Registros MaxTrack] > 1 then "DUPLICIDADE MESMO ODOMETRO"
            else "OK",
        type text
    ),

    AddRequerRevisao = Table.AddColumn(
        AddClassificacao,
        "Requer Revisão",
        each [Classificação MaxTrack] <> "OK",
        type logical
    ),

    Resultado = Table.Sort(
        Table.RemoveColumns(AddRequerRevisao, {"Placa Audit"}, MissingField.Ignore),
        {
            {"Classificação MaxTrack", Order.Ascending},
            {"Núcleo", Order.Ascending},
            {"Filial", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    Resultado
