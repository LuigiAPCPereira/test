# Power Query — Controle de Frotas Nordeste

Consultas auxiliares para evoluir a planilha sem substituir o que já funciona antes de validar no Excel corporativo.

## Ordem de criação no Excel

1. `PreventivaRodante` — `../PreventivaRodante_PowerQuery.m`
2. `ManoTer` — `ManoTer.m`
3. `Medidor` — `Medidor.m`
4. `OSOperacional` — `OSOperacional.m`
5. `DocumentosOperacionais` — `DocumentosOperacionais.m`
6. `AcoesOperacionais` — `AcoesOperacionais.m`
7. `ResumoOperacional` — `ResumoOperacional.m`
8. `QualidadeDados` — `QualidadeDados.m`

A ordem importa porque as consultas finais reaproveitam as anteriores.

A especificação de layout está em `../CAMADA_VISUAL.md`.

## Carregamento recomendado na primeira validação

- `PreventivaRodante`: tabela em uma nova aba **Preventiva Rodante**.
- `ManoTer`: tabela em uma nova aba **Mano-Ter**.
- `Medidor`: tabela em uma nova aba **Medidor**.
- `AcoesOperacionais`: tabela em uma nova aba **Ações Operacionais**.
- `QualidadeDados`: tabela em uma nova aba **Qualidade dos Dados**.
- `OSOperacional`: inicialmente **somente conexão** ou aba separada para comparação.
- `DocumentosOperacionais`: **somente conexão**.
- `ResumoOperacional`: **somente conexão**; alimenta a camada visual da aba Ações Operacionais.

## Dependências

- `PreventivaRodante` → planilha mãe no SharePoint + `MaxTrack`.
- `ManoTer` → `SuasTrans`.
- `Medidor` → `SuasTrans`.
- `OSOperacional` → consulta `Tableu`.
- `DocumentosOperacionais` → `SuasTrans`.
- `AcoesOperacionais` → `PreventivaRodante` + `DocumentosOperacionais` + `OSOperacional`.
- `ResumoOperacional` → `AcoesOperacionais`.
- `QualidadeDados` → bases existentes e consultas novas.

## Importante: consulta não é a mesma coisa que aba

`OSOperacional` usa a **consulta Power Query** chamada `Tableu` como fonte. Ela não precisa da aba carregada `Tableu` para funcionar.

Depois da validação é possível deixar a consulta `Tableu` como **Somente Criar Conexão** e usar apenas `OSOperacional` como página visível. O que não pode ser feito é excluir a consulta `Tableu`, porque isso quebraria a dependência.

O mesmo princípio vale para outras consultas auxiliares.

## Desempenho

As bases finais são pequenas; a demora não vem do agrupamento de 57 placas ou de algumas centenas de documentos.

A arquitetura original usa `SharePoint.Files(...)` em várias consultas. Essa função pode enumerar muitos arquivos do site antes de aplicar o filtro de pasta. Além disso, uma consulta derivada pode provocar reavaliações das consultas-pai durante o refresh.

`Medidor` e `ManoTer` foram simplificadas para:

- usar apenas `SuasTrans` como fonte operacional;
- obter NUCLEO, Filial e Frota diretamente da SuasTrans;
- materializar a pequena base normalizada com `Table.Buffer` antes de reutilizá-la dentro da própria consulta.

Isso elimina a dependência adicional de `ConsultarFrotasNordeste` nessas duas consultas e deve reduzir bastante o custo de atualização delas.

A próxima otimização de desempenho deve ocorrer na **fonte**, trocando a enumeração ampla do SharePoint por navegação direta à pasta/biblioteca quando o caminho exato estiver validado no Excel corporativo.

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
- `MÊS-ANO`
- `PLACA`

## Resumo Operacional

`ResumoOperacional` gera uma linha por núcleo e uma linha `TOTAL` com os principais contadores da fila de ações:

- total de ações;
- urgentes;
- preventivas;
- documentos;
- OS;
- fechar no Máximo;
- cobrar mecânica;
- regularizar documento;
- programar renovação;
- programar preventiva.

Essa consulta é apoio visual e deve ficar como **somente conexão**.

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

Mantém uma linha por placa e sinaliza ausência ou duplicidade. NUCLEO, Filial e Frota são lidos diretamente da base SuasTrans para evitar a incompatibilidade `Núcleo` x `NUCLEO` observada anteriormente.

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

## Qualidade dos Dados

É uma tabela de **exceções**, não um dashboard. Quando tudo estiver consistente, deve ficar vazia ou quase vazia.

Ela verifica ausência/duplicidade de KM, documentos esperados, Mano/Ter, Medidor, Preventiva Rodante e status de OS fora do fluxo conhecido.

## Princípio de segurança

Nenhuma consulta nova deve substituir uma página existente antes do primeiro `Atualizar Tudo` ser validado no Excel conectado ao SharePoint. A migração é incremental: primeiro comparar, depois substituir somente o que realmente melhorar o trabalho.
