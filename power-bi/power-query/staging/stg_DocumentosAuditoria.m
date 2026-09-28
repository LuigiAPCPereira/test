let
    // ============================================================
    // STAGING — AUDITORIA DE MULTIPLICIDADE DOCUMENTAL
    // Origem: stg_Documentos
    // Objetivo: classificar múltiplas ocorrências por placa + documento
    // sem remover qualquer linha da camada detalhada.
    // ============================================================

    Fonte = stg_Documentos,

    Agrupar = Table.Group(
        Fonte,
        {"Placa Normalizada", "Placa", "Frota", "Código Documento", "Tipo de Documento"},
        {
            {"Qtd Registros", each Table.RowCount(_), Int64.Type},
            {
                "Qtd Validades Distintas",
                each List.Count(List.Distinct(List.RemoveNulls(Table.Column(_, "Validade")))),
                Int64.Type
            },
            {
                "Validades",
                each Text.Combine(
                    List.Transform(
                        List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "Validade"))), Order.Descending),
                        each Date.ToText(_, "dd/MM/yyyy", "pt-BR")
                    ),
                    " | "
                ),
                type text
            },
            {
                "Qtd Filiais SuaTrans Distintas",
                each List.Count(List.Distinct(List.RemoveNulls(Table.Column(_, "Filial SuaTrans")))),
                Int64.Type
            },
            {
                "Filiais SuaTrans",
                each Text.Combine(
                    List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "Filial SuaTrans")))),
                    " | "
                ),
                type text
            },
            {
                "Status Calculados",
                each Text.Combine(
                    List.Sort(List.Distinct(List.RemoveNulls(Table.Column(_, "Status Calculado")))),
                    " | "
                ),
                type text
            }
        }
    ),

    AddClassificacao = Table.AddColumn(
        Agrupar,
        "Classificação Multiplicidade",
        each
            if [Qtd Registros] = 1 then
                "ÚNICO"
            else if [Qtd Validades Distintas] > 1 then
                "RENOVAÇÃO POSSÍVEL"
            else if [Qtd Filiais SuaTrans Distintas] > 1 then
                "DUPLICIDADE ENTRE FILIAIS"
            else
                "DUPLICIDADE MESMA VALIDADE",
        type text
    ),

    AddRequerRevisao = Table.AddColumn(
        AddClassificacao,
        "Requer Revisão",
        each [Classificação Multiplicidade] <> "ÚNICO",
        type logical
    ),

    Resultado = Table.Sort(
        AddRequerRevisao,
        {
            {"Classificação Multiplicidade", Order.Ascending},
            {"Placa", Order.Ascending},
            {"Código Documento", Order.Ascending}
        }
    )
in
    Resultado
