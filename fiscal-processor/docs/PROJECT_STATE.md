# PROJECT_STATE — 2026-09-27

## Ref observada

- Repositório: `LuigiAPCPereira/test`
- Branch ativa deste produto: `feat/fiscal-processor-local-v0.1`
- Base: `main`
- Draft PR: #4 — `Bootstrap Fiscal Processor local-only architecture`
- Protótipo anterior: Draft PR #3 em `feat/nf-automation-m365-v0.3`; não é dependência e não foi mergeado.

## Fontes de processo

- `DOCUMENTATION_AND_CONTINUITY.md` versão 2.2 foi consultado a partir da cópia disponível no Project.
- `ENGINEERING_DNA.md` e `FRONTEND_DNA.md` disponíveis no Project foram consultados.
- A publicação editorial central no Notion não foi revalidada nesta execução; não afirmar sincronização dessa cópia com uma release Notion atual.
- `fiscal-processor/AGENTS.md` é o entrypoint local do subprojeto.

## Trilha PDF atual

**FP-003 — Adapter PDFium para texto + render**

Estado: **IMPLEMENTADA / VALIDADA PARCIALMENTE**.

Evidências:
- `pypdfium2==5.13.0` fixado no contrato do projeto;
- adapter isolado em `adapters/pdf/pdfium.py`;
- extração de texto e bounding boxes implementada;
- rasterização por DPI para buffer próprio em memória;
- testes unitários com doubles validam lifecycle, buffer, bounds, normalização e falhas;
- suíte local observada antes de FP-006: **24 PASS**;
- `compileall`: **PASS**;
- integração real com o wheel `pypdfium2`: **NÃO REVALIDADA** nesta sessão;
- tentativa de GitHub Actions gerou runs sem runner/steps; workflow removido.

## Trilha Excel paralela

**FP-006 — Adapter Excel idempotente**

Estado: **CONCLUÍDA / VALIDADA**.

Evidências:
- `openpyxl==3.1.5` pinado;
- workbook controlado `Controle_Notas_Fiscais.xlsx` com sheet `Notas Fiscais`;
- colunas técnicas ocultas: `_sha256`, `_extraction_mode`, `_parser_id`, `_processed_at`;
- SHA-256 é chave de upsert: mesma NF atualiza a mesma linha;
- `Número da OS`, `Validade` e `Observações` não entram no writer automático;
- save grava em temporário no mesmo diretório e usa `os.replace`;
- falha de replace preserva o arquivo anterior e limpa o temporário;
- workbook com contrato de cabeçalho desconhecido é recusado em vez de ser reescrito;
- **5/5 testes reais com openpyxl 3.1.5: PASS**;
- `compileall`: **PASS**.

Commit:
- `d2e829987c407b48ef28ba5f45ff30389e283c36`

## Desconhecidos relevantes

- Qualidade real do pypdfium2 em PDF sintético/real executado com a biblioteca instalada.
- Qual OCR vence o corpus fiscal.
- Se o executável não assinado passa pelas políticas da máquina corporativa.
- Toolkit visual final.
- Baseline real de performance.
- Necessidade futura de code signing.

## Próxima ação segura

Revalidar **FP-003** num ambiente com `pypdfium2==5.13.0` instalável, executando o smoke sintético real de texto + render.

FP-004 permanece bloqueada por esse gate. FP-006 não está bloqueada e já foi validada de forma independente.
