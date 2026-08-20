let
    SiteUrl = "https://grupoultracloud.sharepoint.com/teams/Teste728",
    FolderPath = "https://grupoultracloud.sharepoint.com/teams/Teste728/Documentos Compartilhados/Dados Tableau/",

    Site = SharePoint.Contents(
        SiteUrl,
        [ApiVersion = 15, Implementation = "2.0"]
    ),

    Biblioteca =
        try Site{[Name = "Documentos Compartilhados"]}[Content]
        otherwise error Error.Record(
            "Biblioteca não encontrada",
            "Não foi possível navegar até Documentos Compartilhados no site Teste728.",
            [Site = SiteUrl]
        ),

    Pasta =
        try Biblioteca{[Name = "Dados Tableau"]}[Content]
        otherwise error Error.Record(
            "Pasta não encontrada",
            "Não foi possível navegar até Dados Tableau.",
            [Site = SiteUrl]
        ),

    ComFolderPath =
        if List.Contains(Table.ColumnNames(Pasta), "Folder Path") then
            Pasta
        else
            Table.AddColumn(Pasta, "Folder Path", each FolderPath, type text),

    ComExtension =
        if List.Contains(Table.ColumnNames(ComFolderPath), "Extension") then
            ComFolderPath
        else
            Table.AddColumn(
                ComFolderPath,
                "Extension",
                each
                    let
                        Nome = Text.From(Record.FieldOrDefault(_, "Name", "")),
                        Partes = Text.Split(Nome, ".")
                    in
                        if List.Count(Partes) > 1 then "." & Text.Lower(List.Last(Partes)) else "",
                type text
            )
in
    ComExtension
