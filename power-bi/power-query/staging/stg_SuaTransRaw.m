let
    // ============================================================
    // STAGING — SUATRANS RAW
    // Origem: stg_SP_SuaTrans
    // Objetivo: abrir o export corrente e preservar todos os registros
    // antes de filtros de frota, recorte documental ou deduplicação.
    // ============================================================

    Fonte = stg_SP_SuaTrans,

    Arquivos = Table.SelectRows(
        Fonte,
        each
            let
                Nome = Text.From(Record.FieldOrDefault(_, "Name", "")),
                Conteudo = Record.FieldOrDefault(_, "Content", null)
            in
                Text.EndsWith(Text.Lower(Nome), ".xlsx")
                    and not Text.StartsWith(Nome, "~$")
                    and Value.Is(Conteudo, type binary)
    ),

    ValidarArquivos =
        if Table.RowCount(Arquivos) = 0 then
            error Error.Record(
                "Arquivo não encontrado",
                "Nenhum export .xlsx válido foi encontrado em Dados Suastrans.",
                null
            )
        else
            Arquivos,

    ArquivosOrdenados =
        if List.Contains(Table.ColumnNames(ValidarArquivos), "Date modified") then
            Table.Sort(ValidarArquivos, {{"Date modified", Order.Descending}})
        else
            ValidarArquivos,

    ArquivoAtual = ArquivosOrdenados{0},
    ConteudoAtual = ArquivoAtual[Content],
    NomeArquivo = Text.From(Record.FieldOrDefault(ArquivoAtual, "Name", "")),
    DataCriacaoArquivo = Record.FieldOrDefault(ArquivoAtual, "Date created", null),
    DataModificacaoArquivo = Record.FieldOrDefault(ArquivoAtual, "Date modified", null),

    Workbook = Excel.Workbook(ConteudoAtual, null, true),
    Planilhas = Table.SelectRows(Workbook, each [Kind] = "Sheet"),

    ValidarPlanilha =
        if Table.RowCount(Planilhas) = 0 then
            error Error.Record(
                "Planilha não encontrada",
                "O export SuaTrans não contém nenhuma planilha do tipo Sheet.",
                [Arquivo = NomeArquivo]
            )
        else
            Planilhas{0}[Data],

    ValidarLargura =
        if Table.ColumnCount(ValidarPlanilha) < 2 then
            error Error.Record(
                "Estrutura inválida",
                "O export SuaTrans não possui a quantidade mínima de colunas esperada.",
                [Arquivo = NomeArquivo, Colunas = Table.ColumnCount(ValidarPlanilha)]
            )
        else
            ValidarPlanilha,

    SegundaColuna = Table.ColumnNames(ValidarLargura){1},
    RemoverColunaVaziaLegada = Table.RemoveColumns(ValidarLargura, {SegundaColuna}),
    RemoverLinhaInicial = Table.Skip(RemoverColunaVaziaLegada, 1),
    PromoverCabecalhos = Table.PromoteHeaders(RemoverLinhaInicial, [PromoteAllScalars = true]),

    PrimeiraColuna = Table.ColumnNames(PromoverCabecalhos){0},
    RenomearFilial =
        if PrimeiraColuna = "Filial" then
            PromoverCabecalhos
        else
            Table.RenameColumns(PromoverCabecalhos, {{PrimeiraColuna, "Filial"}}),

    ColunasEsperadas = {
        "Filial",
        "Tipo",
        "Empresa/Placa/Pessoa",
        "CNPJ/Frota/CPF",
        "Tipo de Documento",
        "Validade",
        "Status",
        "Restritivo",
        "Nº Chamado",
        "Responsável",
        "Ação"
    },

    ColunasFaltantes = List.Difference(ColunasEsperadas, Table.ColumnNames(RenomearFilial)),

    ValidarEstrutura =
        if List.Count(ColunasFaltantes) > 0 then
            error Error.Record(
                "Estrutura inválida",
                "O export SuaTrans não contém todas as colunas esperadas.",
                [Arquivo = NomeArquivo, ColunasFaltantes = ColunasFaltantes]
            )
        else
            RenomearFilial,

    AddSourceFile = Table.AddColumn(ValidarEstrutura, "SourceFile", each NomeArquivo, type text),
    AddSourceCreated = Table.AddColumn(AddSourceFile, "SourceCreated", each DataCriacaoArquivo),
    AddSourceModified = Table.AddColumn(AddSourceCreated, "SourceModified", each DataModificacaoArquivo)
in
    AddSourceModified
