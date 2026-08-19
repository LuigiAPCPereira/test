let
    // ============================================================
    // AÇÕES OPERACIONAIS — VISÃO INTEGRADA
    //
    // Une apenas itens que merecem atenção provenientes de:
    // - PreventivaRodante
    // - DocumentosOperacionais
    // - OSOperacional
    //
    // ManoTer e Medidor permanecem em páginas próprias para PROCV;
    // seus vencimentos já estão representados pela base documental.
    // ============================================================

    ColunasPadrao = {
        "ORDEM GERAL", "PRIORIDADE", "NUCLEO", "FILIAL", "PLACA", "FROTA",
        "CATEGORIA", "ITEM", "SITUAÇÃO", "AÇÃO", "DATA", "DIAS",
        "MÉTRICA DIAS", "KM RESTANTE", "REFERÊNCIA", "MÊS-ANO",
        "ORIGEM", "INTEGRIDADE"
    },

    Vazia = #table(ColunasPadrao, {}),

    Texto = (valor as nullable any) as nullable text =>
        if valor = null then null else Text.Trim(Text.From(valor)),

    PrioridadeTexto = (ordem as nullable number) as text =>
        if ordem = null then "REVISAR"
        else if ordem = 1 then "URGENTE"
        else if ordem = 2 then "AÇÃO"
        else if ordem = 3 then "ATENÇÃO"
        else "MONITORAR",

    // ---------------- PREVENTIVA RODANTE ----------------
    PreventivaAtiva = Table.SelectRows(
        PreventivaRodante,
        each Record.FieldOrDefault(_, "Situação Geral", "DADOS INCOMPLETOS") <> "OK"
    ),

    RegistrosPreventiva = List.Transform(
        Table.ToRecords(PreventivaAtiva),
        (r as record) as record =>
            let
                Situacao = Texto(Record.FieldOrDefault(r, "Situação Geral", null)),
                Integridade = Texto(Record.FieldOrDefault(r, "Integridade", null)),
                Ordem =
                    if Situacao = "CRÍTICA" or Situacao = "VENCIDA" or Situacao = "DADOS INCOMPLETOS" then 1
                    else if Situacao = "PROGRAMAR" then 2
                    else if Situacao = "ATENÇÃO" then 3
                    else 4,
                Acao =
                    if Situacao = "CRÍTICA" then "TRATAR PREVENTIVA"
                    else if Situacao = "VENCIDA" then "PROGRAMAR PREVENTIVA"
                    else if Situacao = "PROGRAMAR" then "PROGRAMAR PREVENTIVA"
                    else if Situacao = "ATENÇÃO" then "ACOMPANHAR PREVENTIVA"
                    else if Situacao = "MONITORAR" then "MONITORAR PREVENTIVA"
                    else "REVISAR DADOS",
                FaixaKm = Texto(Record.FieldOrDefault(r, "Faixa KM", null)),
                StatusData = Texto(Record.FieldOrDefault(r, "Status por data", null)),
                Ref = Text.Combine(List.RemoveNulls({FaixaKm, StatusData}), " | ")
            in
                [
                    #"ORDEM GERAL" = Ordem,
                    PRIORIDADE = PrioridadeTexto(Ordem),
                    NUCLEO = Texto(Record.FieldOrDefault(r, "Núcleo", null)),
                    FILIAL = Texto(Record.FieldOrDefault(r, "Filial", null)),
                    PLACA = Texto(Record.FieldOrDefault(r, "Placa", null)),
                    FROTA = Texto(Record.FieldOrDefault(r, "Frota", null)),
                    CATEGORIA = "PREVENTIVA RODANTE",
                    ITEM = "Preventiva Rodante",
                    #"SITUAÇÃO" = Situacao,
                    #"AÇÃO" = Acao,
                    DATA = Record.FieldOrDefault(r, "Data Próx. Prev.", null),
                    DIAS = Record.FieldOrDefault(r, "Dias para a data", null),
                    #"MÉTRICA DIAS" = "PARA PRÓX. PREVENTIVA",
                    #"KM RESTANTE" = Record.FieldOrDefault(r, "KM Restante", null),
                    #"REFERÊNCIA" = Ref,
                    #"MÊS-ANO" = Texto(Record.FieldOrDefault(r, "Mês-Ano", null)),
                    ORIGEM = "PreventivaRodante",
                    INTEGRIDADE = if Integridade = null then "REVISAR" else Integridade
                ]
    ),

    TabelaPreventiva = Table.FromRecords(RegistrosPreventiva),

    // ---------------- DOCUMENTAÇÃO ----------------
    DocumentosAtivos = Table.SelectRows(
        DocumentosOperacionais,
        each Record.FieldOrDefault(_, "AÇÃO OPERACIONAL", "REVISAR STATUS") <> "SEM AÇÃO"
    ),

    RegistrosDocumentos = List.Transform(
        Table.ToRecords(DocumentosAtivos),
        (r as record) as record =>
            let
                Acao = Texto(Record.FieldOrDefault(r, "AÇÃO OPERACIONAL", null)),
                Status = Texto(Record.FieldOrDefault(r, "STATUS", null)),
                Ordem =
                    if Acao = "REGULARIZAR DOCUMENTO" or Acao = "REVISAR DADO" or Acao = "REVISAR STATUS" then 1
                    else 2
            in
                [
                    #"ORDEM GERAL" = Ordem,
                    PRIORIDADE = PrioridadeTexto(Ordem),
                    NUCLEO = Texto(Record.FieldOrDefault(r, "NUCLEO", null)),
                    FILIAL = Texto(Record.FieldOrDefault(r, "FILIAL", null)),
                    PLACA = Texto(Record.FieldOrDefault(r, "PLACA", null)),
                    FROTA = Texto(Record.FieldOrDefault(r, "FROTA", null)),
                    CATEGORIA = "DOCUMENTAÇÃO",
                    ITEM = Texto(Record.FieldOrDefault(r, "TIPO DE DOCUMENTO", null)),
                    #"SITUAÇÃO" = Status,
                    #"AÇÃO" = Acao,
                    DATA = Record.FieldOrDefault(r, "VALIDADE", null),
                    DIAS = Record.FieldOrDefault(r, "DIAS PARA VENCER", null),
                    #"MÉTRICA DIAS" = "PARA VENCER",
                    #"KM RESTANTE" = null,
                    #"REFERÊNCIA" = Texto(Record.FieldOrDefault(r, "PERÍODO VALIDADE", null)),
                    #"MÊS-ANO" = Texto(Record.FieldOrDefault(r, "MÊS-ANO", null)),
                    ORIGEM = "SuasTrans",
                    INTEGRIDADE = Texto(Record.FieldOrDefault(r, "INTEGRIDADE", "REVISAR"))
                ]
    ),

    TabelaDocumentos = Table.FromRecords(RegistrosDocumentos),

    // ---------------- ORDENS DE SERVIÇO ----------------
    OSAtivas = Table.SelectRows(
        OSOperacional,
        each Record.FieldOrDefault(_, "AÇÃO OPERACIONAL", "REVISAR STATUS") <> "SEM AÇÃO"
    ),

    RegistrosOS = List.Transform(
        Table.ToRecords(OSAtivas),
        (r as record) as record =>
            let
                Acao = Texto(Record.FieldOrDefault(r, "AÇÃO OPERACIONAL", null)),
                Status = Texto(Record.FieldOrDefault(r, "STATUS", null)),
                NumeroOS = Texto(Record.FieldOrDefault(r, "OS", null)),
                Descricao0 = Record.FieldOrDefault(r, "Descrição", null),
                Descricao1 = if Descricao0 = null then Record.FieldOrDefault(r, "DESCRIÇÃO", null) else Descricao0,
                Descricao = Texto(Descricao1),
                Item =
                    if NumeroOS <> null and Descricao <> null then "OS " & NumeroOS & " — " & Descricao
                    else if NumeroOS <> null then "OS " & NumeroOS
                    else if Descricao <> null then Descricao
                    else "Ordem de Serviço",
                Ordem =
                    if Acao = "FECHAR NO MÁXIMO" or Acao = "REVISAR STATUS" then 1
                    else 2,
                Integridade = if Acao = "REVISAR STATUS" then "STATUS NÃO MAPEADO" else "OK"
            in
                [
                    #"ORDEM GERAL" = Ordem,
                    PRIORIDADE = PrioridadeTexto(Ordem),
                    NUCLEO = Texto(Record.FieldOrDefault(r, "NUCLEO", null)),
                    FILIAL = Texto(Record.FieldOrDefault(r, "FILIAL", null)),
                    PLACA = Texto(Record.FieldOrDefault(r, "PLACA", null)),
                    FROTA = Texto(Record.FieldOrDefault(r, "FROTA", null)),
                    CATEGORIA = "ORDEM DE SERVIÇO",
                    ITEM = Item,
                    #"SITUAÇÃO" = Status,
                    #"AÇÃO" = Acao,
                    DATA = Record.FieldOrDefault(r, "DATA OS", null),
                    DIAS = Record.FieldOrDefault(r, "DIAS DESDE SOLICITAÇÃO", null),
                    #"MÉTRICA DIAS" = "DESDE SOLICITAÇÃO",
                    #"KM RESTANTE" = null,
                    #"REFERÊNCIA" = Texto(Record.FieldOrDefault(r, "PERÍODO", null)),
                    #"MÊS-ANO" = Texto(Record.FieldOrDefault(r, "MÊS-ANO OS", null)),
                    ORIGEM = "Tableau/Máximo",
                    INTEGRIDADE = Integridade
                ]
    ),

    TabelaOS = Table.FromRecords(RegistrosOS),

    // ---------------- FILA ÚNICA ----------------
    Combinar = Table.Combine({Vazia, TabelaPreventiva, TabelaDocumentos, TabelaOS}),

    Tipar = Table.TransformColumnTypes(
        Combinar,
        {
            {"ORDEM GERAL", Int64.Type},
            {"DATA", type date},
            {"DIAS", Int64.Type},
            {"KM RESTANTE", type number}
        },
        "pt-BR"
    ),

    Ordenar = Table.Sort(
        Tipar,
        {
            {"ORDEM GERAL", Order.Ascending},
            {"NUCLEO", Order.Ascending},
            {"DATA", Order.Ascending},
            {"KM RESTANTE", Order.Ascending},
            {"PLACA", Order.Ascending},
            {"CATEGORIA", Order.Ascending}
        }
    )
in
    Ordenar
