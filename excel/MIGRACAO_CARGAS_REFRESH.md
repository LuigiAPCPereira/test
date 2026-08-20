# Migração de cargas e refresh — Controle de Frotas Nordeste

Este documento registra o estado real encontrado no arquivo original `Controle_de_Frotas_Nordeste.xlsx` e a migração recomendada.

## Estado original confirmado

O arquivo possui 11 abas alimentadas por Power Query:

1. `ConsultarFrotasNordeste`
2. `SuasTrans`
3. `MaxTrack`
4. `Tableu`
5. `CIV`
6. `Crono`
7. `CIPP`
8. `TH`
9. `Medidores`
10. `Mássico`
11. `CRLV`

Todas as 11 consultas estão carregadas em tabelas do Excel. Portanto, as sete consultas documentais simples não são apenas referências internas: cada uma possui carga própria.

As conexões de `ConsultarFrotasNordeste`, `SuasTrans`, `MaxTrack` e `Tableu` estão configuradas no arquivo original com:

- atualização em segundo plano;
- `Atualizar ao abrir o arquivo`;
- intervalo automático de 60 minutos.

Isso cria três modos de refresh concorrentes: ao abrir, a cada hora e quando o usuário atualiza manualmente.

## Consultas simples antigas

A função original `FiltrarTidoDoc` filtra `SuasTrans` e devolve apenas `Placa | Validade`.

Ela alimenta:

- `CRLV` → 02.07
- `Mássico` → 02.02 Medidor Mássico
- `CIPP` → 02.05
- `TH` → 02.25
- `Crono` → 02.08
- `CIV` → 02.06
- `Medidores` → **somente 02.03 Termômetro Analógico**

O último ponto confirma o problema conceitual já identificado: `Medidores` não representa Mano/Ter; ele era apenas Termômetro.

## Arquitetura alvo

### Visíveis

- `Ações Operacionais`
- `Preventiva Rodante`
- `SuasTrans`
- `OS Operacional`
- `Atualização Mãe`
- `Qualidade dos Dados`

### Opcionais

- `Mano-Ter`
- `Medidor`

Essas duas páginas só devem permanecer se os segmentadores específicos forem realmente úteis. A `Atualização Mãe` já contém `Medidor`, `Mano/Ter` e `Documento Mano/Ter mais próximo`.

### Somente conexão / staging

Após validação:

- `ConsultarFrotasNordeste`
- `MaxTrack` — se não houver necessidade de página própria
- `Tableu`
- `DocumentosOperacionais`
- `ResumoOperacional`

`SuasTrans` continua visível porque é usada operacionalmente para filtros e prints.

## Migração segura

### Fase A — comparação

Manter tudo que existe e adicionar:

- `AtualizacaoMae`
- `ManoTer`
- `Medidor`
- `OSOperacional`
- `AcoesOperacionais`
- `QualidadeDados`

Comparar resultados antes de remover cargas.

### Fase B — substituir as sete consultas documentais simples

Quando `AtualizacaoMae` estiver validada, deixar de carregar:

- CIV
- Crono
- CIPP
- TH
- Medidores
- Mássico
- CRLV

A consulta `AtualizacaoMae` passa a ser a tabela única para PROCV/XLOOKUP desses campos.

### Fase C — staging do Tableau

Depois de validar `OSOperacional` contra a página atual:

- manter a **consulta** `Tableu`;
- retirar apenas a carga/aba `Tableu`;
- usar `OSOperacional` como página visível.

Não excluir a consulta `Tableu`, pois `OSOperacional` depende dela.

### Fase D — política de refresh

Como os arquivos-fonte são exportados e adicionados periodicamente pelo usuário, o fluxo recomendado é um refresh deliberado:

1. colocar os novos arquivos nas pastas;
2. abrir a pasta de trabalho;
3. executar `Atualizar Tudo` uma vez;
4. aguardar o término;
5. trabalhar com os dados já consolidados.

Depois da validação, recomenda-se desativar `Atualizar a cada 60 minutos` nas quatro consultas-base. Isso evita atualizações inesperadas durante o uso.

`Atualizar ao abrir` também pode ser desativado se o fluxo manual acima for adotado. O importante é evitar manter ao mesmo tempo atualização ao abrir + intervalo horário + refresh manual sem necessidade operacional.

## Resultado esperado

A redução de tempo não depende apenas de deixar abas ocultas. O ganho vem de:

- parar de carregar sete filtros documentais redundantes;
- reduzir avaliações repetidas de `SuasTrans`;
- remover refresh automático desnecessário;
- posteriormente substituir `SharePoint.Files` por navegação direta à pasta com `SharePoint.Contents`.

A última etapa depende dos caminhos SharePoint exatos retornados por `DiagnosticoPastasSharePoint.m`.
