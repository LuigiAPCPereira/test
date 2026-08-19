let
    // ============================================================
    // QUALIDADE DOS DADOS
    //
    // Tabela de EXCEÇÕES. Se tudo estiver correto, tende a ficar vazia.
    // Depende das consultas:
    // ConsultarFrotasNordeste, MaxTrack, SuasTrans, ManoTer, Medidor.
    // ============================================================

    PlacasFrota = Table.Distinct(
        Table.SelectRows(
            Table.TransformColumns(
                Table.SelectColumns(ConsultarFrotasNordeste, {"Placa", "Frota", "NUCLEO", "Filial"}, MissingField.UseNull),
                {{"Placa", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type nullable text}}
            ),
            each [Placa] <> null and [Placa] <> ""
        ),
        {"Placa"}
    ),

    PlacasMax = List.Buffer(
        List.Distinct(
            List.RemoveNulls(
                List.Transform(
                    Table.Column(MaxTrack, "PLACA"),
                    each if _ = null then null else Text.Upper(Text.Trim(Text.From(_)))
                )
            )
        )
    ),

    SemMaxTrack0 = Table.SelectRows(PlacasFrota, each not List.Contains(PlacasMax, [Placa])),
    SemMaxTrack1 = Table.AddColumn(SemMaxTrack0, "Gravidade", each "ERRO", type text),
    SemMaxTrack2 = Table.AddColumn(SemMaxTrack1, "Origem", each "MaxTrack", type text),
    SemMaxTrack3 = Table.AddColumn(SemMaxTrack2, "Problema", each "Placa sem KM no MaxTrack", type text),
    SemMaxTrack = Table.AddColumn(SemMaxTrack3, "Detalhe", each "A placa está na frota Nordeste, mas não apareceu na consulta MaxTrack.", type text),

    ManoTerProblemas0 = Table.SelectRows(ManoTer, each [Integridade] <> "OK"),
    ManoTerProblemas1 = Table.SelectColumns(ManoTerProblemas0, {"Placa", "Frota", "NUCLEO", "Filial", "Integridade", "Documentos faltantes", "Documentos duplicados"}, MissingField.UseNull),
    ManoTerProblemas2 = Table.AddColumn(ManoTerProblemas1, "Gravidade", each "ERRO", type text),
    ManoTerProblemas3 = Table.AddColumn(ManoTerProblemas2, "Origem", each "Mano/Ter", type text),
    ManoTerProblemas4 = Table.AddColumn(ManoTerProblemas3, "Problema", each [Integridade], type text),
    ManoTerProblemas = Table.AddColumn(
        ManoTerProblemas4,
        "Detalhe",
        each Text.Combine(
            List.RemoveNulls({
                if [#"Documentos faltantes"] = null then null else "Faltantes: " & [#"Documentos faltantes"],
                if [#"Documentos duplicados"] = null then null else "Duplicados: " & [#"Documentos duplicados"]
            }),
            " | "
        ),
        type text
    ),

    MedidorProblemas0 = Table.SelectRows(Medidor, each [Integridade] <> "OK"),
    MedidorProblemas1 = Table.SelectColumns(MedidorProblemas0, {"Placa", "Frota", "NUCLEO", "Filial", "Integridade", "Qtd registros"}, MissingField.UseNull),
    MedidorProblemas2 = Table.AddColumn(MedidorProblemas1, "Gravidade", each "ERRO", type text),
    MedidorProblemas3 = Table.AddColumn(MedidorProblemas2, "Origem", each "Medidor", type text),
    MedidorProblemas4 = Table.AddColumn(MedidorProblemas3, "Problema", each [Integridade], type text),
    MedidorProblemas = Table.AddColumn(MedidorProblemas4, "Detalhe", each "Quantidade de registros 02.02: " & Text.From([#"Qtd registros"]), type text),

    SemMaxTrackFinal = Table.SelectColumns(SemMaxTrack, {"Gravidade", "Origem", "Placa", "Frota", "NUCLEO", "Filial", "Problema", "Detalhe"}, MissingField.UseNull),
    ManoTerFinal = Table.SelectColumns(ManoTerProblemas, {"Gravidade", "Origem", "Placa", "Frota", "NUCLEO", "Filial", "Problema", "Detalhe"}, MissingField.UseNull),
    MedidorFinal = Table.SelectColumns(MedidorProblemas, {"Gravidade", "Origem", "Placa", "Frota", "NUCLEO", "Filial", "Problema", "Detalhe"}, MissingField.UseNull),

    Combinar = Table.Combine({SemMaxTrackFinal, ManoTerFinal, MedidorFinal}),
    Ordenar = Table.Sort(Combinar, {{"Gravidade", Order.Ascending}, {"Origem", Order.Ascending}, {"NUCLEO", Order.Ascending}, {"Placa", Order.Ascending}})
in
    Ordenar
