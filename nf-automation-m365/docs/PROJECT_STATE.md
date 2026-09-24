# PROJECT_STATE — 2026-09-24

- Fonte operacional: Solution unmanaged real do tenant `ControledenotasFiscais_1_0_0_1.zip`.
- Repositório: `LuigiAPCPereira/test`, `nf-automation-m365/`.
- T-003/T-004: VALIDADAS no tenant.
- T-005:
  - AI Builder `Processar faturas`: indisponível por ausência de créditos/capacidade.
  - Power Automate Desktop: extração nativa de texto de PDF digital VALIDADA.
  - Evidência visual: texto extraído contém número da NF `004.241.885`, série `99`, fornecedor `BAHIANA DISTRIBUIDORA DE GAS LTDA`, CNPJ `46.395.687/0004-55` e valor total da nota `112.000,00`.
- Próxima ação: criar parser no Desktop com ações de texto/regex para transformar `ExtractedPDFText` em campos estruturados, começando por NúmeroNF, Série, CNPJPrestadora, EmpresaPrestadora e Valor.
- OCR permanece fallback para PDFs sem camada de texto.
