# PROJECT_STATE — 2026-09-24

- T-003/T-004: VALIDADAS no tenant.
- T-005:
  - AI Builder bloqueado por falta de créditos/capacidade.
  - extração nativa de texto PDF no PAD VALIDADA.
  - parser fiscal completo mantido em `desktop/NF_Parser_Completo.ps1`.
  - tentativas de importar a ação PowerShell por Robin falharam com identificadores internos `Scripting.RunPowershellScript` e `System.RunPowershellScript`.
  - estratégia compatível com o tenant: adicionar manualmente a ação visual **Executar script do PowerShell** e colar o conteúdo do `.ps1`.
  - instruções: `desktop/PAD_MANUAL_SETUP.md`.
  - execução real do parser: PENDENTE.
- SharePoint corporativo não será conectado ao ChatGPT; esquema será obtido por export/inspeção autorizada.
- Próxima ação: montar as ações 3–7 conforme `PAD_MANUAL_SETUP.md` e executar na NF já usada no teste.

- Correção adicional: removida dependência da área de transferência. `NF_Parser_Completo.ps1` agora recebe `%ExtractedPDFText%` diretamente dentro da ação PowerShell, conforme suporte oficial do PAD a variáveis em scripting actions.
