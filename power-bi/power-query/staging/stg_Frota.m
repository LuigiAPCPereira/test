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
    // - não oculta duplicidades;
    // - serve de base para validar unicidade antes da DimFrota.
    // ============================================================

    TextoTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    TextoUpper = (valor as nullable any) as nullable text =>
        let
            T = TextoTrim(valor)
        in
            if T = null then null else Text.Upper(T),

    Fonte = stg_SP_PlanilhaMae,

    ArquivosMae = Table.SelectRows(
        Fonte,
        each
            [Name] = "Programações Paradas Frotas.xlsm"
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
        each TextoTrim([Mercado]) = "Empresarial Nordeste"
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
            {"Frota", each TextoTrim(_), type nullable text},
            {"Proprietário", each TextoTrim(_), type nullable text},
            {"Mercado", each TextoTrim(_), type nullable text}
        }
    ),

    Resultado = Table.Sort(
        NormalizarTexto,
        {
            {"Núcleo", Order.Ascending},
            {"Filial", Order.Ascending},
            {"Placa", Order.Ascending}
        }
    )
in
    Resultado
