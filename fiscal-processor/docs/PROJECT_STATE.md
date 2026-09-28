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

## Tarefa atual

**FP-002 — Bootstrap Python e contratos de domínio**

Estado: **CONCLUÍDA / VALIDADA PARCIALMENTE**.

Evidências:
- `pyproject.toml` criado com Python 3.11+ e gates dev explícitos;
- pacote `src/fiscal_processor/` criado;
- estados explícitos para tipo de documento, modo de extração, processamento e quality flags;
- `FiscalExtraction` separado de `ManualFields`, preservando ownership de OS/validade/observações;
- validação determinística de CNPJ com dígitos verificadores;
- parsing de datas suportadas e valores monetários BRL;
- `tests/fixtures/README.md` proíbe dados corporativos reais no repositório;
- 16 testes unitários executados: **PASS**;
- `python -m compileall -q src`: **PASS**;
- `ruff` e `mypy`: **DOCUMENTADOS MAS NÃO REVALIDADOS** nesta sessão porque os módulos não estavam instalados no ambiente de execução.

Commit de implementação:
- `ab95f45045f7f4e6f813c5100e7914931350a4e5`

## Desconhecidos relevantes

- Qual OCR vence o corpus fiscal.
- Qualidade real do pypdfium2 nos layouts fiscais do domínio.
- Se o executável não assinado passa pelas políticas da máquina corporativa.
- Toolkit visual final.
- Baseline real de performance.
- Necessidade futura de code signing.

## Próxima ação

**FP-003 — Adapter PDFium para texto + render.**

Implementar boundary PDF sem OCR:
1. abrir PDF por pypdfium2;
2. extrair texto e caixas por página;
3. rasterizar página para memória;
4. criar fixtures sintéticas de PDF textual;
5. testar erro/corrupção e páginas sem texto;
6. não introduzir OCR ainda.
