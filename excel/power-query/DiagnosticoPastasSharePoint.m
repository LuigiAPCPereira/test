let
    // ============================================================
    // DIAGNÓSTICO TEMPORÁRIO — CAMINHOS EXATOS DO SHAREPOINT
    //
    // Use esta consulta somente para descobrir os Folder Path reais.
    // Depois que os caminhos forem validados, ela pode ser removida.
    // O objetivo é permitir a migração de SharePoint.Files (enumeração
    // ampla do site) para SharePoint.Contents com navegação direta.
    // ============================================================

    SiteTeste = SharePoint.Files(
        "https://grupoultracloud.sharepoint.com/teams/Teste728",
        [ApiVersion = 15]
    ),

    ExcelTeste = Table.SelectRows(
        SiteTeste,
        each Text.Lower(Record.FieldOrDefault(_, "Extension", "")) = ".xlsx"
            and not Text.StartsWith(Record.FieldOrDefault(_, "Name", ""), "~$")
    ),

    AddCategoria = Table.AddColumn(
        ExcelTeste,
        "Fonte",
        each
            if Text.Contains([Folder Path], "Dados Suastrans", Comparer.OrdinalIgnoreCase) then "SuasTrans"
            else if Text.Contains([Folder Path], "Dados MaxTrack", Comparer.OrdinalIgnoreCase) then "MaxTrack"
            else if Text.Contains([Folder Path], "Dados Tableau", Comparer.OrdinalIgnoreCase) then "Tableau"
            else null,
        type nullable text
    ),

    SomenteFontes = Table.SelectRows(AddCategoria, each [Fonte] <> null),

    SelecionarTeste = Table.SelectColumns(
        SomenteFontes,
        {"Fonte", "Name", "Folder Path", "Date modified"},
        MissingField.UseNull
    ),

    OrdenarTeste = Table.Sort(
        SelecionarTeste,
        {{"Fonte", Order.Ascending}, {"Date modified", Order.Descending}}
    ),

    UltimoPorFonte = Table.Group(
        OrdenarTeste,
        {"Fonte"},
        {{"Linha", each Table.FirstN(_, 1), type table}}
    ),

    ExpandirTeste = Table.ExpandTableColumn(
        UltimoPorFonte,
        "Linha",
        {"Name", "Folder Path", "Date modified"},
        {"Arquivo mais recente", "Folder Path", "Date modified"}
    ),

    SiteMae = SharePoint.Files(
        "https://grupoultracloud.sharepoint.com/teams/UG-ExcelnciaemFrotas",
        [ApiVersion = 15]
    ),

    MaeFiltrada = Table.SelectRows(
        SiteMae,
        each [Name] = "Programações Paradas Frotas.xlsm"
            and Text.Contains([Folder Path], "Manutenção e Disponibilidade", Comparer.OrdinalIgnoreCase)
    ),

    MaeSelecionada0 = Table.SelectColumns(
        MaeFiltrada,
        {"Name", "Folder Path", "Date modified"},
        MissingField.UseNull
    ),

    MaeSelecionada1 = Table.AddColumn(MaeSelecionada0, "Fonte", each "Planilha mãe", type text),
    MaeSelecionada2 = Table.RenameColumns(MaeSelecionada1, {{"Name", "Arquivo mais recente"}}),
    MaeSelecionada = Table.SelectColumns(
        MaeSelecionada2,
        {"Fonte", "Arquivo mais recente", "Folder Path", "Date modified"},
        MissingField.UseNull
    ),

    Resultado = Table.Combine({ExpandirTeste, MaeSelecionada}),
    Ordenar = Table.Sort(Resultado, {{"Fonte", Order.Ascending}})
in
    Ordenar
