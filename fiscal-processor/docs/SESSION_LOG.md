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

## 2026-09-27 — FP-002 bootstrap Python

### Implementado
- `pyproject.toml` com pacote src-layout e dependências dev separadas.
- Domínio sem dependências externas.
- Enums explícitos: `DocumentType`, `ExtractionMode`, `ProcessingStatus`, `QualityFlag`.
- `FiscalExtraction` imutável para dados automáticos.
- `ManualFields` separado para OS, validade e observações.
- Validador de CNPJ com dígitos verificadores.
- Parsers determinísticos de data e BRL.
- Política de fixtures sintéticas/anonimizadas.
- Guia de gates locais em `docs/DEVELOPMENT.md`.

### Validação
- `pytest`: 16 testes, PASS.
- `compileall`: PASS.
- `ruff`: não executado; módulo ausente no ambiente.
- `mypy`: não executado; módulo ausente no ambiente.

### Evidência Git
- Commit funcional: `ab95f45045f7f4e6f813c5100e7914931350a4e5`.

## 2026-09-27 — FP-003 adapter PDFium

### Implementado
- Dependência `pypdfium2==5.13.0` pinada.
- Adapter local para abrir PDF, extrair texto Unicode, obter text objects/bounding boxes e rasterizar página por DPI.
- Buffer rasterizado é copiado antes de fechar o bitmap PDFium.
- OCR e parsing fiscal permanecem fora deste boundary.
- Teste de integração sintético preparado com PDF mínimo gerado em memória.
- Doubles locais adicionados para validar lifecycle, bounds, render e erros sem depender do wheel.

### Validação observada
- suíte local: 24 testes, PASS;
- `compileall`: PASS;
- instalação do wheel no container: indisponível por resolução de rede;
- GitHub Actions: runs criados, mas falharam antes de alocar runner/steps; logs do job não estavam disponíveis;
- workflow temporário removido para não tratar infraestrutura indisponível como resultado do código.

### Estado
FP-003 permanece **implementada / parcialmente validada** até smoke real com `pypdfium2` instalado.
