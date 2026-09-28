# SESSION_LOG — Fiscal Processor

## 2026-09-27 — Pivot do protótipo M365 para produto local-only

### Evidência recuperada
- Protótipo Power Automate demonstrou extração correta em NF-e textual.
- Outro PDF/NFS-e retornou texto vazio e expôs a necessidade de rasterização/OCR.
- AI Builder não possuía capacidade no tenant testado.
- Usuário decidiu não depender de SharePoint/conta corporativa e exige que dados fiscais não sejam enviados a LLM/serviço externo.

### Decisão
Criar produto separado em Python, local-only, com saída Excel e distribuição Windows portátil.

### Pesquisa
- PyMuPDF: AGPL/comercial; não selecionado como base da v0.1.
- pypdfium2/PDFium: licenças permissivas e APIs para texto/render; selecionado para POC.
- Tesseract: Apache-2.0, português e operação local.
- RapidOCR: Apache-2.0, offline, modelos PP-OCRv6 com português; benchmark necessário.
- openpyxl: MIT e suporta leitura/escrita de XLSX; selecionado para POC.
- PyInstaller: gera bundle standalone, não é cross-compiler; `onedir` escolhido inicialmente.
- GUI: decisão adiada; contrato de Frontend DNA documentado antes do framework.

### Continuidade
- Branch criada a partir de `main`: `feat/fiscal-processor-local-v0.1`.
- Protótipo M365 permanece isolado no Draft PR #3.
- Próxima tarefa: FP-002.
