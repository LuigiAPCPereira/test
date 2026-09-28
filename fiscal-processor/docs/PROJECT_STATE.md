# PROJECT_STATE — 2026-09-28 UTC

## Ref observada e escopo
- Repositório: LuigiAPCPereira/test
- Branch: feat/fiscal-processor-local-v0.1; Draft PR #4; sem merge.
- HEAD recuperado: 05d247e470931a8c0a38bb030c0fa4a19d3822e2.
- Snapshot dos 32 arquivos do PR recuperado pelo plugin GitHub. Clone indisponível por autenticação; não há alegação de checkout Git local completo.
- Escopo: Fiscal Processor local-only, separado do PR #3/M365.

## Fontes
AGENTS.md do subprojeto lido na ref exata; AGENTS.md raiz retornou 404.
Protocolo 2.2 e DNAs dos anexos consultados. Índice Notion retornou STAGING,
mas o usuário corrigiu explicitamente em 2026-09-27: estado atual COMPLETE;
Notion desatualizado. COMPLETE é informação do usuário; equivalência integral
entre cópias não foi certificada nesta sessão. Não se trata de nova adoção.

## FP-003 — validada no Linux
pypdfium2 5.13.0 instalado e executado com Python 3.12 Linux x86_64.
44 testes PASS, incluindo integração real de texto, caixas, render em cinco
DPIs, página sem texto, PDF inválido, buffer independente após close e limites.
Limites configuráveis: 500 páginas e 40 milhões de pixels; DPI inteiro 1–600.
Dimensionamento usa a mesma ordem de operações float do PDFium: ceil(points * scale).
Ruff check/format, mypy src e compileall PASS. FP-002 também teve gates revalidados.
FP-006 mantém seis testes reais PASS, incluindo texto externo como literal (sem fórmula).

## Limites de evidência
Não há prova de ausência de todos os vazamentos nativos; limites de pixels não
são sandbox nem timeout de PDF malicioso. Windows, máquina corporativa,
OCR e desempenho do produto completo não validados.

## Próxima ação
FP-004: implementar corpus/benchmark OCR local e comparar engines por campos.
FP-005 depende da escolha por evidência em FP-004; GUI/build aguardam core.
