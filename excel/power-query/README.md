# Power Query — Controle de Frotas Nordeste

Arquivos auxiliares para evoluir a planilha sem alterar a lógica já funcional.

## Ordem sugerida de criação no Excel

1. `PreventivaRodante` — usar o arquivo `../PreventivaRodante_PowerQuery.m` já existente.
2. `ManoTer` — usar `ManoTer.m`.
3. `Medidor` — usar `Medidor.m`.
4. `QualidadeDados` — usar `QualidadeDados.m`.

## Carregamento recomendado

- `PreventivaRodante`: carregar em tabela em uma nova planilha **Preventiva Rodante**.
- `ManoTer`: carregar em tabela em uma nova planilha **Mano-Ter**.
- `Medidor`: carregar em tabela em uma nova planilha **Medidor**.
- `QualidadeDados`: carregar em tabela em uma nova planilha **Qualidade dos Dados**.

As consultas `ManoTer`, `Medidor` e `QualidadeDados` usam consultas já existentes no workbook e não precisam buscar novamente os arquivos do SharePoint.

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

## Regra de Mano/Ter

Para cada placa, a consulta considera:
- 02.01 — Manômetro Analógico Vertical
- 02.03 — Termômetro Analógico
- 02.04 — Manômetro Analógico Horizontal

A validade usada no PROCV/XLOOKUP é a **menor das três**, e `Documento mais próximo` informa qual item gerou a menor data. Empates são mostrados em conjunto.
