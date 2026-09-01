let
    // ============================================================
    // STAGING — MAXTRACK RAW
    // Origem: stg_SP_MaxTrack
    // Objetivo: abrir o export corrente e preservar os registros
    // antes de filtrar a frota oficial ou resolver duplicidades.
    // ============================================================

    LimparCabecalho = (valor as nullable any) as nullable text =>
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
                                            Text.Replace(T0, "Ô", "O"),
                                        "Õ", "O"),
                                    "Ó", "O"),
                                "Ò", "O"),
                            "Ö", "O"),
                        "Ê", "E"),
                    "É", "E"),
                "È", "E"),
            T2 = if T1 = null then null else Text.Remove(T1, {" ", "_", "-", ".", "/", "º", "ª"})
        in
            T2,

    Fonte = stg_SP_MaxTrack,

    Arquivos = Table.SelectRows(
        Fonte,
        each
            let
                Nome = Text.From(Record.FieldOrDefault(_, "Name", "")),
                Ext = Text.Lower(Text.From(Record.FieldOrDefault(_, "Extension", ""))),
                Conteudo = Record.FieldOrDefault(_, "Content", null)
            in
                Ext = ".xlsx"
                    and not Text.StartsWith(Nome, "~$")
                    and Nome <> "Frotas Nordeste.xlsx"
                    and Value.Is(Conteudo, type binary)
    ),

    ValidarArquivos =
        if Table.RowCount(Arquivos) = 0 then
            error Error.Record(
                "Arquivo não encontrado",
                "Nenhum export .xlsx válido foi encontrado em Dados MaxTrack.",
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
                "O export MaxTrack não contém planilha do tipo Sheet.",
                [Arquivo = NomeArquivo]
            )
        else
            Planilhas{0}[Data],

    RemoverLinhasIniciais = Table.Skip(ValidarPlanilha, 3),
    Cabecalhos = Table.PromoteHeaders(RemoverLinhasIniciais, [PromoteAllScalars = true]),
    NomesColunas = Table.ColumnNames(Cabecalhos),

    ColPlaca = List.First(List.Select(NomesColunas, each LimparCabecalho(_) = "PLACA"), null),
    ColOdometro = List.First(List.Select(NomesColunas, each LimparCabecalho(_) = "ODOMETRO"), null),

    ValidarEstrutura =
        if ColPlaca = null or ColOdometro = null then
            error Error.Record(
                "Estrutura inválida",
                "O export MaxTrack não contém as colunas Placa e Odômetro esperadas.",
                [Arquivo = NomeArquivo, Cabecalhos = NomesColunas]
            )
        else
            Cabecalhos,

    ParesRenomeacao = List.RemoveNulls({
        if ColPlaca <> "PLACA_BRUTA" then {ColPlaca, "PLACA_BRUTA"} else null,
        if ColOdometro <> "ODOMETRO_BRUTO" then {ColOdometro, "ODOMETRO_BRUTO"} else null
    }),

    RenomearEstruturais = Table.RenameColumns(
        ValidarEstrutura,
        ParesRenomeacao,
        MissingField.Ignore
    ),

    AddSourceFile = Table.AddColumn(RenomearEstruturais, "SourceFile", each NomeArquivo, type text),
    AddSourceCreated = Table.AddColumn(AddSourceFile, "SourceCreated", each DataCriacaoArquivo),
    AddSourceModified = Table.AddColumn(AddSourceCreated, "SourceModified", each DataModificacaoArquivo)
in
    AddSourceModified
