# VALIDATION_REPORT — Test Candidate 0.1.1.0

## Bug reproduzido no tenant
- Import da 0.1.0.0: concluído.
- Ativação do `NF - Processamento Imediato - Candidate`: FALHOU.
- Erro observado: a propriedade `recurrence` do trigger `Para_um_arquivo_selecionado` não estava definida/válida.
- Causa confirmada na definição gerada: trigger manual foi serializado como `OpenApiConnection`, tipo usado para triggers de polling.

## Correção 0.1.1.0
- trigger `Para_um_arquivo_selecionado`: `type = Request`.
- `kind = ApiConnection`.
- `operationId = ForASelectedFileHybridTrigger` no nível correto de `inputs`.
- binding da conexão via `$connections.shared_sharepointonline.connectionId`.
- nenhuma propriedade `recurrence` no trigger manual.

## Validação local
- ZIP integrity/open: PASS
- solution.xml parse: PASS
- customizations.xml parse: PASS
- workflow JSON parse: PASS (2 flows)
- environment variables present: PASS (5)
- selected-file trigger structural assertions: PASS
- broken literal `$filter: IDdoarquivo` absent: PASS
- SHA-256 do ZIP 0.1.1.0: `234a92e2bb203eecf8fd990446230eb880df2a6fb6de9d3a3e08eabf1be47b17`

## Ainda não validado
- update/import da 0.1.1.0 no tenant;
- ativação do fluxo imediato;
- execução real em arquivo selecionado;
- idempotência contra a lista SharePoint.

Resultado: IMPLEMENTADA NÃO VALIDADA.
