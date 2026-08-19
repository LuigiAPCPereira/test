# Power Query — Controle de Frotas Nordeste

Consultas auxiliares para evoluir a planilha sem substituir o que já funciona antes de validar no Excel corporativo.

## Ordem de criação no Excel

1. `PreventivaRodante` — `../PreventivaRodante_PowerQuery.m`
2. `ManoTer` — `ManoTer.m`
3. `Medidor` — `Medidor.m`
4. `OSOperacional` — `OSOperacional.m`
5. `DocumentosOperacionais` — `DocumentosOperacionais.m`
6. `AcoesOperacionais` — `AcoesOperacionais.m`
7. `QualidadeDados` — `QualidadeDados.m`

A ordem importa porque as consultas finais reaproveitam as anteriores.

## Carregamento recomendado na primeira validação

- `PreventivaRodante`: tabela em uma nova aba **Preventiva Rodante**.
- `ManoTer`: tabela em uma nova aba **Mano-Ter**.
- `Medidor`: tabela em uma nova aba **Medidor**.
- `AcoesOperacionais`: tabela em uma nova aba **Ações Operacionais**.
- `QualidadeDados`: tabela em uma nova aba **Qualidade dos Dados**.
- `OSOperacional`: inicialmente **somente conexão**; a aba Tableau atual continua preservada.
- `DocumentosOperacionais`: inicialmente **somente conexão**; a aba SuasTrans atual continua preservada.

Dessa forma a implementação nova pode ser comparada com as telas atuais sem quebrar o processo que já é usado no dia a dia.

## Dependências

- `PreventivaRodante` → planilha mãe no SharePoint + `MaxTrack`.
- `ManoTer` → `ConsultarFrotasNordeste` + `SuasTrans`.
- `Medidor` → `ConsultarFrotasNordeste` + `SuasTrans`.
- `OSOperacional` → `Tableu`.
- `DocumentosOperacionais` → `SuasTrans`.
- `AcoesOperacionais` → `PreventivaRodante` + `DocumentosOperacionais` + `OSOperacional`.
- `QualidadeDados` → bases existentes e consultas novas.

## Ações Operacionais

`AcoesOperacionais` é a fila única do que merece atenção. Ela não substitui as páginas específicas; serve para responder rapidamente **o que precisa de ação**.

Ela reúne:

- preventiva rodante fora de `OK`;
- documentos `Vencido`, `Expirando` ou com dados inconsistentes;
- OS `APROG`, `COMP` ou com status não reconhecido.

`FECHAR` e documentos válidos não poluem a fila.

Mano/Ter e Medidor não são adicionados novamente como categorias separadas na fila, porque os mesmos vencimentos já existem na documentação SuasTrans. As consultas específicas continuam sendo a fonte prática para o PROCV/XLOOKUP na planilha mãe.

### Segmentadores recomendados — Ações Operacionais

- `NUCLEO`
- `PRIORIDADE`
- `CATEGORIA`
- `AÇÃO`
- `SITUAÇÃO`
- `MÊS-ANO`
- `PLACA`

## Preventiva Rodante

Segmentadores:

- `Núcleo`
- `Situação Geral`
- `Faixa KM`
- `Mês-Ano`
- `Integridade`
- `Placa`

A classificação considera KM e data. A tolerância de 2.000 km não é usada para inventar o próximo KM: a consulta usa o `KM Próx. Prev.` oficial da planilha mãe e compara com o KM atual do MaxTrack.

## Mano/Ter

Segmentadores:

- `NUCLEO`
- `Status`
- `Documento mais próximo`
- `Prioridade`
- `Mês-Ano`
- `Placa`

Para cada placa são considerados:

- 02.01 — Manômetro Analógico Vertical
- 02.03 — Termômetro Analógico
- 02.04 — Manômetro Analógico Horizontal

A validade usada no PROCV/XLOOKUP é a **menor das três**. `Documento mais próximo` informa qual item originou essa data e exibe empates em conjunto.

## Medidor

`Medidor` representa exclusivamente:

- 02.02 — Calibração — Medidor Mássico

Mantém uma linha por placa e sinaliza ausência ou duplicidade.

## OS Operacional

Mantém o status original do Tableau e acrescenta a ação:

- `COMP` → **FECHAR NO MÁXIMO**
- `APROG` → **COBRAR MECÂNICA**
- `FECHAR` → **SEM AÇÃO**
- qualquer outro valor → **REVISAR STATUS**

Também classifica a OS em mês atual, mês anterior ou anterior ao mês passado.

## Documentos Operacionais

Mantém o status produzido por `SuasTrans` e acrescenta:

- dias para vencer;
- ação operacional;
- período de validade;
- mês-ano;
- integridade do registro.

A consulta aceita pequenas variações de nome/capitalização das colunas da base existente.

## Qualidade dos Dados

É uma tabela de **exceções**, não um dashboard. Quando tudo estiver consistente, deve ficar vazia ou quase vazia.

Ela verifica:

- placa sem KM no MaxTrack;
- placa duplicada no MaxTrack;
- ausência dos 9 tipos documentais esperados por placa;
- documento duplicado no SuasTrans;
- problemas de Mano/Ter;
- problemas de Medidor;
- dados insuficientes da Preventiva Rodante;
- campos documentais inválidos;
- OS fora do fluxo conhecido.

## Princípio de segurança

Nenhuma consulta nova deve substituir uma página existente antes do primeiro `Atualizar Tudo` ser validado no Excel conectado ao SharePoint. A migração é incremental: primeiro comparar, depois substituir somente o que realmente melhorar o trabalho.
