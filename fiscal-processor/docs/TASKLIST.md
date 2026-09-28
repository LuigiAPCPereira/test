# TASKLIST — Fiscal Processor

| ID | Marco | Resultado | Estado | Depende de | Aceite/evidência |
| --- | --- | --- | --- | --- | --- |
| FP-001 | M0 | Pesquisa local-only + arquitetura inicial | validada documentalmente | nenhuma | PRODUCT/PRD/DESIGN/FRONTEND/RESEARCH/ADR-001 versionados; fontes técnicas verificadas |
| FP-002 | M1 | Bootstrap Python e contratos de domínio | validada parcialmente | FP-001 | pacote `src/` criado; modelos/estados tipados; validações CNPJ/data/valor; 16 testes unitários PASS; `compileall` PASS; ruff/mypy definidos mas não revalidados neste ambiente |
| FP-003 | M1 | Adapter PDFium para texto + render | implementada parcialmente validada | FP-002 | adapter pypdfium2 5.13.0 implementado; texto/caixas/render em memória cobertos por doubles; suíte local 24 PASS + compileall PASS; integração real pypdfium2 não revalidada porque o ambiente atual não instalou o wheel e o GitHub Actions não iniciou runner/steps |
| FP-004 | M2 | Benchmark OCR local | pendente | FP-003 | benchmark fiscal próprio inspirado no olmOCR-bench; comparar Tesseract e RapidOCR/ONNX; PaddleOCR como baseline técnico; relatório de exatidão/latência/tamanho e uma engine escolhida |
| FP-005 | M2 | Classificador + parsers NF-e/NFS-e | pendente | FP-003,FP-004 | NF-e e NFS-e sintéticas retornam campos/flags esperados; ausências não são inventadas |
| FP-006 | M3 | Adapter Excel idempotente | pendente | FP-002 | SHA-256 evita duplicata; OS/validade/observações preservados; save atômico |
| FP-007 | M3 | CLI end-to-end local | pendente | FP-005,FP-006 | pasta de entrada → processamento → workbook sem rede |
| FP-008 | M4 | Frontend desktop conforme FRONTEND_DNA | pendente | FP-007 | estados inicial/vazio/processando/parcial/sucesso/erro; teclado e foco visível |
| FP-009 | M4 | Pacote Windows portátil `onedir` | pendente | FP-008 | build Windows CI + smoke sem Python instalado e sem admin no caminho nominal |
| FP-010 | M5 | Gates de privacidade/performance/licenças | pendente | FP-007,FP-009 | egress bloqueado, notices empacotados, benchmark e logs mínimos verificados |
| FP-011 | M5 | Smoke em máquina corporativa autorizada | pendente | FP-009,FP-010 | execução real sem privilégio adicional, com documentos aprovados localmente; nenhuma cópia sai da máquina |

## Observações

- O protótipo M365 é histórico separado e não satisfaz tarefas deste produto.
- Metas numéricas de performance não serão inventadas antes de FP-004/FP-010.
- FP-011 depende de políticas reais da empresa; execução sem admin é hipótese até smoke.
