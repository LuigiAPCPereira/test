let
    Create_TextCleaner = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    Create_TextTrim = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    Create_HeaderCleaner = (valor as nullable any) as nullable text =>
        let
            TextoBase = if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),
            TextoSemAcentos =
                if TextoBase = null then null else
                    Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.Replace(TextoBase, "Ô", "O"), "Õ", "O"), "Ó", "O"), "Ò", "O"), "Ö", "O"), "Ê", "E"), "É", "E"), "È", "E"),
            TextoLimpo = if TextoSemAcentos = null then null else Text.Remove(TextoSemAcentos, {" ", "_", "-", ".", "/", "\\", "º", "ª"})
        in
            TextoLimpo,

    Create_OdometroTratado = (valor as nullable any) as nullable number =>
        let
            TextoOriginal = if valor = null then null else Text.Trim(Text.From(valor)),
            ApenasDigitos = if TextoOriginal = null then null else Text.Select(TextoOriginal, {"0".."9"}),
            TextoSemUltimos3Digitos = if ApenasDigitos = null or Text.Length(ApenasDigitos) <= 3 then null else Text.Start(ApenasDigitos, Text.Length(ApenasDigitos) - 3),
            NumeroFinal = try Number.FromText(TextoSemUltimos3Digitos, "pt-BR") otherwise null
        in
            NumeroFinal,

    Connect_PastaMaxTrack = SharePoint.Contents(
        "https://grupoultracloud.sharepoint.com/teams/Teste728/Documentos Compartilhados/Dados MaxTrack/",
        [ApiVersion = 15, Implementation = "2.0"]
    ),

    Select_TabelaMapeamento = ConsultarFrotasNordeste,

    Create_ColunasEsperadasMapeamento = {"Placa", "Frota", "Núcleo", "Filial"},

    Validate_EstruturaMapeamento =
        let
            ColunasFaltando = List.RemoveItems(Create_ColunasEsperadasMapeamento, Table.ColumnNames(Select_TabelaMapeamento))
        in
            if List.Count(ColunasFaltando) > 0 then
                error Error.Record("Erro de Estrutura", "A tabela tb_FrotaNordeste não contém as colunas esperadas.", "Colunas faltando: " & Text.Combine(ColunasFaltando, ", "))
            else
                Select_TabelaMapeamento,

    Transform_TiposMapeamento = Table.TransformColumnTypes(
        Validate_EstruturaMapeamento,
        {{"Placa", type text}, {"Frota", type text}, {"Núcleo", type text}, {"Filial", type text}},
        "pt-BR"
    ),

    Transform_NormalizarMapeamento = Table.TransformColumns(
        Transform_TiposMapeamento,
        {
            {"Placa", each Create_TextCleaner(_), type text},
            {"Frota", each Create_TextTrim(_), type text},
            {"Núcleo", each Create_TextTrim(_), type text},
            {"Filial", each Create_TextTrim(_), type text}
        }
    ),

    Filter_MapeamentoPlacasValidas = Table.SelectRows(Transform_NormalizarMapeamento, each [Placa] <> null and [Placa] <> ""),
    Sort_MapeamentoPorPlaca = Table.Sort(Filter_MapeamentoPlacasValidas, {{"Placa", Order.Ascending}}),
    Buffer_MapeamentoOrdenado = Table.Buffer(Sort_MapeamentoPorPlaca),
    Distinct_MapeamentoPorPlaca = Table.Distinct(Buffer_MapeamentoOrdenado, {"Placa"}),
    Buffer_MapeamentoPorPlaca = Table.Buffer(Distinct_MapeamentoPorPlaca),

    Create_ListaPlacasValidas = List.Distinct(List.RemoveNulls(Table.Column(Buffer_MapeamentoPorPlaca, "Placa"))),
    Create_RecordPlacasValidas = Record.FromList(List.Repeat({true}, List.Count(Create_ListaPlacasValidas)), Create_ListaPlacasValidas),

    Filter_ArquivosMaxTrack = Table.SelectRows(
        Connect_PastaMaxTrack,
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

    Validate_ArquivosMaxTrack =
        if Table.RowCount(Filter_ArquivosMaxTrack) = 0 then
            error Error.Record("Erro de Validação", "Nenhum arquivo Excel (.xlsx) encontrado na pasta MaxTrack.", "Verifique o caminho direto e os arquivos da pasta.")
        else
            Filter_ArquivosMaxTrack,

    Sort_ArquivosPorModificacao = Table.Sort(Validate_ArquivosMaxTrack, {{"Date modified", Order.Descending}}),
    Get_ContentArquivoMaisRecente = Sort_ArquivosPorModificacao{0}[Content],
    Import_WorkbookMaxTrack = Excel.Workbook(Get_ContentArquivoMaisRecente, null, true),
    Select_PrimeiraPlanilha = Import_WorkbookMaxTrack{0}[Data],

    Skip_LinhasIniciais = Table.Skip(Select_PrimeiraPlanilha, 3),
    Promote_Cabecalhos = Table.PromoteHeaders(Skip_LinhasIniciais, [PromoteAllScalars = true]),
    Get_NomesColunasBase = Table.ColumnNames(Promote_Cabecalhos),

    Get_ColunaPlaca = List.First(List.Select(Get_NomesColunasBase, each Create_HeaderCleaner(_) = "PLACA"), null),
    Get_ColunaOdometro = List.First(List.Select(Get_NomesColunasBase, each Create_HeaderCleaner(_) = "ODOMETRO"), null),

    Validate_ColunasBase =
        if Get_ColunaPlaca = null or Get_ColunaOdometro = null then
            error Error.Record("Erro de Estrutura", "A planilha MaxTrack não contém as colunas esperadas.", "Colunas necessárias: Placa e Odometro/Odomêtro/Odômetro.")
        else
            Promote_Cabecalhos,

    Create_ParesRenomeacao = List.RemoveNulls({
        if Get_ColunaPlaca <> "PLACA" then {Get_ColunaPlaca, "PLACA"} else null,
        if Get_ColunaOdometro <> "ODOMETRO_BRUTO" then {Get_ColunaOdometro, "ODOMETRO_BRUTO"} else null
    }),

    Rename_ColunasPadrao = Table.RenameColumns(Validate_ColunasBase, Create_ParesRenomeacao, MissingField.Ignore),

    Transform_TiposBase = Table.TransformColumnTypes(
        Rename_ColunasPadrao,
        {{"PLACA", type text}, {"ODOMETRO_BRUTO", type text}},
        "pt-BR"
    ),

    Transform_NormalizarBase = Table.TransformColumns(
        Transform_TiposBase,
        {{"PLACA", each Create_TextCleaner(_), type text}, {"ODOMETRO_BRUTO", each Create_TextTrim(_), type text}}
    ),

    Add_OdometroTratado = Table.AddColumn(Transform_NormalizarBase, "ODOMETRO", each Create_OdometroTratado([ODOMETRO_BRUTO]), Int64.Type),

    Filter_RegistrosValidos = Table.SelectRows(
        Add_OdometroTratado,
        each [PLACA] <> null and [PLACA] <> "" and [ODOMETRO] <> null and Record.HasFields(Create_RecordPlacasValidas, [PLACA])
    ),

    Add_OdometroVisual = Table.AddColumn(Filter_RegistrosValidos, "ODOMETRO VISUAL", each Number.ToText([ODOMETRO], "#,##0", "pt-BR") & " KM", type text),

    Select_ColunasOficiais = Table.SelectColumns(Add_OdometroVisual, {"PLACA", "ODOMETRO", "ODOMETRO VISUAL"}, MissingField.Ignore),

    Transform_TiposResultadoFinal = Table.TransformColumnTypes(
        Select_ColunasOficiais,
        {{"PLACA", type text}, {"ODOMETRO", Int64.Type}, {"ODOMETRO VISUAL", type text}},
        "pt-BR"
    ),

    Sort_ResultadoFinal = Table.Sort(Transform_TiposResultadoFinal, {{"PLACA", Order.Ascending}})
in
    Sort_ResultadoFinal
