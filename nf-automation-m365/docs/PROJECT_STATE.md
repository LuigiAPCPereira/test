# PROJECT_STATE — 2026-09-24

- Fonte operacional: Solution unmanaged real do tenant `ControledenotasFiscais_1_0_0_1.zip`.
- Repositório: `LuigiAPCPereira/test`, `nf-automation-m365/`.
- T-003/T-004: VALIDADAS no tenant (fluxo imediato, SharePoint menu e idempotência).
- Tarefa atual: T-005 — validar engine de extração fiscal.
- Teste Cloud/AI Builder: ação `Processar faturas` existe no designer, mas a execução falhou por ausência de capacidade de Crédito do Copilot ou créditos do AI Builder no ambiente.
- Não foi ativado trial, compra ou alteração de licenciamento.
- Decisão operacional atual: não depender de AI Builder; próximo teste é Power Automate Desktop com extração nativa de texto de PDF.
- Próxima ação: criar um fluxo Desktop mínimo `Selecionar PDF → Extrair texto do PDF → Exibir texto` usando uma NF digital de teste.
