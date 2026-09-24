# TASKLIST — Controle de Notas Fiscais

| ID | Marco | Resultado | Estado | Depende de | Aceite/evidência |
| --- | --- | --- | --- | --- | --- |
| T-001 | M1 | Bootstrap documental e arquitetura inicial | validada | nenhuma | pacote v0.1/v0.2 + escopo da conversa |
| T-002 | M1 | Obter Solution não gerenciada real do tenant | validada | T-001 | `ControledenotasFiscais_1_0_0_1.zip`, Managed=0, publisher cnf |
| T-003 | M1 | Parametrizar referências e corrigir idempotência | validada | T-002 | import/runtime confirmados; mesma NF executada duas vezes sem criar segundo item |
| T-004 | M1 | Adicionar fluxo Cloud imediato por arquivo selecionado | validada | T-002 | 0.1.2.0 importada; fluxo apareceu em Integrar → Fluxos, executou e criou o item |
| T-005 | M2 | Validar engine de extração fiscal Cloud/Desktop | implementada não validada | T-003 | extração PDF validada; import Robin do PowerShell incompatível no tenant; parser `.ps1` + montagem manual documentados, execução pendente |
| T-006 | M2 | Mapear colunas fiscais reais da lista | bloqueada parcialmente | T-005 | rótulos visíveis conhecidos, mas nomes internos SharePoint ainda não confirmados; necessário antes de gerar `Atualizar item` definitivo |
| T-007 | M2 | Atualizar registro com campos fiscais sem tocar OS/validade | pendente | T-005,T-006 | smoke em NF de teste |
| T-008 | M3 | Criar Desktop flow parametrizado | pendente | T-006 | leitura local + parse + update idempotente |
| T-009 | M3 | Validar concorrência Cloud/Desktop | pendente | T-007,T-008 | execução simultânea não duplica e preserva campos manuais |
| T-010 | M4 | Teste final e pacote de implantação | pendente | T-009 | import + testes reais no ambiente corporativo |
