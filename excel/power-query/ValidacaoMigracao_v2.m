let
    // Execução manual após as consultas novas existirem.
    // Deixe sem refresh automático para não adicionar custo ao uso diário.

    Texto = (v as any) as text => if v = null then "null" else Text.From(v),
    QtdUnicos = (t as table, coluna as text) as number =>
        List.Count(List.Distinct(List.RemoveNulls(Table.Column(t, coluna)))),
    QtdVazios = (t as table, coluna as text) as number =>
        Table.RowCount(
            Table.SelectRows(
                t,
                each
                    let v = Record.FieldOrDefault(_, coluna, null)
                    in v = null or Text.Trim(Text.From(v)) = ""
            )
        ),
    Check = (area as text, item as text, esperado as text, encontrado as any, ok as logical) as record =>
        [
            Área = area,
            Verificação = item,
            Esperado = esperado,
            Encontrado = Texto(encontrado),
            Status = if ok then "OK" else "REVISAR"
        ],

    QtdFrota = Table.RowCount(ConsultarFrotasNordeste),
    PlacasFrota = QtdUnicos(ConsultarFrotasNordeste, "Placa"),

    QtdSuas = Table.RowCount(SuasTrans),
    PlacasSuas = QtdUnicos(SuasTrans, "Placa"),
    TiposSuas = QtdUnicos(SuasTrans, "Tipo de Documento"),

    QtdMax = Table.RowCount(MaxTrack),
    PlacasMax = QtdUnicos(MaxTrack, "PLACA"),

    QtdMedidor = Table.RowCount(Medidor),
    QtdManoTer = Table.RowCount(ManoTer),
    QtdAtualizacaoMae = Table.RowCount(AtualizacaoMae),

    QtdTableu = Table.RowCount(Tableu),
    QtdOSOperacional = Table.RowCount(OSOperacional),
    StatusTableu = List.Sort(
        List.Distinct(
            List.RemoveNulls(
                List.Transform(Table.Column(Tableu, "STATUS"), each Text.Upper(Text.Trim(Text.From(_))))
            )
        )
    ),
    StatusForaFluxo = List.Difference(StatusTableu, {"APROG", "COMP", "FECHAR"}),

    Checks = {
        Check("Frota", "Linhas = placas únicas", "iguais", Texto(QtdFrota) & " / " & Texto(PlacasFrota), QtdFrota = PlacasFrota),
        Check("Frota", "Placa vazia", "0", QtdVazios(ConsultarFrotasNordeste, "Placa"), QtdVazios(ConsultarFrotasNordeste, "Placa") = 0),

        Check("SuasTrans", "Placas cobertas", Texto(QtdFrota), PlacasSuas, PlacasSuas = QtdFrota),
        Check("SuasTrans", "Tipos documentais", "9", TiposSuas, TiposSuas = 9),
        Check("SuasTrans", "Linhas esperadas", Texto(QtdFrota * 9), QtdSuas, QtdSuas = QtdFrota * 9),
        Check("SuasTrans", "NUCLEO vazio", "0", QtdVazios(SuasTrans, "NUCLEO"), QtdVazios(SuasTrans, "NUCLEO") = 0),

        Check("MaxTrack", "Placas cobertas", Texto(QtdFrota), PlacasMax, PlacasMax = QtdFrota),
        Check("MaxTrack", "Uma linha por placa", Texto(PlacasMax), QtdMax, QtdMax = PlacasMax),
        Check("MaxTrack", "ODOMETRO vazio", "0", QtdVazios(MaxTrack, "ODOMETRO"), QtdVazios(MaxTrack, "ODOMETRO") = 0),

        Check("Medidor", "Uma linha por placa", Texto(QtdFrota), QtdMedidor, QtdMedidor = QtdFrota),
        Check("Medidor", "NUCLEO vazio", "0", QtdVazios(Medidor, "NUCLEO"), QtdVazios(Medidor, "NUCLEO") = 0),
        Check("Medidor", "Integridade diferente de OK", "0", Table.RowCount(Table.SelectRows(Medidor, each [Integridade] <> "OK")), Table.RowCount(Table.SelectRows(Medidor, each [Integridade] <> "OK")) = 0),

        Check("Mano/Ter", "Uma linha por placa", Texto(QtdFrota), QtdManoTer, QtdManoTer = QtdFrota),
        Check("Mano/Ter", "NUCLEO vazio", "0", QtdVazios(ManoTer, "NUCLEO"), QtdVazios(ManoTer, "NUCLEO") = 0),
        Check("Mano/Ter", "Integridade diferente de OK", "0", Table.RowCount(Table.SelectRows(ManoTer, each [Integridade] <> "OK")), Table.RowCount(Table.SelectRows(ManoTer, each [Integridade] <> "OK")) = 0),

        Check("Atualização Mãe", "Uma linha por placa", Texto(QtdFrota), QtdAtualizacaoMae, QtdAtualizacaoMae = QtdFrota),
        Check("Atualização Mãe", "NUCLEO vazio", "0", QtdVazios(AtualizacaoMae, "NUCLEO"), QtdVazios(AtualizacaoMae, "NUCLEO") = 0),
        Check("Atualização Mãe", "Integridade diferente de OK", "0", Table.RowCount(Table.SelectRows(AtualizacaoMae, each [Integridade] <> "OK")), Table.RowCount(Table.SelectRows(AtualizacaoMae, each [Integridade] <> "OK")) = 0),

        Check("Tableau", "Status fora do fluxo", "nenhum", if List.Count(StatusForaFluxo) = 0 then "nenhum" else Text.Combine(StatusForaFluxo, ", "), List.Count(StatusForaFluxo) = 0),
        Check("OS Operacional", "Quantidade = Tableu", Texto(QtdTableu), QtdOSOperacional, QtdOSOperacional = QtdTableu),
        Check("OS Operacional", "NUCLEO vazio", "0", QtdVazios(OSOperacional, "NUCLEO"), QtdVazios(OSOperacional, "NUCLEO") = 0)
    },

    Resultado0 = Table.FromRecords(Checks),
    Ordem = Table.AddColumn(Resultado0, "_ordem", each if [Status] = "REVISAR" then 1 else 2, Int64.Type),
    Ordenado = Table.Sort(Ordem, {{"_ordem", Order.Ascending}, {"Área", Order.Ascending}, {"Verificação", Order.Ascending}}),
    Resultado = Table.RemoveColumns(Ordenado, {"_ordem"})
in
    Resultado
