# Camada Visual — Controle de Frotas Nordeste

Objetivo: deixar a planilha rápida para operação diária, sem transformar o arquivo em um dashboard pesado.

## 1. Aba principal — Ações Operacionais

### Topo (linhas 1 a 6)

Usar a consulta `ResumoOperacional` como apoio para os indicadores.

Indicadores principais:

- **Ações pendentes** — total de linhas da fila operacional.
- **Urgentes** — itens classificados como URGENTE.
- **Fechar no Máximo** — OS em COMP.
- **Cobrar mecânica** — OS em APROG.
- **Documentos vencidos** — ação REGULARIZAR DOCUMENTO.
- **Preventivas para programar** — PROGRAMAR PREVENTIVA + TRATAR PREVENTIVA.

A linha TOTAL de `ResumoOperacional` alimenta os cartões gerais. As linhas por núcleo permitem comparar os núcleos sem criar fórmulas extras.

### Segmentadores

Na lateral direita:

1. NUCLEO
2. PRIORIDADE
3. CATEGORIA
4. AÇÃO
5. MÊS-ANO
6. PLACA

Evitar mais segmentadores nessa aba. `SITUAÇÃO`, `FILIAL` e `INTEGRIDADE` continuam disponíveis no filtro da tabela.

### Tabela operacional

Colunas visíveis na ordem:

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

Colunas técnicas como `ORDEM GERAL`, `ORIGEM` e `MÉTRICA DIAS` podem ficar no final ou ocultas.

### Formatação condicional

- URGENTE → destaque forte.
- AÇÃO → destaque médio.
- ATENÇÃO → destaque leve.
- MONITORAR → sem destaque forte.
- INTEGRIDADE diferente de OK → sempre destacar, independentemente da prioridade.

Congelar as linhas superiores para que indicadores e segmentadores continuem visíveis durante a rolagem.

## 2. Aba Preventiva Rodante

É uma página detalhada, não precisa repetir todos os indicadores da principal.

Segmentadores:

- Núcleo
- Situação Geral
- Faixa KM
- Mês-Ano
- Integridade
- Placa

Colunas principais:

- Placa
- Frota
- Núcleo
- KM Atual
- KM Últ. Prev.
- KM Próx. Prev.
- KM Restante
- Faixa KM
- Data Próx. Prev.
- Dias para a data
- Situação Geral
- Integridade

Dar maior destaque visual a `KM Restante`, `Data Próx. Prev.` e `Situação Geral`.

## 3. Aba SuasTrans

Manter a visão atual porque ela já é usada para os prints enviados por núcleo.

Não substituir pela `DocumentosOperacionais` neste momento.

`DocumentosOperacionais` deve ficar como **somente conexão** e servir de base para `AcoesOperacionais`.

## 4. Aba OS Operacional

`Tableu` é a **consulta fonte/staging**.

`OSOperacional` é uma **visão derivada** da consulta `Tableu`.

Para `OSOperacional` funcionar, a consulta `Tableu` precisa existir, mas a planilha/aba carregada chamada `Tableu` não precisa ficar visível.

Durante o teste:

- manter a aba Tableu atual;
- deixar `OSOperacional` como somente conexão ou carregar em uma aba separada para comparação.

Depois da validação:

- manter a consulta `Tableu` como **somente conexão**;
- usar `OSOperacional` como a página visível de OS.

Nunca excluir a consulta `Tableu` enquanto `OSOperacional` depender dela.

Segmentadores recomendados:

- NUCLEO
- AÇÃO OPERACIONAL
- STATUS
- PERÍODO
- MÊS-ANO OS
- PLACA

Colunas de maior destaque:

- OS
- Descrição
- NUCLEO
- PLACA
- STATUS
- AÇÃO OPERACIONAL
- DATA OS
- DIAS DESDE SOLICITAÇÃO
- PREENCHIDO_POR

## 5. Aba Atualização Mãe

Nova visão consolidada gerada por `AtualizacaoMae`.

Ela existe para reduzir a quantidade de abas/consultas simples usadas apenas como fonte de PROCV/XLOOKUP.

Uma linha por placa com:

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

Essa página pode, depois da validação, substituir como fonte de atualização as abas simples antigas `CIV`, `Crono`, `CIPP`, `TH`, `Mássico`, `Medidores` e `CRLV`.

Não remover as antigas antes de comparar os resultados.

### Segmentadores

Para o uso normal de PROCV/XLOOKUP, nenhum segmentador é obrigatório.

Se quiser usar a mesma página para conferir Mano/Ter, adicionar:

- NUCLEO
- Documento Mano/Ter mais próximo
- Integridade
- Placa

Assim é possível filtrar, por exemplo, apenas placas em que **Termômetro** é o documento que vence primeiro, sem precisar de outra base para o PROCV.

## 6. Aba Mano-Ter

Pode permanecer durante a validação e se o segmentador específico for útil.

Segmentadores:

- NUCLEO
- Status
- Documento mais próximo
- Prioridade
- Mês-Ano
- Placa

Colunas de PROCV/XLOOKUP devem continuar nas primeiras posições:

1. Placa
2. Validade Mano/Ter
3. Documento mais próximo

Depois entram Status, Prioridade, NUCLEO, Filial, Frota e Integridade.

Se a aba `Atualização Mãe` cobrir o uso real, esta página pode futuramente virar apenas uma visão de conferência.

## 7. Aba Medidor

Representa exclusivamente o medidor mássico 02.02.

Segmentadores:

- NUCLEO
- Status
- Prioridade
- Mês-Ano
- Placa

Primeiras colunas:

1. Placa
2. Validade Medidor

Assim o PROCV/XLOOKUP continua simples.

A consulta usa NUCLEO, Filial e Frota da própria `SuasTrans`, evitando a incompatibilidade `Núcleo` x `NUCLEO` que gerou valores `null` anteriormente.

## 8. Qualidade dos Dados

Deve ser discreta e usada apenas para exceções.

Segmentadores opcionais:

- Gravidade
- Origem
- NUCLEO

Se não houver problema, a tabela deve ficar vazia ou quase vazia.

## 9. Estrutura final recomendada

### Páginas principais

1. Ações Operacionais
2. Preventiva Rodante
3. SuasTrans
4. OS Operacional
5. Atualização Mãe
6. Qualidade dos Dados

### Páginas opcionais de detalhe

- Mano-Ter
- Medidor

Elas ficam enquanto agregarem valor pelos segmentadores específicos. Se `Atualização Mãe` cobrir a necessidade, não é obrigatório manter duas páginas adicionais.

### Consultas auxiliares como somente conexão

- ConsultarFrotasNordeste
- Tableu
- DocumentosOperacionais
- ResumoOperacional
- DiagnosticoPastasSharePoint (temporária; remover depois de capturar os caminhos)

`MaxTrack` pode ficar visível somente se houver utilidade operacional em consultar a base bruta; caso contrário, também pode virar somente conexão depois da validação.

A aba SuasTrans permanece visível porque já faz parte do processo operacional atual.

## 10. Performance visual

Evitar gráficos e objetos desnecessários. O arquivo é ferramenta de operação, não apresentação executiva.

Preferir:

- tabelas estruturadas;
- poucos segmentadores bem escolhidos;
- formatação condicional;
- indicadores simples no topo;
- consultas de apoio como somente conexão.

A estratégia de performance das fontes e do refresh está documentada em `PERFORMANCE.md`.
