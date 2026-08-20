let
    // ============================================================
    // SUASTRANS — FONTE SHAREPOINT.Contents + ORDEM PADRÃO
    // ============================================================

    Create_TextCleaner = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    Create_TextTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    Create_MesAnoFormatado = (data as nullable date) as nullable text =>
        if data = null then null
        else Date.ToText(data, "yyyy-MM", "pt-BR")
            & " "
            & Text.Proper(Text.Replace(Date.ToText(data, "MMM", "pt-BR"), ".", "")),

    Create_DataReferenciaAtual = Date.From(DateTime.FixedLocalNow()),

    // Fonte otimizada já navegada até Dados Suastrans.
    Connect_PastaSuastrans = FonteSuasTrans_Contents,

    // Mapeamento oficial da frota Nordeste.
    Select_TabelaMapeamento = ConsultarFrotasNordeste,

    Transform_TiposMapeamento = Table.TransformColumnTypes(
        Select_TabelaMapeamento,
        {{"Placa", type text}, {"Núcleo", type text}, {"Filial", type text}},
        "pt-BR"
    ),

    Transform_NormalizarMapeamento = Table.TransformColumns(
        Transform_TiposMapeamento,
        {
            {"Placa", each Create_TextCleaner(_), type text},
            {"Núcleo", each Create_TextTrim(_), type text},
            {"Filial", each Create_TextTrim(_), type text}
        }
    ),

    Filter_MapeamentoPlacasValidas = Table.SelectRows(
        Transform_NormalizarMapeamento,
        each [Placa] <> null and [Placa] <> ""
    ),

    Sort_MapeamentoPorPlaca = Table.Sort(Filter_MapeamentoPlacasValidas, {{"Placa", Order.Ascending}}),
    Buffer_MapeamentoOrdenado = Table.Buffer(Sort_MapeamentoPorPlaca),
    Distinct_MapeamentoPorPlaca = Table.Distinct(Buffer_MapeamentoOrdenado, {"Placa"}),
    Buffer_MapeamentoPorPlaca = Table.Buffer(Distinct_MapeamentoPorPlaca),

    Create_ListaPlacasValidas = List.Distinct(List.RemoveNulls(Table.Column(Buffer_MapeamentoPorPlaca, "Placa"))),
    Create_RecordPlacasValidas = Record.FromList(List.Repeat({true}, List.Count(Create_ListaPlacasValidas)), Create_ListaPlacasValidas),
    Create_RecordNucleoPorPlaca = Record.FromList(Table.Column(Buffer_MapeamentoPorPlaca, "Núcleo"), Table.Column(Buffer_MapeamentoPorPlaca, "Placa")),
    Create_RecordFilialPorPlaca = Record.FromList(Table.Column(Buffer_MapeamentoPorPlaca, "Filial"), Table.Column(Buffer_MapeamentoPorPlaca, "Placa")),

    Create_ListaEmpresasExcluidas = {
        "G F NASCIMENTO SANTOS",
        "MELAURIMAR TRANSPORTES GERAIS LTDA (M) - SÃO PAULO / SP",
        "METALMONTE COMERCIO E SERVICOS LTDA",
        "SUPERGASBRAS ENERGIA LTDA (F) - POUSO ALEGRE MG",
        "SUPERGASBRAS ENERGIA LTDA (F) SAO JOSE DOS CAMPOS SP",
        "TRANSPORTADORA SIMAS LTDA"
    },

    Create_ListaEmpresasExcluidasNormalizada = List.Transform(Create_ListaEmpresasExcluidas, each Create_TextCleaner(_)),
    Create_RecordEmpresasExcluidas = Record.FromList(List.Repeat({true}, List.Count(Create_ListaEmpresasExcluidasNormalizada)), Create_ListaEmpresasExcluidasNormalizada),

    Create_ListaTiposDocumentoValidos = {
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

    Create_RecordTiposDocumentoValidos = Record.FromList(
        List.Repeat({true}, List.Count(Create_ListaTiposDocumentoValidos)),
        Create_ListaTiposDocumentoValidos
    ),

    Filter_ArquivosSuastrans = Table.SelectRows(
        Connect_PastaSuastrans,
        each
            let
                Nome = Text.From(Record.FieldOrDefault(_, "Name", "")),
                Conteudo = Record.FieldOrDefault(_, "Content", null)
            in
                Text.EndsWith(Text.Lower(Nome), ".xlsx")
                    and not Text.StartsWith(Nome, "~$")
                    and Value.Is(Conteudo, type binary)
    ),

    Validate_ArquivosSuastrans =
        if Table.RowCount(Filter_ArquivosSuastrans) = 0 then
            error Error.Record(
                "Erro de Validação",
                "Nenhum arquivo Excel (.xlsx) encontrado na pasta Dados Suastrans.",
                "Verifique a consulta FonteSuasTrans_Contents e se existem arquivos válidos."
            )
        else
            Filter_ArquivosSuastrans,

    Sort_ArquivosPorModificacao = Table.Sort(Validate_ArquivosSuastrans, {{"Date modified", Order.Descending}}),
    Get_ArquivoMaisRecente = Sort_ArquivosPorModificacao{0}[Content],

    Import_WorkbookSuastrans = Excel.Workbook(Get_ArquivoMaisRecente, null, true),
    Select_PrimeiraPlanilha = Import_WorkbookSuastrans{0}[Data],

    Remove_ColunaVazia = Table.RemoveColumns(Select_PrimeiraPlanilha, {Table.ColumnNames(Select_PrimeiraPlanilha){1}}),
    Skip_LinhaInicial = Table.Skip(Remove_ColunaVazia, 1),
    Promote_Cabecalhos = Table.PromoteHeaders(Skip_LinhaInicial, [PromoteAllScalars = true]),
    Rename_ColunaFilial = Table.RenameColumns(Promote_Cabecalhos, {{Table.ColumnNames(Promote_Cabecalhos){0}, "Filial"}}),

    Create_ColunasEsperadas = {
        "Filial", "Tipo", "Empresa/Placa/Pessoa", "CNPJ/Frota/CPF",
        "Tipo de Documento", "Validade", "Status", "Restritivo",
        "Nº Chamado", "Responsável", "Ação"
    },

    Validate_EstruturaColunas =
        let
            ColunasFaltando = List.RemoveItems(Create_ColunasEsperadas, Table.ColumnNames(Rename_ColunaFilial))
        in
            if List.Count(ColunasFaltando) > 0 then
                error Error.Record(
                    "Erro de Estrutura",
                    "A planilha não contém as colunas esperadas.",
                    "Colunas faltando: " & Text.Combine(ColunasFaltando, ", ")
                )
            else Rename_ColunaFilial,

    Transform_TiposBase = Table.TransformColumnTypes(
        Validate_EstruturaColunas,
        {
            {"Filial", type text}, {"Tipo", type text}, {"Empresa/Placa/Pessoa", type text},
            {"CNPJ/Frota/CPF", type text}, {"Tipo de Documento", type text}, {"Validade", type date},
            {"Status", type text}, {"Restritivo", type text}, {"Nº Chamado", Int64.Type},
            {"Responsável", type text}, {"Ação", type text}
        },
        "pt-BR"
    ),

    Transform_NormalizarBase = Table.TransformColumns(
        Transform_TiposBase,
        {
            {"Tipo", each Create_TextTrim(_), type text},
            {"Empresa/Placa/Pessoa", each Create_TextCleaner(_), type text},
            {"CNPJ/Frota/CPF", each Create_TextTrim(_), type text},
            {"Tipo de Documento", each Create_TextTrim(_), type text},
            {"Status", each Create_TextTrim(_), type text}
        }
    ),

    Filter_DadosEscopo = Table.SelectRows(
        Transform_NormalizarBase,
        each
            [Tipo] = "Veículo"
            and [#"Empresa/Placa/Pessoa"] <> null
            and not Record.HasFields(Create_RecordEmpresasExcluidas, [#"Empresa/Placa/Pessoa"])
            and Record.HasFields(Create_RecordPlacasValidas, [#"Empresa/Placa/Pessoa"])
    ),

    Rename_ColunasBase = Table.RenameColumns(Filter_DadosEscopo, {{"Empresa/Placa/Pessoa", "Placa"}, {"CNPJ/Frota/CPF", "Frota"}}),
    Remove_ColunasNaoUsadas = Table.RemoveColumns(Rename_ColunasBase, {"Tipo", "Ação", "Restritivo", "Responsável", "Nº Chamado"}, MissingField.Ignore),

    Filter_TiposDocumento = Table.SelectRows(
        Remove_ColunasNaoUsadas,
        each [#"Tipo de Documento"] <> null and Record.HasFields(Create_RecordTiposDocumentoValidos, [#"Tipo de Documento"])
    ),

    Add_NucleoMapeado = Table.AddColumn(
        Filter_TiposDocumento,
        "NUCLEO",
        each Record.FieldOrDefault(Create_RecordNucleoPorPlaca, [Placa], "OUTROS"),
        type text
    ),

    Add_FilialMapeada = Table.AddColumn(
        Add_NucleoMapeado,
        "FilialMapeada",
        each Record.FieldOrDefault(Create_RecordFilialPorPlaca, [Placa], "DESCONHECIDA"),
        type text
    ),

    Remove_FilialOriginal = Table.RemoveColumns(Add_FilialMapeada, {"Filial"}, MissingField.Ignore),
    Rename_FilialMapeada = Table.RenameColumns(Remove_FilialOriginal, {{"FilialMapeada", "Filial"}}),

    Add_DataReferencia = Table.AddColumn(Rename_FilialMapeada, "DataReferencia", each Create_DataReferenciaAtual, type date),

    Add_StatusCalculado = Table.AddColumn(
        Add_DataReferencia,
        "StatusCalculado",
        each
            if [Validade] = null then null
            else if [Validade] < [DataReferencia] then "Vencido"
            else if Duration.Days([Validade] - [DataReferencia]) <= 30 then "Expirando"
            else "Válido",
        type text
    ),

    Remove_StatusOriginal = Table.RemoveColumns(Add_StatusCalculado, {"Status"}, MissingField.Ignore),
    Rename_StatusCalculado = Table.RenameColumns(Remove_StatusOriginal, {{"StatusCalculado", "Status"}}),

    Add_PrioridadeStatus = Table.AddColumn(
        Rename_StatusCalculado,
        "Prioridade",
        each if [Status] = "Válido" then 1 else if [Status] = "Expirando" then 2 else if [Status] = "Vencido" then 3 else 4,
        Int64.Type
    ),

    Sort_RegistrosPriorizados = Table.Sort(
        Add_PrioridadeStatus,
        {{"Placa", Order.Ascending}, {"Tipo de Documento", Order.Ascending}, {"Prioridade", Order.Ascending}, {"Validade", Order.Descending}}
    ),

    Buffer_RegistrosPriorizados = Table.Buffer(Sort_RegistrosPriorizados),
    Distinct_PlacaDocumento = Table.Distinct(Buffer_RegistrosPriorizados, {"Placa", "Tipo de Documento"}),
    Remove_PrioridadeStatus = Table.RemoveColumns(Distinct_PlacaDocumento, {"Prioridade"}, MissingField.Ignore),

    Add_MesAnoFormatado = Table.AddColumn(
        Remove_PrioridadeStatus,
        "Mês-Ano",
        each Create_MesAnoFormatado([Validade]),
        type text
    ),

    Select_ColunasOficiais = Table.SelectColumns(
        Add_MesAnoFormatado,
        {
            "NUCLEO",
            "Filial",
            "Placa",
            "Frota",
            "Tipo de Documento",
            "Validade",
            "Mês-Ano",
            "Status",
            "DataReferencia"
        },
        MissingField.Ignore
    ),

    Transform_TiposResultadoFinal = Table.TransformColumnTypes(
        Select_ColunasOficiais,
        {
            {"NUCLEO", type text}, {"Filial", type text}, {"Placa", type text}, {"Frota", type text},
            {"Tipo de Documento", type text}, {"Validade", type date}, {"Mês-Ano", type text},
            {"Status", type text}, {"DataReferencia", type date}
        },
        "pt-BR"
    ),

    Sort_ResultadoFinal = Table.Sort(
        Transform_TiposResultadoFinal,
        {{"NUCLEO", Order.Ascending}, {"Filial", Order.Ascending}, {"Placa", Order.Ascending}, {"Tipo de Documento", Order.Ascending}}
    )
in
    Sort_ResultadoFinal
