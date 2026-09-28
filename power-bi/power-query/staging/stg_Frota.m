let
    // ============================================================
    // STAGING — FROTA OFICIAL NORDESTE
    // Origem: stg_SP_PlanilhaMae
    // Arquivo: Programações Paradas Frotas.xlsm
    // Aba: Base de Dados
    // Escopo: Mercado = Empresarial Nordeste
    //
    // IMPORTANTE:
    // - não aplica Table.Distinct;
    // - não cria chave substituta;
    // - não elimina placa/frota vazia;
    // - preserva duplicidades reais para o Gate 2B;
    // - expõe colunas auxiliares de qualidade antes da DimFrota.
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

    NormalizarFrota = (valor as nullable any) as nullable text =>
        let
            T = TextoUpper(valor)
        in
            if T = null or T = "" then null else T,

    Fonte = stg_SP_PlanilhaMae,

    ArquivosMae = Table.SelectRows(
        Fonte,
        each
            Text.From(Record.FieldOrDefault(_, "Name", "")) = "Programações Paradas Frotas.xlsm"
            and Value.Is(Record.FieldOrDefault(_, "Content", null), type binary)
    ),

    ValidarArquivo =
        if Table.RowCount(ArquivosMae) = 0 then
            error Error.Record(
                "Arquivo não encontrado",
                "Programações Paradas Frotas.xlsm não foi encontrado no staging da planilha mãe.",
                null
            )
        else if Table.RowCount(ArquivosMae) > 1 then
            error Error.Record(
                "Arquivo duplicado",
                "Mais de um arquivo chamado Programações Paradas Frotas.xlsm foi encontrado no staging da planilha mãe.",
                [Quantidade = Table.RowCount(ArquivosMae)]
            )
        else
            ArquivosMae{0}[Content],

    Workbook = Excel.Workbook(ValidarArquivo, false, true),

    AbaBase = Table.SelectRows(
        Workbook,
        each [Item] = "Base de Dados" and [Kind] = "Sheet"
    ),

    ValidarAba =
        if Table.RowCount(AbaBase) = 0 then
            error Error.Record(
                "Aba não encontrada",
                "A aba 'Base de Dados' não foi encontrada em Programações Paradas Frotas.xlsm.",
                null
            )
        else if Table.RowCount(AbaBase) > 1 then
            error Error.Record(
                "Aba ambígua",
                "Mais de uma aba 'Base de Dados' foi encontrada.",
                [Quantidade = Table.RowCount(AbaBase)]
            )
        else
            AbaBase{0}[Data],

    BaseSemErros = Table.ReplaceErrorValues(
        ValidarAba,
        List.Transform(Table.ColumnNames(ValidarAba), each {_, null})
    ),

    PrimeiraColuna = Table.ColumnNames(BaseSemErros){0},

    PrimeiraColunaTratada = List.Transform(
        Table.Column(BaseSemErros, PrimeiraColuna),
        each TextoTrim(_)
    ),

    LinhaCabecalho = List.PositionOf(PrimeiraColunaTratada, "Placa"),

    ValidarCabecalho =
        if LinhaCabecalho < 0 then
            error Error.Record(
                "Cabeçalho não encontrado",
                "Não foi possível localizar o cabeçalho 'Placa' na primeira coluna da aba Base de Dados.",
                null
            )
        else
            Table.Skip(BaseSemErros, LinhaCabecalho),

    CabecalhosPromovidos = Table.PromoteHeaders(
        ValidarCabecalho,
        [PromoteAllScalars = true]
    ),

    ColunasObrigatorias = {
        "Núcleo",
        "Filial",
        "Placa",
        "Frota",
        "Proprietário",
        "Mercado"
    },

    ColunasFaltantes = List.Difference(
        ColunasObrigatorias,
        Table.ColumnNames(CabecalhosPromovidos)
    ),

    ValidarEstrutura =
        if List.Count(ColunasFaltantes) > 0 then
            error Error.Record(
                "Estrutura inválida",
                "A aba Base de Dados não contém todas as colunas obrigatórias para a frota oficial.",
                [ColunasFaltantes = ColunasFaltantes]
            )
        else
            CabecalhosPromovidos,

    FiltrarNordeste = Table.SelectRows(
        ValidarEstrutura,
        each try TextoTrim([Mercado]) = "Empresarial Nordeste" otherwise false
    ),

    SelecionarColunas = Table.SelectColumns(
        FiltrarNordeste,
        ColunasObrigatorias,
        MissingField.UseNull
    ),

    NormalizarTexto = Table.TransformColumns(
        SelecionarColunas,
        {
            {"Núcleo", each TextoTrim(_), type nullable text},
            {"Filial", each TextoTrim(_), type nullable text},
            {"Placa", each TextoUpper(_), type nullable text},
            {"Frota", each TextoUpper(_), type nullable text},
            {"Proprietário", each TextoTrim(_), type nullable text},
            {"Mercado", each TextoTrim(_), type nullable text}
        }
    ),

    AddPlacaNormalizada = Table.AddColumn(
        NormalizarTexto,
        "Placa Normalizada",
        each NormalizarPlaca([Placa]),
        type nullable text
    ),

    AddFrotaNormalizada = Table.AddColumn(
        AddPlacaNormalizada,
        "Frota Normalizada",
        each NormalizarFrota([Frota]),
        type nullable text
    ),

    ContagemPlaca = Table.Group(
        Table.SelectRows(AddFrotaNormalizada, each [#"Placa Normalizada"] <> null),
        {"Placa Normalizada"},
        {{"Qtd Placa", each Table.RowCount(_), Int64.Type}}
    ),

    MergeContagemPlaca = Table.NestedJoin(
        AddFrotaNormalizada,
        {"Placa Normalizada"},
        ContagemPlaca,
        {"Placa Normalizada"},
        "AuditoriaPlaca",
        JoinKind.LeftOuter
    ),

    ExpandContagemPlaca = Table.ExpandTableColumn(
        MergeContagemPlaca,
        "AuditoriaPlaca",
        {"Qtd Placa"},
        {"Qtd Placa"}
    ),

    ContagemFrota = Table.Group(
        Table.SelectRows(ExpandContagemPlaca, each [#"Frota Normalizada"] <> null),
        {"Frota Normalizada"},
        {{"Qtd Frota", each Table.RowCount(_), Int64.Type}}
    ),

    MergeContagemFrota = Table.NestedJoin(
        ExpandContagemPlaca,
        {"Frota Normalizada"},
        ContagemFrota,
        {"Frota Normalizada"},
        "AuditoriaFrota",
        JoinKind.LeftOuter
    ),

    ExpandContagemFrota = Table.ExpandTableColumn(
        MergeContagemFrota,
        "AuditoriaFrota",
        {"Qtd Frota"},
        {"Qtd Frota"}
    ),

    AddQualidadePlaca = Table.AddColumn(
        ExpandContagemFrota,
        "Qualidade Placa",
        each
            if [#"Placa Normalizada"] = null then "PLACA VAZIA"
            else if [#"Qtd Placa"] > 1 then "PLACA DUPLICADA"
            else "OK",
        type text
    ),

    AddQualidadeFrota = Table.AddColumn(
        AddQualidadePlaca,
        "Qualidade Frota",
        each
            if [#"Frota Normalizada"] = null then "FROTA VAZIA"
            else if [#"Qtd Frota"] > 1 then "FROTA DUPLICADA"
            else "OK",
        type text
    ),

    AddIntegridade = Table.AddColumn(
        AddQualidadeFrota,
        "Integridade",
        each
            if [#"Qualidade Placa"] <> "OK" and [#"Qualidade Frota"] <> "OK" then
                [#"Qualidade Placa"] & " + " & [#"Qualidade Frota"]
            else if [#"Qualidade Placa"] <> "OK" then [#"Qualidade Placa"]
            else if [#"Qualidade Frota"] <> "OK" then [#"Qualidade Frota"]
            else "OK",
        type text
    ),

    Resultado = Table.Sort(
        Table.ReorderColumns(
            AddIntegridade,
            {
                "Núcleo",
                "Filial",
                "Placa",
                "Frota",
                "Proprietário",
                "Mercado",
                "Placa Normalizada",
                "Frota Normalizada",
                "Qtd Placa",
                "Qtd Frota",
                "Qualidade Placa",
                "Qualidade Frota",
                "Integridade"
            }
        ),
        {
            {"Núcleo", Order.Ascending},
            {"Filial", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    Resultado
