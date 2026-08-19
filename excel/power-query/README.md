# Power Query — Controle de Frotas Nordeste

Arquivos auxiliares para evoluir a planilha sem alterar a lógica já funcional.

## Ordem sugerida de criação no Excel

1. `PreventivaRodante` — usar o arquivo `../PreventivaRodante_PowerQuery.m` já existente.
2. `ManoTer` — usar `ManoTer.m`.
3. `Medidor` — usar `Medidor.m`.
4. `OSOperacional` — usar `OSOperacional.m`.
5. `QualidadeDados` — usar `QualidadeDados.m`.

## Carregamento recomendado

- `PreventivaRodante`: carregar em tabela em uma nova planilha **Preventiva Rodante**.
- `ManoTer`: carregar em tabela em uma nova planilha **Mano-Ter**.
- `Medidor`: carregar em tabela em uma nova planilha **Medidor**.
- `OSOperacional`: pode substituir futuramente a visão atual da aba **Tableu**, depois do teste.
- `QualidadeDados`: carregar em tabela em uma nova planilha **Qualidade dos Dados**.

As consultas novas reaproveitam as consultas já existentes no workbook. `ManoTer`, `Medidor` e `OSOperacional` não refazem a leitura dos arquivos-fonte.

## Segmentadores recomendados

### Mano-Ter
- NUCLEO
- Status
- Documento mais próximo
- Prioridade
- Mês-Ano
- Placa

### Medidor
- NUCLEO
- Status
- Prioridade
- Mês-Ano
- Placa

### Preventiva Rodante
- NUCLEO
- Situação Geral
- Faixa KM
- Mês-Ano
- Integridade
- Placa

### OS Operacional
- NUCLEO
- AÇÃO OPERACIONAL
- STATUS
- RECORRENCIA
- PERÍODO
- MÊS-ANO OS
- PLACA

## Regra de Mano/Ter

Para cada placa, a consulta considera:
- 02.01 — Manômetro Analógico Vertical
- 02.03 — Termômetro Analógico
- 02.04 — Manômetro Analógico Horizontal

A validade usada no PROCV/XLOOKUP é a **menor das três**, e `Documento mais próximo` informa qual item gerou a menor data. Empates são mostrados em conjunto.

## Regra operacional das OS

A consulta `OSOperacional` mantém o status original do Tableau e cria uma coluna de ação:

- `COMP` → **FECHAR NO MÁXIMO**
- `APROG` → **COBRAR MECÂNICA**
- `FECHAR` → **SEM AÇÃO**
- qualquer outro valor → **REVISAR STATUS**

Também classifica a OS em mês atual, mês anterior ou anterior ao mês passado para facilitar o filtro que já é usado no dia a dia.
