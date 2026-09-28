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

## 2026-09-27 — FP-002 bootstrap Python

### Implementado
- `pyproject.toml` com pacote src-layout e dependências dev separadas.
- Domínio sem dependências externas.
- Enums explícitos e ownership separado entre extração automática e campos manuais.
- Validador de CNPJ, datas e BRL.

### Validação
- `pytest`: 16 testes, PASS.
- `compileall`: PASS.
- `ruff`/`mypy`: não revalidados neste ambiente.

## 2026-09-27 — FP-003 adapter PDFium

### Implementado
- `pypdfium2==5.13.0` pinado.
- Texto, text objects/bounding boxes e renderização por DPI implementados.

### Validação observada
- suíte local com doubles: PASS;
- integração real do wheel: pendente;
- GitHub Actions não obteve runner/steps e foi removido como sinal não confiável.

### Estado
FP-003 permanece **implementada / parcialmente validada**.

## 2026-09-27 — FP-006 adapter Excel

### Implementado
- `openpyxl==3.1.5` pinado.
- Adapter `OpenpyxlInvoiceStore` com upsert por SHA-256.
- Campos manuais são fora do mapa de escrita automática.
- Colunas técnicas ficam ocultas.
- Save atômico usa arquivo temporário no mesmo diretório e `os.replace`.
- Contrato de cabeçalho divergente falha fechado.

### Validação real
Foram executados 5 testes com a biblioteca openpyxl instalada:
1. criação do workbook e ocultação das colunas técnicas;
2. mesma SHA atualiza a mesma linha;
3. reprocessamento preserva OS, validade e observações;
4. SHA diferente cria nova linha;
5. falha simulada no replace preserva o XLSX anterior e limpa temporário.

Resultado: **5/5 PASS**.  
`compileall`: **PASS**.

### Evidência Git
- `d2e829987c407b48ef28ba5f45ff30389e283c36`


## 2026-09-28 — FP-003 integração real e limites
- Base observada: 05d247e470931a8c0a38bb030c0fa4a19d3822e2, PR #4 Draft.
- Wheel pypdfium2 5.13.0 instalado; baseline 29 testes PASS.
- Acrescentados testes reais de DPI, página vazia, limites e buffer após close.
- Achado: ceil(points * (dpi / 72)) pode diferir um pixel de ceil(points * dpi / 72).
  Preflight e testes corrigidos para corresponder ao PDFium real.
- Limites configuráveis evitam rasterizações acima do orçamento e documentos extensos.
- 44 testes PASS; ruff/mypy/compileall PASS após correção das pendências de baseline.
- Protocolo: usuário informou COMPLETE; índice Notion STAGING está desatualizado.
- Próxima tarefa FP-004; runtime Windows e memória nativa de longa duração não validados.
- Commit: identificado no histórico pela mensagem FP-003: validate real PDFium integration and bound rendering.

## 2026-09-28 — FP-006 texto externo no Excel
- Teste real reproduziu fórmula involuntária em nome de arquivo/emitente/número iniciado com `=`.
- Writer agora força strings automáticas como texto XLSX, mantendo valor literal.
- Também fecha workbook quando validação de cabeçalho lança erro.
- Teste de regressão PASS junto às invariantes existentes; nenhum campo manual alterado.
- Commit: FP-006: keep extracted text literal in Excel cells.
