(UrlPasta as text, optional Extensao as nullable text, optional NomeIgnorar as nullable text) as record =>
let
    // ============================================================
    // FUNÇÃO — ARQUIVO MAIS RECENTE EM UMA PASTA SHAREPOINT
    //
    // Usa SharePoint.Contents diretamente na URL da pasta validada.
    // Não usar com a URL ampla do site: a intenção é navegar direto à
    // pasta que contém a fonte operacional.
    //
    // Retorna um record com Nome, Conteudo, Modificado e UrlPasta.
    // ============================================================

    Ext = if Extensao = null then ".xlsx" else Text.Lower(Text.Trim(Extensao)),

    Fonte = SharePoint.Contents(
        UrlPasta,
        [ApiVersion = 15, Implementation = "2.0"]
    ),

    Arquivos = Table.SelectRows(
        Fonte,
        each
            let
                Nome = Text.From(Record.FieldOrDefault(_, "Name", "")),
                ExtLinha = Text.Lower(Text.From(Record.FieldOrDefault(_, "Extension", ""))),
                Conteudo = Record.FieldOrDefault(_, "Content", null),
                EhBinario = Conteudo <> null and Value.Is(Conteudo, type binary),
                NomePermitido = NomeIgnorar = null or Nome <> NomeIgnorar
            in
                EhBinario
                    and ExtLinha = Ext
                    and not Text.StartsWith(Nome, "~$")
                    and NomePermitido
    ),

    Validar =
        if Table.RowCount(Arquivos) = 0 then
            error Error.Record(
                "Arquivo não encontrado",
                "Nenhum arquivo compatível foi encontrado na pasta SharePoint informada.",
                [UrlPasta = UrlPasta, Extensao = Ext]
            )
        else
            Arquivos,

    Ordenar = Table.Sort(Validar, {{"Date modified", Order.Descending}}),
    Linha = Ordenar{0},

    Resultado = [
        Nome = Text.From(Record.FieldOrDefault(Linha, "Name", null)),
        Conteudo = Record.FieldOrDefault(Linha, "Content", null),
        Modificado = Record.FieldOrDefault(Linha, "Date modified", null),
        UrlPasta = UrlPasta
    ]
in
    Resultado
