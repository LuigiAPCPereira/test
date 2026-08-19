# Validação no Excel — Controle de Frotas Nordeste

Este roteiro deve ser usado no primeiro teste real com o Excel conectado ao SharePoint corporativo.

## Objetivo

Validar as consultas novas sem substituir as abas atuais antes de termos evidência de que o refresh e os relacionamentos estão corretos.

## Preparação

1. Faça uma cópia do arquivo de controle atual.
2. Abra **Dados → Consultas e Conexões**.
3. Crie as consultas novas na ordem definida em `power-query/README.md`.
4. Mantenha `OSOperacional` e `DocumentosOperacionais` como **Somente conexão** no primeiro teste.
5. Carregue em novas abas apenas `PreventivaRodante`, `ManoTer`, `Medidor`, `AcoesOperacionais` e `QualidadeDados`.
6. Execute **Atualizar Tudo**.

## Critérios de aceite

### PreventivaRodante

- Deve existir exatamente uma linha para cada placa da frota Nordeste.
- `Placa` não deve ficar vazia.
- `KM Atual` deve vir do MaxTrack.
- `KM Últ. Prev.`, `KM Próx. Prev.` e `Data Próx. Prev.` devem vir da planilha mãe.
- `KM Restante = KM Próx. Prev. - KM Atual`.
- Uma preventiva com `KM Restante <= 2.000` deve estar, no mínimo, em `PROGRAMAR`.
- Uma preventiva com KM já ultrapassado, mas ainda dentro de 2.000 km, deve aparecer como `VENCIDA - tolerância`.
- Uma preventiva ultrapassada em mais de 2.000 km deve aparecer como `CRÍTICA - fora tolerância`.
- O status por data também deve participar da `Situação Geral`.
- `Dias para a data` deve ser número inteiro, nunca formato de data.

### ManoTer

- Deve existir exatamente uma linha por placa.
- `Validade Mano/Ter` deve ser a menor data entre 02.01, 02.03 e 02.04.
- `Documento mais próximo` deve indicar qual dos três gerou a menor data.
- Em empate, os documentos devem aparecer juntos.
- Se um dos três documentos estiver ausente, a placa não pode desaparecer; `Integridade` deve sinalizar o problema.
- Se houver duplicidade, `Integridade` deve sinalizar o problema.

### Medidor

- Deve existir exatamente uma linha por placa.
- Deve considerar somente 02.02 — Medidor Mássico.
- Ausência e duplicidade devem ser sinalizadas em `Integridade`.

### OSOperacional

Comparar com a aba Tableau atual:

- `COMP` → `FECHAR NO MÁXIMO`.
- `APROG` → `COBRAR MECÂNICA`.
- `FECHAR` → `SEM AÇÃO`.
- Nenhuma linha deve mudar o `STATUS` original.
- `PERÍODO` deve separar mês atual, mês anterior e datas mais antigas.

### DocumentosOperacionais

Comparar com a aba SuasTrans atual:

- `VENCIDO` → `REGULARIZAR DOCUMENTO`.
- `EXPIRANDO` → `PROGRAMAR RENOVAÇÃO`.
- `VÁLIDO` → `SEM AÇÃO`.
- A validade e o status originais da consulta SuasTrans devem ser preservados.
- `DIAS PARA VENCER` deve ser inteiro.

### AcoesOperacionais

A fila integrada deve conter somente itens que merecem atenção:

- preventiva diferente de `OK`;
- documento vencido, expirando ou inconsistente;
- OS APROG, COMP ou com status inesperado.

Não deve conter:

- OS `FECHAR`;
- documento `VÁLIDO` sem problema;
- preventiva `OK`.

Os filtros principais devem funcionar por `NUCLEO`, `PRIORIDADE`, `CATEGORIA`, `AÇÃO`, `SITUAÇÃO`, `MÊS-ANO` e `PLACA`.

### QualidadeDados

- Deve ser tratada como tabela de exceções.
- Se estiver vazia, isso é um resultado bom.
- Toda placa ausente no MaxTrack deve aparecer.
- Toda duplicidade de placa no MaxTrack deve aparecer.
- Para cada placa, os nove códigos documentais esperados devem existir uma vez: 02.01, 02.02, 02.03, 02.04, 02.05, 02.06, 02.07, 02.08 e 02.25.
- Ausências ou duplicidades documentais devem aparecer com placa e núcleo.
- Preventiva com dados insuficientes deve aparecer.
- OS com status fora do fluxo conhecido deve aparecer.

## Amostras para conferência manual

Antes de aprovar a migração, escolha pelo menos:

- 1 placa de Salvador/NUC Bahia;
- 1 placa de outro núcleo;
- 1 documento vencido;
- 1 documento expirando;
- 1 OS APROG;
- 1 OS COMP, se houver;
- 1 preventiva próxima de 2.000 km, se houver.

Compare cada caso diretamente com a fonte e com as abas antigas.

## Depois do aceite

Somente depois de o `Atualizar Tudo` passar sem erro e as amostras baterem com as fontes é que vale criar os segmentadores definitivos e decidir se `OSOperacional`/`DocumentosOperacionais` substituem alguma visão atual.
