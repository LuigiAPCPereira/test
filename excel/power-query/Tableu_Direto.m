let
    Create_TextCleaner = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    Create_TextTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    Create_DataReferenciaAtual = Date.From(DateTime.FixedLocalNow()),
    Set_DiasOsAntiga = 30,

    Connect_PastaTableau = SharePoint.Contents(
        "https://grupoultracloud.sharepoint.com/teams/Teste728/Documentos Compartilhados/Dados Tableau/",
        [ApiVersion = 15, Implementation = "2.0"]
    ),

    Select_TabelaMapeamento = ConsultarFrotasNordeste,

    Validate_EstruturaMapeamento =
        let
            ColunasEsperadas = {"Frota", "Placa", "Núcleo"},
            ColunasFaltando = List.RemoveItems(ColunasEsperadas, Table.ColumnNames(Select_TabelaMapeamento))
        in
            if List.Count(ColunasFaltando) > 0 then
                error Error.Record("Erro de Estrutura", "A tabela tb_FrotaNordeste não contém as colunas esperadas.", "Colunas faltando: " & Text.Combine(ColunasFaltando, ", "))
            else
                Select_TabelaMapeamento,

    Transform_TiposMapeamento = Table.TransformColumnTypes(
        Validate_EstruturaMapeamento,
        {{"Frota", type text}, {"Placa", type text}, {"Núcleo", type text}},
        "pt-BR"
    ),

    Transform_NormalizarMapeamento = Table.TransformColumns(
        Transform_TiposMapeamento,
        {
            {"Frota", each Create_TextTrim(_), type text},
            {"Placa", each Create_TextCleaner(_), type text},
            {"Núcleo", each Create_TextTrim(_), type text}
        }
    ),

    Filter_MapeamentoFrotasValidas = Table.SelectRows(
        Transform_NormalizarMapeamento,
        each [Frota] <> null and [Frota] <> "" and [Placa] <> null and [Placa] <> "" and [Núcleo] <> null and [Núcleo] <> ""
    ),

    Sort_MapeamentoPorFrota = Table.Sort(Filter_MapeamentoFrotasValidas, {{"Frota", Order.Ascending}}),
    Buffer_MapeamentoOrdenado = Table.Buffer(Sort_MapeamentoPorFrota),
    Distinct_MapeamentoPorFrota = Table.Distinct(Buffer_MapeamentoOrdenado, {"Frota"}),

    Filter_ArquivosTableau = Table.SelectRows(
        Connect_PastaTableau,
        each
            let
                Nome = Text.From(Record.FieldOrDefault(_, "Name", "")),
                Conteudo = Record.FieldOrDefault(_, "Content", null)
            in
                Text.EndsWith(Text.Lower(Nome), ".xlsx")
                    and not Text.StartsWith(Nome, "~$")
                    and Nome <> "Frotas Nordeste.xlsx"
                    and Value.Is(Conteudo, type binary)
    ),

    Validate_ArquivosTableau =
        if Table.RowCount(Filter_ArquivosTableau) = 0 then
            error Error.Record("Erro de Validação", "Nenhum arquivo Excel (.xlsx) encontrado na pasta Dados Tableau.", "Verifique o caminho direto e se há arquivos .xlsx válidos.")
        else
            Filter_ArquivosTableau,

    Sort_ArquivosPorModificacao = Table.Sort(Validate_ArquivosTableau, {{"Date modified", Order.Descending}}),
    Get_ContentArquivoMaisRecente = Sort_ArquivosPorModificacao{0}[Content],
    Import_WorkbookTableau = Excel.Workbook(Get_ContentArquivoMaisRecente, null, true),
    Select_PrimeiraPlanilha = Import_WorkbookTableau{0}[Data],
    Promote_Cabecalhos = Table.PromoteHeaders(Select_PrimeiraPlanilha, [PromoteAllScalars = true]),

    Validate_EstruturaBase =
        let
            ColunasEsperadas = {
                "OS", "FROTA", "FILIAL", "TIPO_SERVICO_OS", "DESCRICAO_DO_PROBLEMA",
                "RECORRENCIA", "STATUS", "TIPO_SERVICO_DESCR", "DATA_DA_SOLICITACAO",
                "ALTERADO_DATA", "PREENCHIDO_POR"
            },
            ColunasFaltando = List.RemoveItems(ColunasEsperadas, Table.ColumnNames(Promote_Cabecalhos))
        in
            if List.Count(ColunasFaltando) > 0 then
                error Error.Record("Erro de Estrutura", "A planilha Tableau não contém as colunas esperadas.", "Colunas faltando: " & Text.Combine(ColunasFaltando, ", "))
            else
                Promote_Cabecalhos,

    Filter_Filial34 = Table.SelectRows(Validate_EstruturaBase, each Text.From([FILIAL]) = "34"),
    Filter_TipoServicoGP = Table.SelectRows(Filter_Filial34, each Text.From([TIPO_SERVICO_OS]) = "GP"),

    Remove_ColunasDesnecessarias = Table.RemoveColumns(
        Filter_TipoServicoGP,
        {
            "DESCRIÇÃO_FALHA", "COD_FALHA", "TIPO_SERVICO_OS", "FILIAL",
            "DESC_CLASSE_FALHA", "CLASSE_FALHA", "TAG", "DATA_PREVISTA_INICIO",
            "DATA_PREVISTA_SAIDA", "DATA_EFETIVA_INICIO", "DATA_EFETIVA_SAIDA"
        },
        MissingField.Ignore
    ),

    Rename_ColunasBase = Table.RenameColumns(
        Remove_ColunasDesnecessarias,
        {{"DESCRICAO_DO_PROBLEMA", "Descrição"}, {"TIPO_SERVICO_DESCR", "TIPO_DE_SERVICO"}},
        MissingField.Ignore
    ),

    Transform_TiposBase = Table.TransformColumnTypes(
        Rename_ColunasBase,
        {
            {"OS", type text}, {"FROTA", type text}, {"Descrição", type text},
            {"RECORRENCIA", type text}, {"STATUS", type text}, {"TIPO_DE_SERVICO", type text},
            {"DATA_DA_SOLICITACAO", type datetime}, {"ALTERADO_DATA", type datetime}, {"PREENCHIDO_POR", type text}
        },
        "pt-BR"
    ),

    Transform_NormalizarBase = Table.TransformColumns(
        Transform_TiposBase,
        {
            {"OS", each Create_TextTrim(_), type text},
            {"FROTA", each Create_TextTrim(_), type text},
            {"Descrição", each Create_TextTrim(_), type text},
            {"RECORRENCIA", each Create_TextTrim(_), type text},
            {"STATUS", each Create_TextTrim(_), type text},
            {"TIPO_DE_SERVICO", each Create_TextTrim(_), type text},
            {"PREENCHIDO_POR", each Create_TextTrim(_), type text}
        }
    ),

    Add_DiasEmAberto = Table.AddColumn(
        Transform_NormalizarBase,
        "DIAS_EM_ABERTO",
        each if [DATA_DA_SOLICITACAO] = null then null else Duration.Days(Create_DataReferenciaAtual - Date.From([DATA_DA_SOLICITACAO])),
        Int64.Type
    ),

    Add_StatusOS = Table.AddColumn(
        Add_DiasEmAberto,
        "STATUS_OS",
        each if [DATA_DA_SOLICITACAO] = null then "Sem Data" else if [DIAS_EM_ABERTO] > Set_DiasOsAntiga then "OS Antiga" else "OS Aberta",
        type text
    ),

    Merge_Mapeamento = Table.NestedJoin(
        Add_StatusOS,
        {"FROTA"},
        Distinct_MapeamentoPorFrota,
        {"Frota"},
        "Mapa",
        JoinKind.Inner
    ),

    Expand_Mapeamento = Table.ExpandTableColumn(Merge_Mapeamento, "Mapa", {"Placa", "Núcleo"}, {"PLACA", "NUCLEO"}),

    Filter_RegistrosComPlacaENucleo = Table.SelectRows(
        Expand_Mapeamento,
        each [PLACA] <> null and [PLACA] <> "" and [NUCLEO] <> null and [NUCLEO] <> ""
    ),

    Remove_Frota = Table.RemoveColumns(Filter_RegistrosComPlacaENucleo, {"FROTA"}, MissingField.Ignore),

    Select_ColunasFinais = Table.SelectColumns(
        Remove_Frota,
        {
            "OS", "Descrição", "NUCLEO", "PLACA", "RECORRENCIA", "STATUS", "STATUS_OS",
            "DIAS_EM_ABERTO", "TIPO_DE_SERVICO", "DATA_DA_SOLICITACAO", "ALTERADO_DATA", "PREENCHIDO_POR"
        },
        MissingField.Ignore
    ),

    Transform_TiposResultadoFinal = Table.TransformColumnTypes(
        Select_ColunasFinais,
        {
            {"OS", type text}, {"Descrição", type text}, {"NUCLEO", type text}, {"PLACA", type text},
            {"RECORRENCIA", type text}, {"STATUS", type text}, {"STATUS_OS", type text},
            {"DIAS_EM_ABERTO", Int64.Type}, {"TIPO_DE_SERVICO", type text},
            {"DATA_DA_SOLICITACAO", type datetime}, {"ALTERADO_DATA", type datetime}, {"PREENCHIDO_POR", type text}
        },
        "pt-BR"
    ),

    Sort_ResultadoFinal = Table.Sort(
        Transform_TiposResultadoFinal,
        {
            {"STATUS_OS", Order.Descending}, {"DIAS_EM_ABERTO", Order.Descending},
            {"NUCLEO", Order.Ascending}, {"PLACA", Order.Ascending}, {"DATA_DA_SOLICITACAO", Order.Ascending}
        }
    )
in
    Sort_ResultadoFinal
