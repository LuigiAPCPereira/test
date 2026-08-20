let
    // ============================================================
    // VALIDAÇÃO DE MIGRAÇÃO — EXECUÇÃO MANUAL
    //
    // Use somente depois que as consultas novas já existirem.
    // Recomenda-se deixar esta consulta sem refresh automático.
    // ============================================================

    Texto = (valor as nullable any) as text =>
        if valor = null then "null" else Text.From(valor),

    Linha = (
        area as text,
        verificacao as text,
        esperado as text,
        encontrado as any,
        ok as logical,
        optional detalhe as nullable text
    ) as record =>
        [
            Área = area,
            Verificação = verificacao,
            Esperado = esperado,
            Encontrado = Texto(encontrado),
            Status = if ok then "OK" else "REVISAR",
            Detalhe = if detalhe = null then "" else detalhe
        ],

    // ---------- Frota oficial ----------
    QtdFrota = Table.RowCount(ConsultarFrotasNordeste),
    PlacasFrota = List.Distinct(List.RemoveNulls(Table.Column(ConsultarFrotasNordeste, "Placa"))),
    QtdPlacasFrota = List.Count(PlacasFrota),
    NulosPlacaFrota = Table.RowCount(Table.SelectRows(ConsultarFrotasNordeste, each [Placa] = null or Text.Trim(Text.From([Placa])) = "")),

    // ---------- SuasTrans ----------
    QtdSuas = Table.RowCount(SuasTrans),
    QtdPlacasSuas = List.Count(List.Distinct(List.RemoveNulls(Table.Column(SuasTrans, "Placa")))),
    QtdTiposSuas = List.Count(List.Distinct(List.RemoveNulls(Table.Column(SuasTrans, "Tipo de Documento")))),
    NucleoNuloSuas = Table.RowCount(Table.SelectRows(SuasTrans, each [NUCLEO] = null or Text.Trim(Text.From([NUCLEO])) = "")),
    EsperadoSuas = QtdFrota * 9,

    // ---------- MaxTrack ----------
    QtdMax = Table.RowCount(MaxTrack),
    QtdPlacasMax = List.Count(List.Distinct(List.RemoveNulls(Table.Column(MaxTrack, "PLACA")))),
    KmNuloMax = Table.RowCount(Table.SelectRows(MaxTrack, each [ODOMETRO] = null)),

    // ---------- Medidor ----------
    QtdMedidor = Table.RowCount(Medidor),
    NucleoNuloMedidor = Table.RowCount(Table.SelectRows(Medidor, each [NUCLEO] = null or Text.Trim(Text.From([NUCLEO])) = "")),
    ProblemasMedidor = Table.RowCount(Table.SelectRows(Medidor, each [Integridade] <> "OK")),

    // ---------- Mano/Ter ----------
    QtdManoTer = Table.RowCount(ManoTer),
    NucleoNuloManoTer = Table.RowCount(Table.SelectRows(ManoTer, each [NUCLEO] = null or Text.Trim(Text.From([NUCLEO])) = "")),
    ProblemasManoTer = Table.RowCount(Table.SelectRows(ManoTer, each [Integridade] <> "OK")),

    // ---------- Atualização Mãe ----------
    QtdAtualizacaoMae = Table.RowCount(AtualizacaoMae),
    NucleoNuloAtualizacaoMae = Table.RowCount(Table.SelectRows(AtualizacaoMae, each [NUCLEO] = null or Text.Trim(Text.From([NUCLEO])) = "")),
    ProblemasAtualizacaoMae = Table.RowCount(Table.SelectRows(AtualizacaoMae, each [Integridade] <> "OK")),

    // ---------- Tableau / OS ----------
    QtdTableu = Table.RowCount(Tableu),
    StatusTableu = List.Sort(List.Distinct(List.RemoveNulls(List.Transform(Table.Column(Tableu, "STATUS"), each Text.Upper(Text.Trim(Text.From(_))))))),
    StatusForaFluxo = List.Difference(StatusTableu, {"APROG", "COMP", "FECHAR"}),
    QtdOSOperacional = Table.RowCount(OSOperacional),
    NucleoNuloOS = Table.RowCount(Table.SelectRows(OSOperacional, each [NUCLEO] = null or Text.Trim(Text.From([NUCLEO])) = "")),

    Checks = {
        Linha("Frota", "Linhas = placas únicas", "iguais", QtdFrota & " / " & QtdPlacasFrota, QtdFrota = QtdPlacasFrota),
        Linha("Frota", "Placa vazia", "0", NulosPlacaFrota, NulosPlacaFrota = 0),

        Linha("SuasTrans", "Placas cobertas", Texto(QtdFrota), QtdPlacasSuas, QtdPlacasSuas = QtdFrota),
        Linha("SuasTrans", "Tipos documentais", "9", QtdTiposSuas, QtdTiposSuas = 9),
        Linha("SuasTrans", "Linhas placa x 9 documentos", Texto(EsperadoSuas), QtdSuas, QtdSuas = EsperadoSuas, "Se houver documento legitimamente ausente, a divergência deve ser investigada e não mascarada."),
        Linha("SuasTrans", "NUCLEO vazio", "0", NucleoNuloSuas, NucleoNuloSuas = 0),

        Linha("MaxTrack", "Placas cobertas", Texto(QtdFrota), QtdPlacasMax, QtdPlacasMax = QtdFrota),
        Linha("MaxTrack", "Uma linha por placa", Texto(QtdPlacasMax), QtdMax, QtdMax = QtdPlacasMax),
        Linha("MaxTrack", "KM/ODOMETRO vazio", "0", KmNuloMax, KmNuloMax = 0),

        Linha("Medidor", "Uma linha por placa", Texto(QtdFrota), QtdMedidor, QtdMedidor = QtdFrota),
        Linha("Medidor", "NUCLEO vazio", "0", NucleoNuloMedidor, NucleoNuloMedidor = 0),
        Linha("Medidor", "Problemas de integridade", "0", ProblemasMedidor, ProblemasMedidor = 0),

        Linha("Mano/Ter", "Uma linha por placa", Texto(QtdFrota), QtdManoTer, QtdManoTer = QtdFrota),
        Linha("Mano/Ter", "NUCLEO vazio", "0", NucleoNuloManoTer, NucleoNuloManoTer = 0),
        Linha("Mano/Ter", "Problemas de integridade", "0", ProblemasManoTer, ProblemasManoTer = 0),

        Linha("Atualização Mãe", "Uma linha por placa", Texto(QtdFrota), QtdAtualizacaoMae, QtdAtualizacaoMae = QtdFrota),
        Linha("Atualização Mãe", "NUCLEO vazio", "0", NucleoNuloAtualizacaoMae, NucleoNuloAtualizacaoMae = 0),
        Linha("Atualização Mãe", "Problemas de integridade", "0", ProblemasAtualizacaoMae, ProblemasAtualizacaoMae = 0),

        Linha("Tableau", "Status fora do fluxo", "nenhum", Text.Combine(StatusForaFluxo, ", "), List.Count(StatusForaFluxo) = 0, "Status conhecidos: APROG, COMP e FECHAR."),
        Linha("OS Operacional", "Mesma quantidade da base Tableu", Texto(QtdTableu), QtdOSOperacional, QtdOSOperacional = QtdTableu),
        Linha("OS Operacional", "NUCLEO vazio", "0", NucleoNuloOS, NucleoNuloOS = 0)
    },

    Resultado0 = Table.FromRecords(Checks),
    AddOrdem = Table.AddColumn(Resultado0, "Ordem", each if [Status] = "REVISAR" then 1 else 2, Int64.Type),
    Ordenar = Table.Sort(AddOrdem, {{"Ordem", Order.Ascending}, {"Área", Order.Ascending}, {"Verificação", Order.Ascending}}),
    Resultado = Table.RemoveColumns(Ordenar, {"Ordem"})
in
    Resultado
