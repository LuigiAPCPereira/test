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

**FP-003 — Adapter PDFium para texto + render**

Estado: **IMPLEMENTADA / VALIDADA PARCIALMENTE**.

Evidências:
- `pypdfium2==5.13.0` fixado no contrato do projeto;
- adapter isolado em `adapters/pdf/pdfium.py`;
- extração de texto inteiro via `get_text_bounded()`;
- extração de objetos de texto e bounding boxes;
- normalização de quebras CRLF;
- rasterização por DPI para buffer próprio em memória;
- erros de abertura/render encapsulados em `PdfAdapterError`;
- testes unitários com doubles validam lifecycle, cópia de buffer, bounds, normalização e falhas;
- suíte local completa: **24 PASS**;
- `compileall`: **PASS**;
- integração real com o wheel `pypdfium2`: **NÃO REVALIDADA** nesta sessão;
- tentativa de GitHub Actions gerou runs sem runner/steps e sem logs recuperáveis; workflow removido para não manter sinal falso de CI.

Commits relevantes:
- `fd8b36d74bb261e367969c8f302037071c028ea6` — adapter + teste de integração sintético;
- `81000b5f9eaf6275ca4568432bbe025f583c9365` — cobertura local com doubles;
- `b573a560f3c68eef345b623f7e7044d072cdceae` — remoção do workflow indisponível.

## Desconhecidos relevantes

- Qualidade real do pypdfium2 em PDFs fiscais reais/sintéticos executados com a biblioteca instalada.
- Qual OCR vence o corpus fiscal.
- Se o executável não assinado passa pelas políticas da máquina corporativa.
- Toolkit visual final.
- Baseline real de performance.
- Necessidade futura de code signing.

## Próxima ação segura

**Revalidar FP-003 num ambiente com `pypdfium2==5.13.0` instalável**, executando o teste sintético real de texto + render.

Somente após esse smoke, promover FP-003 para validada e iniciar FP-004 como benchmark OCR dependente do adapter real.
