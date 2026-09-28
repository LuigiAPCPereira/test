let
    // ============================================================
    // STAGING — DOCUMENTOS NORDESTE (SEM DEDUPLICAÇÃO)
    // Origem: stg_SuaTransRaw + stg_Frota
    // Objetivo: recortar os 9 documentos da frota oficial preservando
    // todas as ocorrências por placa + documento para auditoria.
    // ============================================================

    TextoTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    TextoUpper = (valor as nullable any) as nullable text =>
        let
            T = TextoTrim(valor)
        in
            if T = null then null else Text.Upper(T),

    NormalizarPlaca = (valor as nullable any) as nullable text =>
        let
            T = TextoUpper(valor),
            Limpa = if T = null then null else Text.Remove(T, {" ", "-", ".", "/"})
        in
            if Limpa = null or Limpa = "" then null else Limpa,

    DataReferenciaAtual = Date.From(DateTime.FixedLocalNow()),

    DocumentosValidos = {
        "02.01 - Calibração - Manômetro Analógico Vertical",
        "02.02 - Calibração - Medidor Mássico",
        "02.03 - Calibração - Termometro Analógico",
        "02.04 - Calibração - Manômetro Analógico Horizontal",
        "02.05 - CIPP",
        "02.06 - CIV",
        "02.07 - CRLV",
        "02.08 - Cronotacógrafo",
        "02.25 - Teste Hidrostático - Mangueira Flexível"
    },

    FonteRaw = stg_SuaTransRaw,

    NormalizarCamposTexto = Table.TransformColumns(
        FonteRaw,
        {
            {"Tipo", each TextoTrim(_), type nullable text},
            {"Empresa/Placa/Pessoa", each TextoUpper(_), type nullable text},
            {"CNPJ/Frota/CPF", each TextoTrim(_), type nullable text},
            {"Tipo de Documento", each TextoTrim(_), type nullable text},
            {"Status", each TextoTrim(_), type nullable text}
        }
    ),

    AddValidadeOrigem = Table.DuplicateColumn(
        NormalizarCamposTexto,
        "Validade",
        "Validade Origem"
    ),

    NormalizarValidade = Table.TransformColumns(
        AddValidadeOrigem,
        {
            {
                "Validade",
                each
                    let
                        Valor = _
                    in
                        if Valor = null then null
                        else
                            try Date.From(Valor)
                            otherwise try Date.FromText(Text.Trim(Text.From(Valor)), [Culture = "pt-BR"])
                            otherwise null,
                type nullable date
            }
        }
    ),

    FiltrarVeiculos = Table.SelectRows(
        NormalizarValidade,
        each TextoUpper([Tipo]) = "VEÍCULO"
    ),

    FiltrarDocumentosValidos = Table.SelectRows(
        FiltrarVeiculos,
        each [#"Tipo de Documento"] <> null
            and List.Contains(DocumentosValidos, [#"Tipo de Documento"])
    ),

    AddPlacaNormalizada = Table.AddColumn(
        FiltrarDocumentosValidos,
        "Placa Normalizada",
        each NormalizarPlaca([#"Empresa/Placa/Pessoa"]),
        type nullable text
    ),

    RenomearCamposFonte = Table.RenameColumns(
        AddPlacaNormalizada,
        {
            {"Filial", "Filial SuaTrans"},
            {"Empresa/Placa/Pessoa", "Placa SuaTrans"},
            {"CNPJ/Frota/CPF", "Frota SuaTrans"},
            {"Status", "Status Fonte"}
        },
        MissingField.Ignore
    ),

    FrotaOficial = Table.SelectColumns(
        stg_Frota,
        {"Placa Normalizada", "Núcleo", "Filial", "Placa", "Frota"}
    ),

    MergeFrota = Table.NestedJoin(
        RenomearCamposFonte,
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

    AddCodigoDocumento = Table.AddColumn(
        ExpandFrota,
        "Código Documento",
        each try Text.BeforeDelimiter([#"Tipo de Documento"], " - ") otherwise null,
        type nullable text
    ),

    AddStatusCalculado = Table.AddColumn(
        AddCodigoDocumento,
        "Status Calculado",
        each
            if [Validade] = null then "SEM VALIDADE"
            else if [Validade] < DataReferenciaAtual then "Vencido"
            else if Duration.Days([Validade] - DataReferenciaAtual) <= 30 then "Expirando"
            else "Válido",
        type text
    ),

    AddDataReferencia = Table.AddColumn(
        AddStatusCalculado,
        "DataReferencia",
        each DataReferenciaAtual,
        type date
    ),

    ContagemPlacaDocumento = Table.Group(
        AddDataReferencia,
        {"Placa Normalizada", "Tipo de Documento"},
        {{"Qtd Registros Placa Documento", each Table.RowCount(_), Int64.Type}}
    ),

    MergeContagem = Table.NestedJoin(
        AddDataReferencia,
        {"Placa Normalizada", "Tipo de Documento"},
        ContagemPlacaDocumento,
        {"Placa Normalizada", "Tipo de Documento"},
        "AuditoriaMultiplicidade",
        JoinKind.LeftOuter
    ),

    ExpandContagem = Table.ExpandTableColumn(
        MergeContagem,
        "AuditoriaMultiplicidade",
        {"Qtd Registros Placa Documento"},
        {"Qtd Registros Placa Documento"}
    ),

    AddMultiplicidade = Table.AddColumn(
        ExpandContagem,
        "Multiplicidade",
        each
            if [#"Qtd Registros Placa Documento"] > 1 then "MÚLTIPLOS REGISTROS"
            else "ÚNICO",
        type text
    ),

    Resultado = Table.Sort(
        Table.SelectColumns(
            AddMultiplicidade,
            {
                "Núcleo",
                "Filial",
                "Placa",
                "Frota",
                "Placa Normalizada",
                "Placa SuaTrans",
                "Frota SuaTrans",
                "Filial SuaTrans",
                "Código Documento",
                "Tipo de Documento",
                "Validade",
                "Validade Origem",
                "Status Fonte",
                "Status Calculado",
                "Qtd Registros Placa Documento",
                "Multiplicidade",
                "Restritivo",
                "Nº Chamado",
                "Responsável",
                "Ação",
                "DataReferencia",
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
            {"Código Documento", Order.Ascending},
            {"Validade", Order.Descending}
        }
    )
in
    Resultado
