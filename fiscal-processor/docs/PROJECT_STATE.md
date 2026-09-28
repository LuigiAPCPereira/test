# PROJECT_STATE — 2026-09-28 UTC

## Ref observada e escopo
- Repositório: LuigiAPCPereira/test
- Branch: feat/fiscal-processor-local-v0.1; Draft PR #4; sem merge.
- HEAD inicial recuperado: 05d247e470931a8c0a38bb030c0fa4a19d3822e2.
- Commits publicados: 1de8841 (FP-003), 6b7605f (FP-006), f08cef7 (FP-004 inicial).
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

## FP-004 — implementada / parcialmente validada
Benchmark local com corpus sintético, degradações, scorer exato, hashes pinados,
checkpoint por amostra e três engines executadas (135 amostras ao todo).
Small 476/480 campos (60 casos); medium 120/120 (15 casos/150 DPI);
Tesseract 459/480 (60 casos). Comparação comum/limites em RESEARCH-003.
52 testes PASS + ruff check/format/mypy/compileall PASS no conjunto final.
Small permanece candidato, sem seleção final nem runtime OCR do produto.

## FP-004 — ampliação espacial
Corpus espacial executado: seis documentos/sete páginas por motor a 200 DPI;
small, medium e Tesseract 48/48 verificações cada; nativo também 48/48.
Inclui dez ausências esperadas. Relatório RESEARCH-004 e JSON versionados.
58 testes PASS; Ruff check/format, mypy e compileall PASS.

## FP-004 — avaliador local por manifesto
Implementado `benchmarks.local_run`: schema restrito, caminhos contidos, gabarito
separado da extração, relatórios sem valores/caminhos, saída exclusiva e checkpoint.
69 testes PASS; gates estáticos PASS. Smoke nativo e Tesseract sintéticos 48/48 cada.
Guia operacional em LOCAL_CORPUS.md. Isto habilita a coleta de evidência externa,
mas não equivale a corpus independente validado.

## Decisão atual — ADR-002
Usuário autorizou small provisório e testes representativos após pacote Windows:
PC corporativo sem Python; não possui corpus equivalente no PC pessoal.
Foto de NFS-e fornecida como referência visual; nenhum dado real versionado.
FP-004 parcial deixa de bloquear implementação, sem declarar validação concluída.

## FP-005 — primeiro parser determinístico
`parsers.parse_invoice` recebe linhas em ordem de leitura e metadados; não importa
PDF/OCR nem filesystem. DANFE com labels explícitos e NFS-e com contexto de
prestador/tomador. Número/série combinados, data/hora, CNPJ com dígitos verificadores,
valor monetário estrito; ausência/duplicidade/invalidez gera REVIEW e campo vazio.
83 testes PASS no Linux, incluindo PDFium real → parser.
Não suporta ainda tabelas achatadas, remontagem espacial, OCR integrado ou layouts
municipais em geral. Foto de referência não foi processada pela engine.

## CI
Workflow `.github/workflows/fiscal-processor-ci.yml`: PR/push/manual, Python 3.12,
Ubuntu 24.04 e Windows 2022; Ruff, mypy, pytest, compileall e build wheel.
Actions fixadas em SHA, permissão contents:read, sem secrets/deploy/documentos reais.
Execução remota ainda deve ser consultada no commit publicado; configuração não
é prova de CI verde. Wheel não é pacote portátil Windows.

## Próxima ação
FP-005: integrar caixas/ordem de leitura ao parser e adapter OCR small local;
depois FP-007 (processamento PDF→Excel e CLI). Consultar CI e corrigir falhas reais.
Validação corporativa mantém sequência ADR-002, sem exigir Python do usuário.
