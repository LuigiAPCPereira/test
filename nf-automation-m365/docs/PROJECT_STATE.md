# PROJECT_STATE — 2026-09-24

- Fonte operacional recebida: `ControledenotasFiscais_1_0_0_1.zip` (Solution unmanaged real do tenant).
- Repositório de continuidade: `LuigiAPCPereira/test`, subpasta `nf-automation-m365/`.
- Tarefa atual: T-003/T-004.
- T-003: parametrização/idempotência implementada; validação de runtime pendente.
- T-004: primeira revisão 0.1.0.0 importou, mas não ativou por trigger manual serializado como `OpenApiConnection`.
- Correção atual: Test Candidate 0.1.1.0 com `For a selected file` como `Request + ApiConnection`.
- Validação local 0.1.1.0: ZIP íntegro, XML/JSON parseáveis e assertions estruturais do trigger PASS.
- Integração/runtime 0.1.1.0: não validada.
- Próxima ação: importar `dist/ControledenotasFiscais_TestCandidate_0_1_1_0.zip` sobre a Test Candidate existente e tentar ativar somente `NF - Processamento Imediato - Candidate`.
