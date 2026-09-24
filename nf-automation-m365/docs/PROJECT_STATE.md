# PROJECT_STATE — 2026-09-24

- Fonte operacional: Solution unmanaged real do tenant `ControledenotasFiscais_1_0_0_1.zip`.
- Repositório: `LuigiAPCPereira/test`, `nf-automation-m365/`.
- T-003/T-004: VALIDADAS no tenant.
- T-005:
  - AI Builder bloqueado por ausência de créditos/capacidade.
  - extração nativa de texto no Power Automate Desktop VALIDADA em NF digital.
  - parser completo NF-e/NFS-e implementado.
  - primeira revisão do parser falhou no designer porque usava namespace interno incorreto `Scripting.RunPowershellScript.RunPowershellScript`.
  - correção aplicada: `System.RunPowershellScript`, ação nativa do PAD.
  - reexecução do parser corrigido no PAD: PENDENTE.
- T-006: nomes internos das colunas fiscais da lista SharePoint ainda não confirmados. Como o SharePoint é corporativo, o projeto não depende de conexão externa ao ChatGPT; o esquema será obtido por export/inspeção autorizada do Power Automate/SharePoint.
- Próxima ação: substituir o bloco antigo pelo parser corrigido e executar na NF de teste.
