# PROJECT_STATE — 2026-09-24

- Fonte operacional: Solution unmanaged real do tenant `ControledenotasFiscais_1_0_0_1.zip`.
- Repositório: `LuigiAPCPereira/test`, `nf-automation-m365/`.
- T-003/T-004: VALIDADAS no tenant.
- T-005:
  - AI Builder bloqueado por ausência de créditos/capacidade.
  - extração nativa de texto no Power Automate Desktop VALIDADA em NF digital.
  - parser completo NF-e/NFS-e IMPLEMENTADO, ainda não validado em múltiplos PDFs: `desktop/NF_Parser_Completo_Apos_Extracao.robin`.
  - parser retorna objeto `NF` com NumeroNF, Serie, DataEmissao, EmpresaPrestadora, CNPJPrestadora, EmpresaTomadora, ValorLiquido e campos normalizados.
- T-006: nomes internos das colunas fiscais da lista SharePoint ainda DESCONHECIDOS; não devem ser inferidos.
- Próxima ação: colar o bloco Robin após `ExtractedPDFText` e executar em uma NF-e e uma NFS-e; em paralelo, obter esquema real da lista para fechar a gravação automática.
