# TASKLIST — Fiscal Processor

| ID | Marco | Resultado | Estado | Depende de | Aceite/evidência |
| --- | --- | --- | --- | --- | --- |
| FP-001 | M0 | Pesquisa local-only + arquitetura inicial | validada documentalmente | nenhuma | PRODUCT/PRD/DESIGN/FRONTEND/RESEARCH/ADR-001 versionados; fontes técnicas verificadas |
| FP-002 | M1 | Bootstrap Python e contratos de domínio | validada no Linux | FP-001 | pacote `src/` criado; modelos/estados tipados; validações CNPJ/data/valor; 16 testes unitários PASS; `compileall` PASS; ruff/mypy definidos mas não revalidados neste ambiente |
| FP-003 | M1 | Adapter PDFium para texto + render | validada no Linux | FP-002 | pypdfium2 5.13.0 real; 44 testes totais PASS; texto/caixas, página vazia, PDF inválido, DPI 72–300, buffer após close e limites de páginas/pixels; ruff/mypy/compileall PASS; Windows não validado |
| FP-004 | M2 | Benchmark OCR local | implementada / parcialmente validada | FP-003 | harness offline, hashes, 135 amostras OCR executadas; relatório RESEARCH-003; small candidato preferido; corpus espacial adicional: 48/48 por motor (RESEARCH-004); seleção final pendente de validação independente; avaliador local por manifesto pronto (LOCAL_CORPUS.md); FP-005 ainda não liberada |
| FP-005 | M2 | Classificador + parsers NF-e/NFS-e | pendente | FP-003,FP-004 | NF-e e NFS-e sintéticas retornam campos/flags esperados; ausências não são inventadas |
| FP-006 | M3 | Adapter Excel idempotente | validada | FP-002 | openpyxl 3.1.5 real: 6 testes PASS; texto externo não vira fórmula; mesma SHA atualiza a mesma linha; OS/validade/observações preservados; contrato inválido recusado; save temporário + replace atômico preserva arquivo em falha |
| FP-007 | M3 | CLI end-to-end local | pendente | FP-005,FP-006 | pasta de entrada → processamento → workbook sem rede |
| FP-008 | M4 | Frontend desktop conforme FRONTEND_DNA | pendente | FP-007 | estados inicial/vazio/processando/parcial/sucesso/erro; teclado e foco visível |
| FP-009 | M4 | Pacote Windows portátil `onedir` | pendente | FP-008 | build Windows CI + smoke sem Python instalado e sem admin no caminho nominal |
| FP-010 | M5 | Gates de privacidade/performance/licenças | pendente | FP-007,FP-009 | egress bloqueado, notices empacotados, benchmark e logs mínimos verificados |
| FP-011 | M5 | Smoke em máquina corporativa autorizada | pendente | FP-009,FP-010 | execução real sem privilégio adicional, com documentos aprovados localmente; nenhuma cópia sai da máquina |

## Observações

- O protótipo M365 é histórico separado e não satisfaz tarefas deste produto.
- Metas numéricas de performance não serão inventadas antes de FP-004/FP-010.
- FP-011 depende de políticas reais da empresa; execução sem admin é hipótese até smoke.

