let
    // ============================================================
    // MAXTRACK — FONTE SHAREPOINT.CONTENTS
    // Saída: NUCLEO -> Filial -> PLACA -> demais campos originais.
    // ============================================================

    TextoUpper = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Upper(Text.Trim(Text.From(valor))),

    Texto = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

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
            T2 = if T1 = null then null else Text.Remove(T1, {" ", "_", "-", ".", "/", "\\", "º", "ª"})
        in
            T2,

    OdometroKm = (valor as nullable any) as nullable number =>
        let
            T = if valor = null then null else Text.Trim(Text.From(valor)),
            Digitos = if T = null then null else Text.Select(T, {"0".."9"}),
            SemMilimetros = if Digitos = null or Text.Length(Digitos) <= 3 then null else Text.Start(Digitos, Text.Length(Digitos) - 3),
            N = try Number.FromText(SemMilimetros, "pt-BR") otherwise null
        in
            N,

    // Fonte já navegada diretamente até Dados MaxTrack.
    Fonte = FonteMaxTrack_Contents,

    // Frota oficial para filtrar e enriquecer Núcleo/Filial.
    Mapeamento0 = Table.SelectColumns(
        ConsultarFrotasNordeste,
        {"Placa", "Núcleo", "Filial"},
        MissingField.UseNull
    ),
    Mapeamento1 = Table.TransformColumns(
        Mapeamento0,
        {
            {"Placa", each TextoUpper(_), type nullable text},
            {"Núcleo", each Texto(_), type nullable text},
            {"Filial", each Texto(_), type nullable text}
        }
    ),
    Mapeamento2 = Table.SelectRows(Mapeamento1, each [Placa] <> null and [Placa] <> ""),
    Mapeamento = Table.Buffer(Table.Distinct(Table.Sort(Mapeamento2, {{"Placa", Order.Ascending}}), {"Placa"})),

    Placas = List.Distinct(List.RemoveNulls(Table.Column(Mapeamento, "Placa"))),
    RecordPlacas = Record.FromList(List.Repeat({true}, List.Count(Placas)), Placas),
    RecordNucleo = Record.FromList(Table.Column(Mapeamento, "Núcleo"), Table.Column(Mapeamento, "Placa")),
    RecordFilial = Record.FromList(Table.Column(Mapeamento, "Filial"), Table.Column(Mapeamento, "Placa")),

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
                "Nenhum arquivo Excel (.xlsx) encontrado em Dados MaxTrack.",
                "Verifique FonteMaxTrack_Contents e os arquivos da pasta."
            )
        else
            Arquivos,

    ArquivoMaisRecente = Table.Sort(ValidarArquivos, {{"Date modified", Order.Descending}}){0}[Content],
    Workbook = Excel.Workbook(ArquivoMaisRecente, null, true),
    PrimeiraPlanilha = Workbook{0}[Data],

    RemoverLinhasIniciais = Table.Skip(PrimeiraPlanilha, 3),
    Cabecalhos = Table.PromoteHeaders(RemoverLinhasIniciais, [PromoteAllScalars = true]),
    NomesColunas = Table.ColumnNames(Cabecalhos),

    ColPlaca = List.First(List.Select(NomesColunas, each LimparCabecalho(_) = "PLACA"), null),
    ColOdometro = List.First(List.Select(NomesColunas, each LimparCabecalho(_) = "ODOMETRO"), null),

    ValidarEstrutura =
        if ColPlaca = null or ColOdometro = null then
            error Error.Record(
                "Erro de Estrutura",
                "A planilha MaxTrack não contém Placa e Odômetro.",
                "Cabeçalhos encontrados: " & Text.Combine(NomesColunas, ", ")
            )
        else
            Cabecalhos,

    ParesRenomeacao = List.RemoveNulls({
        if ColPlaca <> "PLACA" then {ColPlaca, "PLACA"} else null,
        if ColOdometro <> "ODOMETRO_BRUTO" then {ColOdometro, "ODOMETRO_BRUTO"} else null
    }),

    Renomear = Table.RenameColumns(ValidarEstrutura, ParesRenomeacao, MissingField.Ignore),
    Tipar = Table.TransformColumnTypes(Renomear, {{"PLACA", type text}, {"ODOMETRO_BRUTO", type text}}, "pt-BR"),
    Normalizar = Table.TransformColumns(
        Tipar,
        {
            {"PLACA", each TextoUpper(_), type nullable text},
            {"ODOMETRO_BRUTO", each Texto(_), type nullable text}
        }
    ),

    AddOdometro = Table.AddColumn(Normalizar, "ODOMETRO", each OdometroKm([ODOMETRO_BRUTO]), Int64.Type),

    FiltrarFrota = Table.SelectRows(
        AddOdometro,
        each [PLACA] <> null
            and [PLACA] <> ""
            and [ODOMETRO] <> null
            and Record.HasFields(RecordPlacas, [PLACA])
    ),

    AddNucleo = Table.AddColumn(FiltrarFrota, "NUCLEO", each Record.FieldOrDefault(RecordNucleo, [PLACA], null), type nullable text),
    AddFilial = Table.AddColumn(AddNucleo, "Filial", each Record.FieldOrDefault(RecordFilial, [PLACA], null), type nullable text),
    AddVisual = Table.AddColumn(AddFilial, "ODOMETRO VISUAL", each Number.ToText([ODOMETRO], "#,##0", "pt-BR") & " KM", type text),

    Selecionar = Table.SelectColumns(
        AddVisual,
        {"NUCLEO", "Filial", "PLACA", "ODOMETRO", "ODOMETRO VISUAL"},
        MissingField.UseNull
    ),

    Resultado = Table.Sort(
        Selecionar,
        {{"NUCLEO", Order.Ascending}, {"Filial", Order.Ascending}, {"PLACA", Order.Ascending}}
    )
in
    Resultado
