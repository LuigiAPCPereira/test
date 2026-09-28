# PROJECT_STATE — 2026-09-27

## Ref observada

- Repositório: `LuigiAPCPereira/test`
- Branch ativa deste produto: `feat/fiscal-processor-local-v0.1`
- Base: `main`
- Protótipo anterior: Draft PR #3 em `feat/nf-automation-m365-v0.3`; não é dependência e não foi mergeado.

## Fontes de processo

- `DOCUMENTATION_AND_CONTINUITY.md` versão 2.2 foi consultado a partir da cópia disponível no Project.
- `ENGINEERING_DNA.md` e `FRONTEND_DNA.md` disponíveis no Project foram consultados.
- A publicação editorial central no Notion não foi revalidada nesta execução; não afirmar sincronização dessa cópia com uma release Notion atual.
- `fiscal-processor/AGENTS.md` é o entrypoint local do subprojeto.

## Tarefa atual

**FP-001 — Pesquisa local-only + arquitetura inicial**

Estado: **CONCLUÍDA / VALIDADA DOCUMENTALMENTE**.

Evidências:
- arquitetura local-only definida;
- SharePoint/Power Automate/LLM removidos do runtime alvo;
- PDF candidate selecionado por pesquisa: pypdfium2/PDFium;
- OCR permanece decisão experimental Tesseract vs RapidOCR;
- Excel operacional definido com SHA-256 oculto e preservação de campos manuais;
- frontend modelado por estados antes de toolkit;
- distribuição inicial definida como Windows `onedir` via CI.

## Desconhecidos relevantes

- Qual OCR vence o corpus fiscal.
- Se o executável não assinado passa pelas políticas da máquina corporativa.
- Toolkit visual final.
- Baseline real de performance.
- Necessidade futura de code signing.

## Próxima ação

**FP-002 — Bootstrap Python e contratos de domínio.**

Criar `pyproject.toml`, layout `src/`, modelos/estados sem dependência de infraestrutura, fixtures sintéticas mínimas e gates locais. Não iniciar GUI antes de o core processar documentos por teste.
