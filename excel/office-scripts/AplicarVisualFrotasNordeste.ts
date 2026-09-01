function main(workbook: ExcelScript.Workbook) {
  const C = {
    navy: "#17365D",
    blue: "#2F75B5",
    lightBlue: "#D9EAF7",
    white: "#FFFFFF",
    text: "#1F1F1F",
    border: "#D9E2F3",
    urgent: "#C00000",
    urgentFill: "#FCE4D6",
    action: "#BF6D00",
    actionFill: "#FFF2CC",
    attention: "#9C6500",
    attentionFill: "#FFE699",
    monitor: "#548235",
    monitorFill: "#E2F0D9",
    ok: "#548235",
    okFill: "#E2F0D9",
    gray: "#F2F2F2",
    darkGray: "#666666"
  };

  const operationalSheets = [
    "AcoesOperacionais",
    "PreventivaRodante",
    "SuaTrans",
    "OSOperacional",
    "Atualizacao",
    "QualidadeDados",
    "MaxTrack",
    "Tableu"
  ];

  function getSheet(name: string): ExcelScript.Worksheet | undefined {
    return workbook.getWorksheet(name);
  }

  function styleBase(sheet: ExcelScript.Worksheet, freezeColumns: number = 3) {
    const used = sheet.getUsedRange();
    if (!used) return;

    sheet.setShowGridlines(false);
    sheet.getFreezePanes().unfreeze();
    sheet.getFreezePanes().freezeRows(1);
    if (freezeColumns > 0) sheet.getFreezePanes().freezeColumns(freezeColumns);

    const header = used.getRow(0);
    header.getFormat().getFill().setColor(C.navy);
    header.getFormat().getFont().setColor(C.white);
    header.getFormat().getFont().setBold(true);
    header.getFormat().getFont().setSize(10);
    header.getFormat().setHorizontalAlignment(ExcelScript.HorizontalAlignment.center);
    header.getFormat().setVerticalAlignment(ExcelScript.VerticalAlignment.center);
    header.getFormat().setRowHeight(30);
    header.getFormat().setWrapText(true);

    used.getFormat().getFont().setName("Aptos");
    used.getFormat().getFont().setSize(9);
    used.getFormat().setVerticalAlignment(ExcelScript.VerticalAlignment.center);
    used.getFormat().autofitRows();

    sheet.getTables().forEach((table) => {
      try { table.setPredefinedTableStyle("TableStyleMedium2"); } catch (e) { }
    });
  }

  function setWidth(sheet: ExcelScript.Worksheet, address: string, width: number) {
    sheet.getRange(address).getFormat().setColumnWidth(width);
  }

  function addCustomFill(
    range: ExcelScript.Range,
    formula: string,
    fill: string,
    fontColor?: string,
    bold: boolean = false
  ) {
    const cf = range.addConditionalFormat(ExcelScript.ConditionalFormatType.custom).getCustom();
    cf.getRule().setFormula(formula);
    cf.getFormat().getFill().setColor(fill);
    if (fontColor) cf.getFormat().getFont().setColor(fontColor);
    if (bold) cf.getFormat().getFont().setBold(true);
  }

  operationalSheets.forEach((name) => {
    const s = getSheet(name);
    if (s) styleBase(s, name === "MaxTrack" ? 3 : 3);
  });

  // ============================================================
  // AÇÕES OPERACIONAIS — principal fila de trabalho
  // ============================================================
  const acoes = getSheet("AcoesOperacionais");
  if (acoes) {
    const used = acoes.getUsedRange();
    if (used) {
      const rows = Math.max(used.getRowCount(), 2);
      const whole = acoes.getRange(`A2:R${rows}`);
      whole.getConditionalFormats().clearAll();

      addCustomFill(whole, '=$E2="URGENTE"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$E2="AÇÃO"', C.actionFill, C.action, true);
      addCustomFill(whole, '=$E2="ATENÇÃO"', C.attentionFill, C.attention, false);
      addCustomFill(whole, '=$E2="MONITORAR"', C.monitorFill, C.monitor, false);

      setWidth(acoes, "A:A", 92);
      setWidth(acoes, "B:B", 88);
      setWidth(acoes, "C:C", 78);
      setWidth(acoes, "D:E", 82);
      setWidth(acoes, "F:F", 70);
      setWidth(acoes, "G:G", 125);
      setWidth(acoes, "H:H", 255);
      setWidth(acoes, "I:J", 150);
      setWidth(acoes, "K:K", 88);
      setWidth(acoes, "L:L", 70);
      setWidth(acoes, "M:M", 145);
      setWidth(acoes, "N:N", 95);
      setWidth(acoes, "O:O", 150);
      setWidth(acoes, "P:R", 115);
      acoes.getRange("H:H").getFormat().setWrapText(true);
      acoes.getRange("J:J").getFormat().setWrapText(true);
      acoes.getRange("O:O").getFormat().setWrapText(true);
      acoes.getRange(`K2:K${rows}`).setNumberFormatLocal("dd/mm/yyyy");
      acoes.getRange(`N2:N${rows}`).setNumberFormatLocal("#,##0");
    }
  }

  // ============================================================
  // PREVENTIVA RODANTE
  // ============================================================
  const preventiva = getSheet("PreventivaRodante");
  if (preventiva) {
    const used = preventiva.getUsedRange();
    if (used) {
      const rows = Math.max(used.getRowCount(), 2);
      const whole = preventiva.getRange(`A2:S${rows}`);
      whole.getConditionalFormats().clearAll();
      addCustomFill(whole, '=$O2="CRÍTICA"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$O2="VENCIDA"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$O2="PROGRAMAR"', C.actionFill, C.action, true);
      addCustomFill(whole, '=$O2="ATENÇÃO"', C.attentionFill, C.attention, false);
      addCustomFill(whole, '=$O2="MONITORAR"', C.monitorFill, C.monitor, false);

      setWidth(preventiva, "A:A", 95);
      setWidth(preventiva, "B:B", 88);
      setWidth(preventiva, "C:D", 76);
      setWidth(preventiva, "E:J", 92);
      setWidth(preventiva, "K:K", 165);
      setWidth(preventiva, "L:L", 95);
      setWidth(preventiva, "M:M", 90);
      setWidth(preventiva, "N:O", 155);
      setWidth(preventiva, "P:S", 105);
      preventiva.getRange("K:O").getFormat().setWrapText(true);
      preventiva.getRange(`L2:L${rows}`).setNumberFormatLocal("dd/mm/yyyy");
      preventiva.getRange(`S2:S${rows}`).setNumberFormatLocal("dd/mm/yyyy");
    }
  }

  // ============================================================
  // SUASTRANS — documentos
  // ============================================================
  const suas = getSheet("SuaTrans");
  if (suas) {
    const used = suas.getUsedRange();
    if (used) {
      const rows = Math.max(used.getRowCount(), 2);
      const whole = suas.getRange(`A2:I${rows}`);
      whole.getConditionalFormats().clearAll();
      addCustomFill(whole, '=$H2="Vencido"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$H2="VENCIDO"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$H2="Expirando"', C.actionFill, C.action, true);
      addCustomFill(whole, '=$H2="EXPIRANDO"', C.actionFill, C.action, true);
      addCustomFill(whole, '=$H2="Válido"', C.okFill, C.ok, false);
      addCustomFill(whole, '=$H2="VÁLIDO"', C.okFill, C.ok, false);
      setWidth(suas, "A:A", 95);
      setWidth(suas, "B:B", 90);
      setWidth(suas, "C:D", 78);
      setWidth(suas, "E:E", 285);
      setWidth(suas, "F:F", 92);
      setWidth(suas, "G:I", 105);
      suas.getRange("E:E").getFormat().setWrapText(true);
      suas.getRange(`F2:F${rows}`).setNumberFormatLocal("dd/mm/yyyy");
      suas.getRange(`I2:I${rows}`).setNumberFormatLocal("dd/mm/yyyy");
    }
  }

  // ============================================================
  // OS OPERACIONAL
  // ============================================================
  const os = getSheet("OSOperacional");
  if (os) {
    const used = os.getUsedRange();
    if (used) {
      const rows = Math.max(used.getRowCount(), 2);
      const whole = os.getRange(`A2:U${rows}`);
      whole.getConditionalFormats().clearAll();
      addCustomFill(whole, '=$O2="FECHAR NO MÁXIMO"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$O2="COBRAR MECÂNICA"', C.actionFill, C.action, true);
      addCustomFill(whole, '=$O2="REVISAR STATUS"', C.attentionFill, C.attention, true);
      addCustomFill(whole, '=$O2="SEM AÇÃO"', C.gray, C.darkGray, false);
      setWidth(os, "A:B", 90);
      setWidth(os, "C:D", 78);
      setWidth(os, "E:E", 92);
      setWidth(os, "F:F", 240);
      setWidth(os, "G:I", 95);
      setWidth(os, "J:J", 90);
      setWidth(os, "K:K", 120);
      setWidth(os, "L:M", 135);
      setWidth(os, "N:N", 120);
      setWidth(os, "O:O", 150);
      setWidth(os, "P:U", 105);
      os.getRange("F:F").getFormat().setWrapText(true);
      os.getRange("O:O").getFormat().setWrapText(true);
      os.getRange(`Q2:Q${rows}`).setNumberFormatLocal("dd/mm/yyyy");
      os.getRange(`U2:U${rows}`).setNumberFormatLocal("dd/mm/yyyy");
    }
  }

  // ============================================================
  // QUALIDADE DOS DADOS
  // ============================================================
  const qualidade = getSheet("QualidadeDados");
  if (qualidade) {
    const used = qualidade.getUsedRange();
    if (used) {
      const rows = Math.max(used.getRowCount(), 2);
      const whole = qualidade.getRange(`A2:I${rows}`);
      whole.getConditionalFormats().clearAll();
      addCustomFill(whole, '=$D2="ERRO"', C.urgentFill, C.urgent, true);
      addCustomFill(whole, '=$D2="ALERTA"', C.actionFill, C.action, true);
      setWidth(qualidade, "A:B", 95);
      setWidth(qualidade, "C:C", 82);
      setWidth(qualidade, "D:F", 105);
      setWidth(qualidade, "G:G", 175);
      setWidth(qualidade, "H:H", 350);
      setWidth(qualidade, "I:I", 90);
      qualidade.getRange("G:H").getFormat().setWrapText(true);
    }
  }

  // ============================================================
  // ATUALIZAÇÃO MÃE / MAXTRACK / TABLEAU
  // ============================================================
  const atualizacao = getSheet("Atualizacao");
  if (atualizacao) {
    setWidth(atualizacao, "A:B", 95);
    setWidth(atualizacao, "C:D", 78);
    setWidth(atualizacao, "E:J", 95);
    setWidth(atualizacao, "K:K", 260);
    setWidth(atualizacao, "L:L", 95);
    setWidth(atualizacao, "M:M", 110);
    setWidth(atualizacao, "N:O", 220);
    atualizacao.getRange("K:O").getFormat().setWrapText(true);
  }

  const max = getSheet("MaxTrack");
  if (max) {
    setWidth(max, "A:B", 95);
    setWidth(max, "C:C", 82);
    setWidth(max, "D:E", 110);
  }

  const tableu = getSheet("Tableu");
  if (tableu) {
    setWidth(tableu, "A:B", 95);
    setWidth(tableu, "C:D", 78);
    setWidth(tableu, "E:E", 95);
    setWidth(tableu, "F:F", 240);
    setWidth(tableu, "G:N", 120);
    tableu.getRange("F:F").getFormat().setWrapText(true);
  }

  // ============================================================
  // PAINEL OPERACIONAL
  // ============================================================
  let painel = getSheet("Painel Operacional");
  if (!painel) {
    painel = workbook.addWorksheet("Painel Operacional");
  } else {
    painel.getCharts().forEach((chart) => chart.delete());
    const old = painel.getUsedRange();
    if (old) old.clear(ExcelScript.ClearApplyTo.all);
  }

  painel.setShowGridlines(false);
  painel.getRange("A1:N30").getFormat().getFont().setName("Aptos");
  painel.getRange("A1:N30").getFormat().getFont().setColor(C.text);

  painel.mergeCells("A1:N1");
  painel.getRange("A1").setValue("PAINEL OPERACIONAL — FROTAS NORDESTE");
  painel.getRange("A1:N1").getFormat().getFill().setColor(C.navy);
  painel.getRange("A1:N1").getFormat().getFont().setColor(C.white);
  painel.getRange("A1:N1").getFormat().getFont().setBold(true);
  painel.getRange("A1:N1").getFormat().getFont().setSize(20);
  painel.getRange("A1:N1").getFormat().setHorizontalAlignment(ExcelScript.HorizontalAlignment.center);
  painel.getRange("A1:N1").getFormat().setVerticalAlignment(ExcelScript.VerticalAlignment.center);
  painel.getRange("A1:N1").getFormat().setRowHeight(42);

  painel.mergeCells("A3:N3");
  painel.getRange("A3").setValue(`Visão consolidada das ações • Atualizado em ${new Date().toLocaleDateString("pt-BR")}`);
  painel.getRange("A3:N3").getFormat().getFont().setColor(C.darkGray);
  painel.getRange("A3:N3").getFormat().getFont().setItalic(true);
  painel.getRange("A3:N3").getFormat().setHorizontalAlignment(ExcelScript.HorizontalAlignment.center);

  const cardLabels = [
    ["URGENTES", "", "AÇÃO", "", "ATENÇÃO", "", "DOCUMENTAÇÃO", "", "PREVENTIVA", "", "ORDENS DE SERVIÇO", "", "EXCEÇÕES", ""]
  ];
  painel.getRange("A5:N5").setValues(cardLabels);
  const cardFormulaRow = [[
    '=COUNTIF(AcoesOperacionais!E:E,"URGENTE")', "",
    '=COUNTIF(AcoesOperacionais!E:E,"AÇÃO")', "",
    '=COUNTIF(AcoesOperacionais!E:E,"ATENÇÃO")', "",
    '=COUNTIF(AcoesOperacionais!G:G,"DOCUMENTAÇÃO")', "",
    '=COUNTIF(AcoesOperacionais!G:G,"PREVENTIVA RODANTE")', "",
    '=COUNTIF(AcoesOperacionais!G:G,"ORDEM DE SERVIÇO")', "",
    '=MAX(COUNTA(QualidadeDados!A:A)-1,0)', ""
  ]];
  painel.getRange("A6:N6").setFormulas(cardFormulaRow);

  for (let col = 0; col < 14; col += 2) {
    const label = painel.getRangeByIndexes(4, col, 1, 2);
    const value = painel.getRangeByIndexes(5, col, 1, 2);
    label.merge(false);
    value.merge(false);
    label.getFormat().getFill().setColor(C.blue);
    label.getFormat().getFont().setColor(C.white);
    label.getFormat().getFont().setBold(true);
    label.getFormat().getFont().setSize(10);
    label.getFormat().setHorizontalAlignment(ExcelScript.HorizontalAlignment.center);
    label.getFormat().setVerticalAlignment(ExcelScript.VerticalAlignment.center);
    value.getFormat().getFill().setColor(C.lightBlue);
    value.getFormat().getFont().setColor(C.navy);
    value.getFormat().getFont().setBold(true);
    value.getFormat().getFont().setSize(22);
    value.getFormat().setHorizontalAlignment(ExcelScript.HorizontalAlignment.center);
    value.getFormat().setVerticalAlignment(ExcelScript.VerticalAlignment.center);
    label.getFormat().setRowHeight(28);
    value.getFormat().setRowHeight(40);
  }

  // Mini tabelas que alimentam os gráficos.
  painel.getRange("A11:B15").setValues([
    ["PRIORIDADE", "QTD"],
    ["URGENTE", 0],
    ["AÇÃO", 0],
    ["ATENÇÃO", 0],
    ["MONITORAR", 0]
  ]);
  painel.getRange("B12:B15").setFormulas([
    ['=COUNTIF(AcoesOperacionais!E:E,A12)'],
    ['=COUNTIF(AcoesOperacionais!E:E,A13)'],
    ['=COUNTIF(AcoesOperacionais!E:E,A14)'],
    ['=COUNTIF(AcoesOperacionais!E:E,A15)']
  ]);

  painel.getRange("D11:E14").setValues([
    ["CATEGORIA", "QTD"],
    ["DOCUMENTAÇÃO", 0],
    ["PREVENTIVA RODANTE", 0],
    ["ORDEM DE SERVIÇO", 0]
  ]);
  painel.getRange("E12:E14").setFormulas([
    ['=COUNTIF(AcoesOperacionais!G:G,D12)'],
    ['=COUNTIF(AcoesOperacionais!G:G,D13)'],
    ['=COUNTIF(AcoesOperacionais!G:G,D14)']
  ]);

  painel.getRange("G11:H14").setValues([
    ["NÚCLEO", "QTD"],
    ["NUC Bahia", 0],
    ["NUC Ceará", 0],
    ["NUC Pernambuco", 0]
  ]);
  painel.getRange("H12:H14").setFormulas([
    ['=COUNTIF(AcoesOperacionais!A:A,G12)'],
    ['=COUNTIF(AcoesOperacionais!A:A,G13)'],
    ['=COUNTIF(AcoesOperacionais!A:A,G14)']
  ]);

  ["A11:B15", "D11:E14", "G11:H14"].forEach((addr) => {
    const r = painel.getRange(addr);
    r.getFormat().getBorders().forEach((b) => {
      b.setColor(C.border);
      b.setStyle(ExcelScript.BorderLineStyle.continuous);
    });
    const h = r.getRow(0);
    h.getFormat().getFill().setColor(C.navy);
    h.getFormat().getFont().setColor(C.white);
    h.getFormat().getFont().setBold(true);
  });

  const chart1 = painel.addChart(ExcelScript.ChartType.columnClustered, painel.getRange("A11:B15"));
  chart1.setPosition("J10", "N18");
  chart1.getTitle().setText("Ações por prioridade");
  chart1.getLegend().setVisible(false);

  const chart2 = painel.addChart(ExcelScript.ChartType.doughnut, painel.getRange("D11:E14"));
  chart2.setPosition("A17", "F28");
  chart2.getTitle().setText("Distribuição por categoria");

  const chart3 = painel.addChart(ExcelScript.ChartType.barClustered, painel.getRange("G11:H14"));
  chart3.setPosition("G17", "N28");
  chart3.getTitle().setText("Ações por núcleo");
  chart3.getLegend().setVisible(false);

  painel.mergeCells("A30:N30");
  painel.getRange("A30").setValue("Fluxo diário: adicionar os novos arquivos nas pastas → Dados > Atualizar Tudo → começar por AcoesOperacionais.");
  painel.getRange("A30:N30").getFormat().getFill().setColor(C.gray);
  painel.getRange("A30:N30").getFormat().getFont().setColor(C.darkGray);
  painel.getRange("A30:N30").getFormat().getFont().setItalic(true);
  painel.getRange("A30:N30").getFormat().setHorizontalAlignment(ExcelScript.HorizontalAlignment.center);

  painel.getRange("A:N").getFormat().setColumnWidth(84);
  painel.getRange("A1:N30").getFormat().setVerticalAlignment(ExcelScript.VerticalAlignment.center);
  painel.getFreezePanes().freezeRows(3);
  painel.activate();
}
