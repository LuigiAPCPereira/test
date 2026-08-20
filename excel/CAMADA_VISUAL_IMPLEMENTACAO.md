# Implementação Visual — Controle de Frotas Nordeste

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

## Segmentadores da página principal

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

## Aba `Atualização Mãe`

Esta passa a ser a página de consulta rápida para PROCV/XLOOKUP e substitui, após validação, as sete páginas simples antigas.

Carregar `AtualizacaoMae` como tabela `tbAtualizacaoMae`.

### Ordem das colunas

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
14. Documentos faltantes
15. Documentos duplicados

### Segmentadores

Prioridade:

- NUCLEO
- Documento Mano/Ter mais próximo
- Integridade
- Placa

O segmentador `Documento Mano/Ter mais próximo` resolve diretamente o uso solicitado: selecionar `Termômetro`, `Manômetro Vertical` ou `Manômetro Horizontal` e visualizar apenas as placas em que aquele item é o primeiro dos três a vencer.

A data correta para o campo `Mano/Ter` da planilha mãe permanece na coluna `Mano/Ter`, portanto o filtro visual não muda a lógica do PROCV/XLOOKUP.

### Formatação

- datas no padrão `dd/mm/aaaa`;
- `Integridade = OK` discreto;
- faltante/duplicado destacado;
- congelar cabeçalho;
- não criar cartões nessa página.

## Mano-Ter e Medidor — decisão de simplificação

Durante a validação, as páginas `Mano-Ter` e `Medidor` podem continuar existindo.

Depois da comparação, porém, a estrutura preferida é usar `Atualização Mãe` como página única, porque ela já contém:

- Medidor Mássico;
- Mano/Ter consolidado;
- Documento Mano/Ter mais próximo;
- demais documentos usados no PROCV/XLOOKUP.

Se os segmentadores da `Atualização Mãe` forem suficientes no uso real, `ManoTer` e `Medidor` podem deixar de ser carregadas como páginas. Isso reduz duplicação visual e também reduz trabalho de refresh.

## Preventiva Rodante

Página detalhada própria.

Colunas principais:

1. Placa
2. Frota
3. Núcleo
4. KM Atual
5. KM Últ. Prev.
6. KM Próx. Prev.
7. KM Restante
8. Faixa KM
9. Data Próx. Prev.
10. Dias para a data
11. Situação Geral
12. Integridade

Segmentadores:

- Núcleo
- Situação Geral
- Faixa KM
- Mês-Ano
- Integridade
- Placa

`KM Restante`, `Data Próx. Prev.` e `Situação Geral` devem receber maior destaque visual.

## SuasTrans

Manter a página atual, incluindo sua tabela verde e os segmentadores azuis, porque já é usada para os prints operacionais.

Não substituir pela `DocumentosOperacionais`.

`DocumentosOperacionais` fica como consulta auxiliar/somente conexão alimentando `AcoesOperacionais`.

## OS Operacional

Depois da comparação com a aba Tableu atual, carregar `OSOperacional` em uma página visível e deixar a consulta `Tableu` como somente conexão.

A consulta `Tableu` continua obrigatória como staging; apenas a aba deixa de ser necessária.

Segmentadores recomendados:

- NUCLEO
- AÇÃO OPERACIONAL
- STATUS
- RECORRENCIA
- PERÍODO
- PLACA

A coluna `AÇÃO OPERACIONAL` deve ficar próxima do `STATUS`, para deixar imediatamente visível:

- COMP → FECHAR NO MÁXIMO
- APROG → COBRAR MECÂNICA
- FECHAR → SEM AÇÃO

## Qualidade dos Dados

Página discreta de exceções.

Segmentadores opcionais:

- Gravidade
- Origem
- NUCLEO

Quando a base estiver íntegra, a tabela deve ficar vazia ou quase vazia.

## Estrutura visual final preferida

1. Ações Operacionais
2. Preventiva Rodante
3. SuasTrans
4. OS Operacional
5. Atualização Mãe
6. Qualidade dos Dados

Opcionalmente, durante transição:

7. Mano-Ter
8. Medidor

Essa redução é intencional: menos páginas duplicadas, menos consultas carregadas e mais clareza para o trabalho diário.

## O que não fazer

- não criar gráfico de pizza para status;
- não criar muitos KPIs que repitam a tabela;
- não duplicar a mesma informação em várias páginas;
- não esconder erros de integridade com filtros;
- não remover as páginas antigas antes da conferência dos resultados.
