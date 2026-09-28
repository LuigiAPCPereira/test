let
    SiteUrl = "https://grupoultracloud.sharepoint.com/teams/Teste728",
    Site = SharePoint.Contents(SiteUrl, [ApiVersion = 15, Implementation = "2.0"]),
    Biblioteca = Site{[Name = "Documentos Compartilhados"]}[Content],
    // Nome físico real da pasta no SharePoint. A nomenclatura do modelo é SuaTrans.
    Pasta = Biblioteca{[Name = "Dados Suastrans"]}[Content]
in
    Pasta
