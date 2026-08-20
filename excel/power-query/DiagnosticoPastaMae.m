let
    // ============================================================
    // DIAGNÓSTICO TEMPORÁRIO — PASTA DA PLANILHA MÃE
    //
    // Consulta separada para não combinar, na mesma avaliação, o site
    // UG-ExcelnciaemFrotas com o site Teste728. Isso evita bloqueio do
    // Formula.Firewall por níveis de privacidade diferentes.
    // ============================================================

    SiteMae = SharePoint.Files(
        "https://grupoultracloud.sharepoint.com/teams/UG-ExcelnciaemFrotas",
        [ApiVersion = 15]
    ),

    MaeFiltrada = Table.SelectRows(
        SiteMae,
        each [Name] = "Programações Paradas Frotas.xlsm"
            and Text.Contains([Folder Path], "Manutenção e Disponibilidade", Comparer.OrdinalIgnoreCase)
    ),

    Selecionar = Table.SelectColumns(
        MaeFiltrada,
        {"Name", "Folder Path", "Date modified"},
        MissingField.UseNull
    ),

    Renomear = Table.RenameColumns(
        Selecionar,
        {{"Name", "Arquivo"}}
    ),

    AddFonte = Table.AddColumn(
        Renomear,
        "Fonte",
        each "Planilha mãe",
        type text
    ),

    Resultado = Table.ReorderColumns(
        AddFonte,
        {"Fonte", "Arquivo", "Folder Path", "Date modified"},
        MissingField.Ignore
    )
in
    Resultado
