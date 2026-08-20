let
    // Navegação direta à pasta confirmada no diagnóstico de 20/08/2026.
    Fonte = SharePoint.Contents(
        "https://grupoultracloud.sharepoint.com/teams/UG-ExcelnciaemFrotas/Documentos Compartilhados/Manutenção e Disponibilidade/",
        [ApiVersion = 15, Implementation = "2.0"]
    ),

    Arquivo = Table.SelectRows(
        Fonte,
        each [Name] = "Programações Paradas Frotas.xlsm"
            and Value.Is(Record.FieldOrDefault(_, "Content", null), type binary)
    ),

    Conteudo =
        if Table.RowCount(Arquivo) = 0
        then error "Arquivo Programações Paradas Frotas.xlsm não encontrado na pasta Manutenção e Disponibilidade."
        else Arquivo{0}[Content],

    PastaExcel = Excel.Workbook(Conteudo, false, true),

    BaseDados0 = PastaExcel{[Item = "Base de Dados", Kind = "Sheet"]}[Data],

    BaseDados = Table.ReplaceErrorValues(
        BaseDados0,
        List.Transform(
            Table.ColumnNames(BaseDados0),
            each {_, null}
        )
    ),

    Coluna1Tratada = List.Transform(
        Table.Column(BaseDados, "Column1"),
        each if _ = null then null else Text.Trim(Text.From(_))
    ),

    LinhaCabecalho = List.PositionOf(Coluna1Tratada, "Placa"),

    LinhasAposCabecalho =
        if LinhaCabecalho < 0
        then error "Cabeçalho Placa não encontrado na coluna inicial da aba Base de Dados."
        else Table.Skip(BaseDados, LinhaCabecalho),

    CabecalhosPromovidos0 = Table.PromoteHeaders(
        LinhasAposCabecalho,
        [PromoteAllScalars = true]
    ),

    CabecalhosPromovidos = Table.ReplaceErrorValues(
        CabecalhosPromovidos0,
        List.Transform(
            Table.ColumnNames(CabecalhosPromovidos0),
            each {_, null}
        )
    ),

    FiltrarNordeste = Table.SelectRows(
        CabecalhosPromovidos,
        each try Text.Trim(Text.From([Mercado])) = "Empresarial Nordeste" otherwise false
    ),

    SelecionarColunas = Table.SelectColumns(
        FiltrarNordeste,
        {
            "Placa",
            "Frota",
            "Proprietário",
            "Mercado",
            "Filial",
            "Núcleo"
        },
        MissingField.Ignore
    ),

    RemoverErrosFinal = Table.ReplaceErrorValues(
        SelecionarColunas,
        List.Transform(
            Table.ColumnNames(SelecionarColunas),
            each {_, null}
        )
    ),

    ConverterParaTexto = Table.TransformColumns(
        RemoverErrosFinal,
        List.Transform(
            Table.ColumnNames(RemoverErrosFinal),
            each {_, each if _ = null then null else Text.From(_), type text}
        )
    )
in
    ConverterParaTexto
