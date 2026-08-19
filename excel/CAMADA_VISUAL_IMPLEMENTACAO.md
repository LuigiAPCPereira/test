# Implementação Visual — Ações Operacionais

Este arquivo transforma a especificação visual em um layout concreto para montar no Excel depois que as consultas estiverem validadas.

## Aba de apoio

Criar uma aba chamada `_Apoio` e carregar nela a consulta `ResumoOperacional` como tabela `tbResumoOperacional`.

A aba pode ficar oculta depois.

Motivo: os cartões da aba principal precisam de células/tabela carregadas para usar fórmulas de planilha. `ResumoOperacional` como **somente conexão** não alimenta diretamente fórmulas comuns de célula.

## Aba `Ações Operacionais`

### Área superior

- `A1:M1` — título: **CONTROLE OPERACIONAL — FROTAS NORDESTE**
- `A2:M2` — subtítulo discreto: **Atualize os dados e filtre somente o que exige ação**

### Cartões

Usar seis cartões pequenos, sem gráficos:

- `A4:B6` — **AÇÕES PENDENTES**
- `C4:D6` — **URGENTES**
- `E4:F6` — **FECHAR NO MÁXIMO**
- `G4:H6` — **COBRAR MECÂNICA**
- `I4:J6` — **DOC. VENCIDOS**
- `K4:L6` — **PREVENTIVAS**

Com `tbResumoOperacional`, as fórmulas conceituais são:

```excel
=PROCX("TOTAL";tbResumoOperacional[NUCLEO];tbResumoOperacional[TOTAL AÇÕES];0)
=PROCX("TOTAL";tbResumoOperacional[NUCLEO];tbResumoOperacional[URGENTES];0)
=PROCX("TOTAL";tbResumoOperacional[NUCLEO];tbResumoOperacional[FECHAR NO MÁXIMO];0)
=PROCX("TOTAL";tbResumoOperacional[NUCLEO];tbResumoOperacional[COBRAR MECÂNICA];0)
=PROCX("TOTAL";tbResumoOperacional[NUCLEO];tbResumoOperacional[REGULARIZAR DOCUMENTO];0)
=PROCX("TOTAL";tbResumoOperacional[NUCLEO];tbResumoOperacional[PROGRAMAR PREVENTIVA];0)
```

Se o Excel corporativo não tiver `PROCX`, usar `ÍNDICE` + `CORRESP`.

### Tabela

Carregar `AcoesOperacionais` começando em `A9` como `tbAcoesOperacionais`.

Ordem visual:

1. PRIORIDADE
2. NUCLEO
3. PLACA
4. FROTA
5. CATEGORIA
6. ITEM
7. SITUAÇÃO
8. AÇÃO
9. DATA
10. DIAS
11. KM RESTANTE
12. REFERÊNCIA
13. INTEGRIDADE

Colunas técnicas (`ORDEM GERAL`, `MÉTRICA DIAS`, `ORIGEM`) podem ficar no final e ocultas.

Congelar painéis acima da linha 9.

## Segmentadores

Posicionar à direita da tabela, começando aproximadamente na coluna `O`:

- O1: NUCLEO
- Q1: PRIORIDADE
- S1: CATEGORIA
- O8: AÇÃO
- Q8: MÊS-ANO
- S8: PLACA

A posição exata pode variar conforme resolução da tela; manter no máximo seis segmentadores nesta página.

## Linguagem visual

Manter compatibilidade com o arquivo atual:

- tabela principal em verde claro/estilo já usado;
- segmentadores em azul claro como SuasTrans/Tableau;
- sem fundos escuros;
- sem gráficos decorativos;
- bordas e títulos discretos.

### Prioridade

Usar formatação condicional na coluna `PRIORIDADE` e, se possível, na linha:

- `URGENTE` — destaque mais forte;
- `AÇÃO` — destaque médio;
- `ATENÇÃO` — destaque leve;
- `MONITORAR` — neutro.

`INTEGRIDADE <> "OK"` sempre deve se destacar, mesmo quando a prioridade não for urgente.

## Atualização Mãe

Carregar `AtualizacaoMae` como tabela `tbAtualizacaoMae`.

A disposição deve priorizar o PROCV/XLOOKUP:

1. Placa
2. Frota
3. NUCLEO
4. Filial
5. CIV
6. Crono
7. CIPP
8. TH
9. Medidor
10. Mano/Ter
11. Documento Mano/Ter mais próximo
12. CRLV
13. Integridade

Como essa aba é operacional e não um dashboard, não precisa de cartões.

Segmentadores opcionais:

- NUCLEO
- Documento Mano/Ter mais próximo
- Integridade
- Placa

## OS Operacional

Depois da comparação com a aba Tableu atual, carregar `OSOperacional` em uma página visível e deixar a consulta `Tableu` como somente conexão.

A consulta `Tableu` continua obrigatória como staging; apenas a aba deixa de ser necessária.

## O que não fazer

- não criar gráfico de pizza para status;
- não criar muitos KPIs que repitam a tabela;
- não duplicar a mesma informação em várias páginas;
- não esconder erros de integridade com filtros;
- não remover as páginas antigas antes da conferência dos resultados.
