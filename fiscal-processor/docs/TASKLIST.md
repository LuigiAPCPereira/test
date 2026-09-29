# TASKLIST — Fiscal Processor

| ID | Marco | Resultado | Estado | Depende de | Aceite/evidência |
| --- | --- | --- | --- | --- | --- |
| FP-001 | M0 | Pesquisa local-only + arquitetura inicial | validada documentalmente | nenhuma | PRODUCT/PRD/DESIGN/FRONTEND/RESEARCH/ADR-001 versionados; fontes técnicas verificadas |
| FP-002 | M1 | Bootstrap Python e contratos de domínio | validada no Linux | FP-001 | pacote `src/` criado; modelos/estados tipados; validações CNPJ/data/valor; 16 testes unitários PASS; `compileall` PASS; ruff/mypy definidos mas não revalidados neste ambiente |
| FP-003 | M1 | Adapter PDFium para texto + render | validada no Linux | FP-002 | pypdfium2 5.13.0 real; 44 testes totais PASS; texto/caixas, página vazia, PDF inválido, DPI 72–300, buffer após close e limites de páginas/pixels; ruff/mypy/compileall PASS; Windows não validado |
| FP-004 | M2 | Benchmark OCR local | implementada / parcialmente validada | FP-003 | harness offline, hashes, 135 amostras OCR executadas; relatório RESEARCH-003; small candidato preferido; corpus espacial adicional: 48/48 por motor (RESEARCH-004); seleção final pendente de validação independente; avaliador local por manifesto pronto (LOCAL_CORPUS.md); small provisório aceito (ADR-002); validação real após pacote Windows |
| FP-005 | M2 | Classificador + parsers NF-e/NFS-e | parcialmente implementada e validada no Linux | FP-003,ADR-002 | labelled-v1 + spatial-labelled-v1: seções, colunas/páginas e ambiguidades; 108 testes com OCR small real/fallback por página PASS; falta diversidade de layouts reais |
| FP-006 | M3 | Adapter Excel idempotente | validada | FP-002 | openpyxl 3.1.5 real: 6 testes PASS; texto externo não vira fórmula; mesma SHA atualiza a mesma linha; OS/validade/observações preservados; contrato inválido recusado; save temporário + replace atômico preserva arquivo em falha |
| FP-007 | M3 | CLI end-to-end local | implementada e validada no Linux (fluxo nativo) | FP-005,FP-006 | pasta → SHA/deduplicação → extração → Excel; reprocessamento explícito, campos manuais preservados, falhas isoladas; 117 testes PASS + 1 OCR opt-in skip; runtime OCR integrado anteriormente, smoke CLI OCR/Windows pendente |
| FP-008 | M4 | Frontend desktop conforme FRONTEND_DNA | implementada / parcialmente validada em Linux e Windows | FP-007 | Tkinter/ttk provisório (ADR-003), tabela/progresso/worker/cancelamento; CI run 36566933575 reexecutado no HEAD `638bae3f`: 133 PASS + 1 skip no Ubuntu e 133 PASS + 1 skip no Windows; testes Tk com display obrigatório PASS nos dois sistemas; Ruff/format/mypy/compileall/build wheel PASS; skip exclusivo do OCR sem modelos provisionados; inspeção visual humana, escala/conteúdo e acessibilidade ainda pendentes |
| FP-009 | M4 | Pacote Windows portátil `onedir` | implementada / parcialmente validada no Windows CI | FP-008 | PyInstaller 6.22.3 `onedir`; runtime Python/Tk/PDFium/RapidOCR/ONNX e modelos small empacotados; run 36575272863 no commit `cc28a2c` PASS; ZIP extraído executou `FiscalProcessor.exe --smoke` com Python ausente do `PATH`, carregando Tk + OCR/modelos; artefato `FiscalProcessor-windows-x64.zip` (162040569 bytes), SHA-256 `10892dd393e1d80f277b410f4fea15bc74159744d76c6ac1fb81eac80ffa916d`; máquina realmente sem Python e sem elevação ainda requer smoke corporativo |
| FP-010 | M5 | Gates de privacidade/performance/licenças | pendente | FP-007,FP-009 | egress bloqueado, notices empacotados, benchmark e logs mínimos verificados |
| FP-011 | M5 | Smoke em máquina corporativa autorizada | pendente | FP-009,FP-010 | execução real sem privilégio adicional, com documentos aprovados localmente; nenhuma cópia sai da máquina |

## Observações

- O protótipo M365 é histórico separado e não satisfaz tarefas deste produto.
- Metas numéricas de performance não serão inventadas antes de FP-004/FP-010.
- FP-011 depende de políticas reais da empresa; execução sem admin é hipótese até smoke.


## Ajuste autorizado — 2026-09-28
ADR-002: FP-004 não bloqueia mais parsers/CLI/GUI/pacote. Validação representativa
será executada no PC corporativo sem Python, com pacote portátil, em FP-010/011.
