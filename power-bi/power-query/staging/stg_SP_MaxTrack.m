let
    SiteUrl = "https://grupoultracloud.sharepoint.com/teams/Teste728",
    Site = SharePoint.Contents(SiteUrl, [ApiVersion = 15, Implementation = "2.0"]),
    Biblioteca = Site{[Name = "Documentos Compartilhados"]}[Content],
    Pasta = Biblioteca{[Name = "Dados MaxTrack"]}[Content]
in
    Pasta
