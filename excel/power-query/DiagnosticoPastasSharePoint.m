let
    // ============================================================
    // DIAGNÓSTICO TEMPORÁRIO — PASTAS DO SITE DE TESTE
    //
    // Esta consulta acessa APENAS o site Teste728 para evitar o
    // Formula.Firewall ao combinar duas fontes SharePoint distintas.
    // Execute separadamente de DiagnosticoPastaMae.m.
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

    Selecionar = Table.SelectColumns(
        SomenteFontes,
        {"Fonte", "Name", "Folder Path", "Date modified"},
        MissingField.UseNull
    ),

    Ordenar = Table.Sort(
        Selecionar,
        {{"Fonte", Order.Ascending}, {"Date modified", Order.Descending}}
    ),

    UltimoPorFonte = Table.Group(
        Ordenar,
        {"Fonte"},
        {{"Linha", each Table.FirstN(_, 1), type table}}
    ),

    Resultado = Table.ExpandTableColumn(
        UltimoPorFonte,
        "Linha",
        {"Name", "Folder Path", "Date modified"},
        {"Arquivo mais recente", "Folder Path", "Date modified"}
    )
in
    Resultado
