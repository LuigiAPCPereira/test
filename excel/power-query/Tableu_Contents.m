let
    DataReferencia = Date.From(DateTime.FixedLocalNow()),
    DiasOsAntiga = 30,

    TextoTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    TextoUpper = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    // Fonte já navegada diretamente até Dados Tableau.
    Fonte = FonteTableu_Contents,

    // Frota oficial usada como fonte de verdade para placa, núcleo e filial.
    Mapeamento0 = Table.SelectColumns(
        ConsultarFrotasNordeste,
        {"Frota", "Placa", "Núcleo", "Filial"},
        MissingField.UseNull
    ),

    Mapeamento1 = Table.TransformColumns(
        Mapeamento0,
        {
            {"Frota", each TextoTrim(_), type nullable text},
            {"Placa", each TextoUpper(_), type nullable text},
            {"Núcleo", each TextoTrim(_), type nullable text},
            {"Filial", each TextoTrim(_), type nullable text}
        }
    ),

    MapeamentoValido = Table.SelectRows(
        Mapeamento1,
        each [Frota] <> null and [Frota] <> ""
            and [Placa] <> null and [Placa] <> ""
            and [Núcleo] <> null and [Núcleo] <> ""
    ),

    Mapeamento = Table.Buffer(
        Table.Distinct(
            Table.Sort(MapeamentoValido, {{"Frota", Order.Ascending}}),
            {"Frota"}
        )
    ),

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
                "Erro de Validação",
                "Nenhum arquivo Excel (.xlsx) encontrado em Dados Tableau.",
                "Verifique FonteTableu_Contents e os arquivos da pasta."
            )
        else
            Arquivos,

    ArquivoMaisRecente = Table.Sort(ValidarArquivos, {{"Date modified", Order.Descending}}){0}[Content],
    Workbook = Excel.Workbook(ArquivoMaisRecente, null, true),
    PrimeiraPlanilha = Workbook{0}[Data],
    Cabecalhos = Table.PromoteHeaders(PrimeiraPlanilha, [PromoteAllScalars = true]),

    ColunasEsperadas = {
        "OS",
        "FROTA",
        "FILIAL",
        "TIPO_SERVICO_OS",
        "DESCRICAO_DO_PROBLEMA",
        "RECORRENCIA",
        "STATUS",
        "TIPO_SERVICO_DESCR",
        "DATA_DA_SOLICITACAO",
        "ALTERADO_DATA",
        "PREENCHIDO_POR"
    },

    ColunasFaltando = List.Difference(ColunasEsperadas, Table.ColumnNames(Cabecalhos)),

    ValidarEstrutura =
        if List.Count(ColunasFaltando) > 0 then
            error Error.Record(
                "Erro de Estrutura",
                "A planilha Tableau não contém as colunas esperadas.",
                "Colunas faltando: " & Text.Combine(ColunasFaltando, ", ")
            )
        else
            Cabecalhos,

    FiltrarFilial = Table.SelectRows(
        ValidarEstrutura,
        each try Text.Trim(Text.From([FILIAL])) = "34" otherwise false
    ),

    FiltrarGP = Table.SelectRows(
        FiltrarFilial,
        each try Text.Upper(Text.Trim(Text.From([TIPO_SERVICO_OS]))) = "GP" otherwise false
    ),

    RemoverDesnecessarias = Table.RemoveColumns(
        FiltrarGP,
        {
            "DESCRIÇÃO_FALHA",
            "COD_FALHA",
            "TIPO_SERVICO_OS",
            "FILIAL",
            "DESC_CLASSE_FALHA",
            "CLASSE_FALHA",
            "TAG",
            "DATA_PREVISTA_INICIO",
            "DATA_PREVISTA_SAIDA",
            "DATA_EFETIVA_INICIO",
            "DATA_EFETIVA_SAIDA"
        },
        MissingField.Ignore
    ),

    Renomear = Table.RenameColumns(
        RemoverDesnecessarias,
        {
            {"DESCRICAO_DO_PROBLEMA", "Descrição"},
            {"TIPO_SERVICO_DESCR", "TIPO_DE_SERVICO"}
        },
        MissingField.Ignore
    ),

    Tipar = Table.TransformColumnTypes(
        Renomear,
        {
            {"OS", type text},
            {"FROTA", type text},
            {"Descrição", type text},
            {"RECORRENCIA", type text},
            {"STATUS", type text},
            {"TIPO_DE_SERVICO", type text},
            {"DATA_DA_SOLICITACAO", type datetime},
            {"ALTERADO_DATA", type datetime},
            {"PREENCHIDO_POR", type text}
        },
        "pt-BR"
    ),

    Normalizar = Table.TransformColumns(
        Tipar,
        {
            {"OS", each TextoTrim(_), type nullable text},
            {"FROTA", each TextoTrim(_), type nullable text},
            {"Descrição", each TextoTrim(_), type nullable text},
            {"RECORRENCIA", each TextoTrim(_), type nullable text},
            {"STATUS", each TextoUpper(_), type nullable text},
            {"TIPO_DE_SERVICO", each TextoTrim(_), type nullable text},
            {"PREENCHIDO_POR", each TextoTrim(_), type nullable text}
        }
    ),

    AddDiasEmAberto = Table.AddColumn(
        Normalizar,
        "DIAS_EM_ABERTO",
        each if [DATA_DA_SOLICITACAO] = null
            then null
            else Duration.Days(DataReferencia - Date.From([DATA_DA_SOLICITACAO])),
        Int64.Type
    ),

    AddStatusOS = Table.AddColumn(
        AddDiasEmAberto,
        "STATUS_OS",
        each if [DATA_DA_SOLICITACAO] = null then "Sem Data"
            else if [DIAS_EM_ABERTO] > DiasOsAntiga then "OS Antiga"
            else "OS Aberta",
        type text
    ),

    MergeMapa = Table.NestedJoin(
        AddStatusOS,
        {"FROTA"},
        Mapeamento,
        {"Frota"},
        "Mapa",
        JoinKind.Inner
    ),

    ExpandirMapa = Table.ExpandTableColumn(
        MergeMapa,
        "Mapa",
        {"Placa", "Núcleo", "Filial"},
        {"PLACA", "NUCLEO", "FILIAL"}
    ),

    FiltrarIdentificacao = Table.SelectRows(
        ExpandirMapa,
        each [PLACA] <> null and [PLACA] <> ""
            and [NUCLEO] <> null and [NUCLEO] <> ""
    ),

    Selecionar = Table.SelectColumns(
        FiltrarIdentificacao,
        {
            "NUCLEO",
            "FILIAL",
            "PLACA",
            "FROTA",
            "OS",
            "Descrição",
            "RECORRENCIA",
            "STATUS",
            "STATUS_OS",
            "DIAS_EM_ABERTO",
            "TIPO_DE_SERVICO",
            "DATA_DA_SOLICITACAO",
            "ALTERADO_DATA",
            "PREENCHIDO_POR"
        },
        MissingField.UseNull
    ),

    Resultado = Table.Sort(
        Selecionar,
        {
            {"STATUS_OS", Order.Descending},
            {"DIAS_EM_ABERTO", Order.Descending},
            {"NUCLEO", Order.Ascending},
            {"FILIAL", Order.Ascending},
            {"PLACA", Order.Ascending},
            {"DATA_DA_SOLICITACAO", Order.Ascending}
        }
    )
in
    Resultado
