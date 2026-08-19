let
    // ============================================================
    // QUALIDADE DOS DADOS — TABELA DE EXCEÇÕES
    //
    // Se tudo estiver consistente, esta consulta tende a ficar vazia.
    // Verifica:
    // - placas ausentes/duplicadas no MaxTrack;
    // - documentos SuasTrans faltantes/duplicados por placa;
    // - integridade de Mano/Ter e Medidor;
    // - dados necessários da Preventiva Rodante;
    // - status inesperados nas OS do Tableau/Máximo.
    // ============================================================

    CodigosDocumentosEsperados = {
        "02.01", "02.02", "02.03", "02.04", "02.05",
        "02.06", "02.07", "02.08", "02.25"
    },

    TextoUpper = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    NomeDocumento = (codigo as text) as text =>
        if codigo = "02.01" then "Manômetro Vertical"
        else if codigo = "02.02" then "Medidor Mássico"
        else if codigo = "02.03" then "Termômetro"
        else if codigo = "02.04" then "Manômetro Horizontal"
        else if codigo = "02.05" then "CIPP"
        else if codigo = "02.06" then "CIV"
        else if codigo = "02.07" then "CRLV"
        else if codigo = "02.08" then "Cronotacógrafo"
        else if codigo = "02.25" then "Teste Hidrostático"
        else codigo,

    // -------- Frota oficial --------
    PlacasFrota0 = Table.SelectColumns(
        ConsultarFrotasNordeste,
        {"Placa", "Frota", "NUCLEO", "Filial"},
        MissingField.UseNull
    ),

    PlacasFrota1 = Table.TransformColumns(
        PlacasFrota0,
        {
            {"Placa", each TextoUpper(_), type nullable text},
            {"Frota", each TextoUpper(_), type nullable text}
        }
    ),

    PlacasFrota = Table.Distinct(
        Table.SelectRows(PlacasFrota1, each [Placa] <> null and [Placa] <> ""),
        {"Placa"}
    ),

    // -------- MaxTrack: ausentes --------
    MaxTrackNormalizado = Table.TransformColumns(
        Table.SelectColumns(MaxTrack, {"PLACA"}, MissingField.UseNull),
        {{"PLACA", each TextoUpper(_), type nullable text}}
    ),

    MaxTrackValido = Table.SelectRows(MaxTrackNormalizado, each [PLACA] <> null and [PLACA] <> ""),
    PlacasMax = List.Buffer(List.Distinct(Table.Column(MaxTrackValido, "PLACA"))),

    SemMaxTrack0 = Table.SelectRows(PlacasFrota, each not List.Contains(PlacasMax, [Placa])),
    SemMaxTrack1 = Table.AddColumn(SemMaxTrack0, "Gravidade", each "ERRO", type text),
    SemMaxTrack2 = Table.AddColumn(SemMaxTrack1, "Origem", each "MaxTrack", type text),
    SemMaxTrack3 = Table.AddColumn(SemMaxTrack2, "Problema", each "PLACA SEM KM", type text),
    SemMaxTrack = Table.AddColumn(SemMaxTrack3, "Detalhe", each "A placa está na frota Nordeste, mas não apareceu no MaxTrack.", type text),

    // -------- MaxTrack: duplicidades --------
    MaxAgrupado = Table.Group(MaxTrackValido, {"PLACA"}, {{"Qtd", each Table.RowCount(_), Int64.Type}}),
    MaxDuplicado0 = Table.SelectRows(MaxAgrupado, each [Qtd] > 1),
    MaxDuplicado1 = Table.NestedJoin(MaxDuplicado0, {"PLACA"}, PlacasFrota, {"Placa"}, "FrotaBase", JoinKind.Inner),
    MaxDuplicado2 = Table.ExpandTableColumn(MaxDuplicado1, "FrotaBase", {"Frota", "NUCLEO", "Filial"}, {"Frota", "NUCLEO", "Filial"}),
    MaxDuplicado3 = Table.RenameColumns(MaxDuplicado2, {{"PLACA", "Placa"}}),
    MaxDuplicado4 = Table.AddColumn(MaxDuplicado3, "Gravidade", each "ERRO", type text),
    MaxDuplicado5 = Table.AddColumn(MaxDuplicado4, "Origem", each "MaxTrack", type text),
    MaxDuplicado6 = Table.AddColumn(MaxDuplicado5, "Problema", each "PLACA DUPLICADA", type text),
    MaxDuplicado = Table.AddColumn(MaxDuplicado6, "Detalhe", each "Quantidade de registros no MaxTrack: " & Text.From([Qtd]), type text),

    // -------- SuasTrans: código por documento --------
    SuasBase0 = Table.SelectColumns(
        SuasTrans,
        {"Placa", "Tipo de Documento", "Validade"},
        MissingField.UseNull
    ),

    SuasBase1 = Table.TransformColumns(
        SuasBase0,
        {
            {"Placa", each TextoUpper(_), type nullable text},
            {"Tipo de Documento", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text}
        }
    ),

    SuasBase2 = Table.AddColumn(
        SuasBase1,
        "Codigo",
        each
            let t = [Tipo de Documento]
            in if t = null or Text.Length(t) < 5 then null else Text.Start(t, 5),
        type nullable text
    ),

    SuasBase = Table.SelectRows(
        SuasBase2,
        each [Placa] <> null and List.Contains(CodigosDocumentosEsperados, [Codigo])
    ),

    SuasAgrupado = Table.Group(
        SuasBase,
        {"Placa", "Codigo"},
        {{"Qtd", each Table.RowCount(_), Int64.Type}}
    ),

    // Combinação placa x documento esperado para detectar ausência completa.
    AddCodigosEsperados = Table.AddColumn(PlacasFrota, "Codigo", each CodigosDocumentosEsperados, type list),
    GradeEsperada = Table.ExpandListColumn(AddCodigosEsperados, "Codigo"),
    MergeDocs = Table.NestedJoin(GradeEsperada, {"Placa", "Codigo"}, SuasAgrupado, {"Placa", "Codigo"}, "Encontrado", JoinKind.LeftOuter),
    ExpandDocs = Table.ExpandTableColumn(MergeDocs, "Encontrado", {"Qtd"}, {"Qtd"}),
    QtdDocs = Table.TransformColumns(ExpandDocs, {{"Qtd", each if _ = null then 0 else Int64.From(_), Int64.Type}}),

    DocsFaltantes0 = Table.SelectRows(QtdDocs, each [Qtd] = 0),
    DocsFaltantes1 = Table.AddColumn(DocsFaltantes0, "Gravidade", each "ERRO", type text),
    DocsFaltantes2 = Table.AddColumn(DocsFaltantes1, "Origem", each "SuasTrans", type text),
    DocsFaltantes3 = Table.AddColumn(DocsFaltantes2, "Problema", each "DOCUMENTO FALTANTE", type text),
    DocsFaltantes = Table.AddColumn(DocsFaltantes3, "Detalhe", each [Codigo] & " — " & NomeDocumento([Codigo]), type text),

    DocsDuplicados0 = Table.SelectRows(QtdDocs, each [Qtd] > 1),
    DocsDuplicados1 = Table.AddColumn(DocsDuplicados0, "Gravidade", each "ERRO", type text),
    DocsDuplicados2 = Table.AddColumn(DocsDuplicados1, "Origem", each "SuasTrans", type text),
    DocsDuplicados3 = Table.AddColumn(DocsDuplicados2, "Problema", each "DOCUMENTO DUPLICADO", type text),
    DocsDuplicados = Table.AddColumn(
        DocsDuplicados3,
        "Detalhe",
        each [Codigo] & " — " & NomeDocumento([Codigo]) & " | registros: " & Text.From([Qtd]),
        type text
    ),

    // -------- Mano/Ter --------
    ManoTerProblemas0 = Table.SelectRows(ManoTer, each [Integridade] <> "OK"),
    ManoTerProblemas1 = Table.SelectColumns(ManoTerProblemas0, {"Placa", "Frota", "NUCLEO", "Filial", "Integridade", "Documentos faltantes", "Documentos duplicados"}, MissingField.UseNull),
    ManoTerProblemas2 = Table.AddColumn(ManoTerProblemas1, "Gravidade", each "ERRO", type text),
    ManoTerProblemas3 = Table.AddColumn(ManoTerProblemas2, "Origem", each "Mano/Ter", type text),
    ManoTerProblemas4 = Table.AddColumn(ManoTerProblemas3, "Problema", each [Integridade], type text),
    ManoTerProblemas = Table.AddColumn(
        ManoTerProblemas4,
        "Detalhe",
        each Text.Combine(
            List.RemoveNulls({
                if [#"Documentos faltantes"] = null then null else "Faltantes: " & [#"Documentos faltantes"],
                if [#"Documentos duplicados"] = null then null else "Duplicados: " & [#"Documentos duplicados"]
            }),
            " | "
        ),
        type text
    ),

    // -------- Medidor --------
    MedidorProblemas0 = Table.SelectRows(Medidor, each [Integridade] <> "OK"),
    MedidorProblemas1 = Table.SelectColumns(MedidorProblemas0, {"Placa", "Frota", "NUCLEO", "Filial", "Integridade", "Qtd registros"}, MissingField.UseNull),
    MedidorProblemas2 = Table.AddColumn(MedidorProblemas1, "Gravidade", each "ERRO", type text),
    MedidorProblemas3 = Table.AddColumn(MedidorProblemas2, "Origem", each "Medidor", type text),
    MedidorProblemas4 = Table.AddColumn(MedidorProblemas3, "Problema", each [Integridade], type text),
    MedidorProblemas = Table.AddColumn(MedidorProblemas4, "Detalhe", each "Quantidade de registros 02.02: " & Text.From([#"Qtd registros"]), type text),

    // -------- Preventiva Rodante --------
    PreventivaProblemas0 = Table.SelectRows(PreventivaRodante, each [Integridade] <> "OK"),
    PreventivaProblemas1 = Table.SelectColumns(PreventivaProblemas0, {"Placa", "Frota", "Núcleo", "Filial", "Integridade"}, MissingField.UseNull),
    PreventivaProblemas2 = Table.RenameColumns(PreventivaProblemas1, {{"Núcleo", "NUCLEO"}}, MissingField.Ignore),
    PreventivaProblemas3 = Table.AddColumn(PreventivaProblemas2, "Gravidade", each "ERRO", type text),
    PreventivaProblemas4 = Table.AddColumn(PreventivaProblemas3, "Origem", each "Preventiva Rodante", type text),
    PreventivaProblemas5 = Table.AddColumn(PreventivaProblemas4, "Problema", each [Integridade], type text),
    PreventivaProblemas = Table.AddColumn(PreventivaProblemas5, "Detalhe", each "Faltam dados necessários para calcular a preventiva com segurança.", type text),

    // -------- Documentos: campos inválidos --------
    DocsIntegridade0 = Table.SelectRows(DocumentosOperacionais, each [INTEGRIDADE] <> "OK"),
    DocsIntegridade1 = Table.SelectColumns(DocsIntegridade0, {"PLACA", "FROTA", "NUCLEO", "FILIAL", "TIPO DE DOCUMENTO", "INTEGRIDADE"}, MissingField.UseNull),
    DocsIntegridade2 = Table.RenameColumns(DocsIntegridade1, {{"PLACA", "Placa"}, {"FROTA", "Frota"}, {"FILIAL", "Filial"}}, MissingField.Ignore),
    DocsIntegridade3 = Table.AddColumn(DocsIntegridade2, "Gravidade", each "ERRO", type text),
    DocsIntegridade4 = Table.AddColumn(DocsIntegridade3, "Origem", each "SuasTrans", type text),
    DocsIntegridade5 = Table.AddColumn(DocsIntegridade4, "Problema", each [INTEGRIDADE], type text),
    DocsIntegridade = Table.AddColumn(DocsIntegridade5, "Detalhe", each if [#"TIPO DE DOCUMENTO"] = null then "Registro documental incompleto." else [#"TIPO DE DOCUMENTO"], type text),

    // -------- OS: status fora do fluxo conhecido --------
    OSProblemas0 = Table.SelectRows(OSOperacional, each [#"AÇÃO OPERACIONAL"] = "REVISAR STATUS" or [PLACA] = null or [NUCLEO] = null),
    OSProblemas1 = Table.SelectColumns(OSProblemas0, {"PLACA", "FROTA", "NUCLEO", "FILIAL", "STATUS", "OS"}, MissingField.UseNull),
    OSProblemas2 = Table.RenameColumns(OSProblemas1, {{"PLACA", "Placa"}, {"FROTA", "Frota"}, {"FILIAL", "Filial"}}, MissingField.Ignore),
    OSProblemas3 = Table.AddColumn(OSProblemas2, "Gravidade", each "ALERTA", type text),
    OSProblemas4 = Table.AddColumn(OSProblemas3, "Origem", each "Tableau/Máximo", type text),
    OSProblemas5 = Table.AddColumn(OSProblemas4, "Problema", each "OS FORA DO FLUXO", type text),
    OSProblemas = Table.AddColumn(
        OSProblemas5,
        "Detalhe",
        each "OS: " & (if [OS] = null then "sem número" else Text.From([OS])) & " | status: " & (if [STATUS] = null then "ausente" else Text.From([STATUS])),
        type text
    ),

    // -------- Padronização --------
    Padrao = {"Gravidade", "Origem", "Placa", "Frota", "NUCLEO", "Filial", "Problema", "Detalhe"},

    SemMaxTrackFinal = Table.SelectColumns(SemMaxTrack, Padrao, MissingField.UseNull),
    MaxDuplicadoFinal = Table.SelectColumns(MaxDuplicado, Padrao, MissingField.UseNull),
    DocsFaltantesFinal = Table.SelectColumns(DocsFaltantes, Padrao, MissingField.UseNull),
    DocsDuplicadosFinal = Table.SelectColumns(DocsDuplicados, Padrao, MissingField.UseNull),
    ManoTerFinal = Table.SelectColumns(ManoTerProblemas, Padrao, MissingField.UseNull),
    MedidorFinal = Table.SelectColumns(MedidorProblemas, Padrao, MissingField.UseNull),
    PreventivaFinal = Table.SelectColumns(PreventivaProblemas, Padrao, MissingField.UseNull),
    DocsIntegridadeFinal = Table.SelectColumns(DocsIntegridade, Padrao, MissingField.UseNull),
    OSFinal = Table.SelectColumns(OSProblemas, Padrao, MissingField.UseNull),

    Combinar = Table.Combine({
        SemMaxTrackFinal,
        MaxDuplicadoFinal,
        DocsFaltantesFinal,
        DocsDuplicadosFinal,
        ManoTerFinal,
        MedidorFinal,
        PreventivaFinal,
        DocsIntegridadeFinal,
        OSFinal
    }),

    AddOrdem = Table.AddColumn(
        Combinar,
        "Ordem Gravidade",
        each if [Gravidade] = "ERRO" then 1 else if [Gravidade] = "ALERTA" then 2 else 3,
        Int64.Type
    ),

    Ordenar = Table.Sort(
        AddOrdem,
        {
            {"Ordem Gravidade", Order.Ascending},
            {"Origem", Order.Ascending},
            {"NUCLEO", Order.Ascending},
            {"Placa", Order.Ascending},
            {"Problema", Order.Ascending}
        }
    )
in
    Ordenar
