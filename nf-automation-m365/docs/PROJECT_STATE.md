# PROJECT_STATE — 2026-09-24

- Fonte operacional: Solution unmanaged real do tenant `ControledenotasFiscais_1_0_0_1.zip`.
- Repositório: `LuigiAPCPereira/test`, `nf-automation-m365/`.
- Tarefa atual concluída: T-003/T-004.
- T-003: VALIDADA no tenant — parametrização/runtime funcionando e segunda execução da mesma NF não criou duplicata.
- T-004: VALIDADA no tenant — Test Candidate 0.1.2.0 importada, fluxo `NF - Processamento Imediato - Candidate` ativado, visível em `Integrar → Fluxos` e executado com sucesso.
- Evidência funcional observada pelo usuário: primeira execução criou registro na lista `Controle de Notas Fiscais`; segunda execução do mesmo PDF manteve apenas um registro.
- Campos fiscais continuam vazios por design; extração ainda não foi implementada.
- Próxima tarefa: T-005 — validar uma engine de extração fiscal capaz de obter data de emissão, emitente, número/série e valor em PDFs reais autorizados.
- PR/branch permanecem não integrados em `main`.
