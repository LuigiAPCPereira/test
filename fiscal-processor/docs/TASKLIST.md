# TASKLIST — Fiscal Processor

| ID | Marco | Resultado | Estado | Depende de | Aceite/evidência |
| --- | --- | --- | --- | --- | --- |
| FP-001 | M0 | Pesquisa local-only + arquitetura inicial | validada documentalmente | nenhuma | PRODUCT/PRD/DESIGN/FRONTEND/RESEARCH/ADR-001 versionados; fontes técnicas verificadas |
| FP-002 | M1 | Bootstrap Python e contratos de domínio | validada no Linux | FP-001 | pacote `src/` criado; modelos/estados tipados; validações CNPJ/data/valor; 16 testes unitários PASS; `compileall` PASS; ruff/mypy definidos mas não revalidados neste ambiente |
| FP-003 | M1 | Adapter PDFium para texto + render | validada no Linux | FP-002 | pypdfium2 5.13.0 real; 44 testes totais PASS; texto/caixas, página vazia, PDF inválido, DPI 72–300, buffer após close e limites de páginas/pixels; ruff/mypy/compileall PASS; Windows não validado |
| FP-004 | M2 | Benchmark OCR local | implementada / parcialmente validada | FP-003 | harness offline, hashes, 135 amostras OCR executadas; relatório RESEARCH-003; small candidato preferido; corpus espacial adicional: 48/48 por motor (RESEARCH-004); seleção final pendente de validação independente; avaliador local por manifesto pronto (LOCAL_CORPUS.md); small provisório aceito (ADR-002); validação real após pacote Windows |
| FP-005 | M2 | Classificador + parsers NF-e/NFS-e | parcialmente implementada; regressões corporativas reproduzidas sinteticamente | FP-003,ADR-002 | smoke corporativo 2026-09-29 expôs dois layouts não cobertos: um PDF com camada nativa inadequada caiu em layout não suportado e um DANFE reconhecido não preencheu corretamente os campos visíveis; sem dados/nomes reais versionados. Commit `74047e2a`: fallback parse→OCR local quando evidência nativa termina em revisão relevante, aliases/seções do DANFE oficial, Nº/Série repetidos idênticos e valores horizontais tipados. CI run 36584471585: 137 PASS + 1 skip em Ubuntu e Windows. Reteste nos mesmos documentos reais ainda pendente. |
| FP-006 | M3 | Adapter Excel idempotente | validada | FP-002 | openpyxl 3.1.5 real: 6 testes PASS; texto externo não vira fórmula; mesma SHA atualiza a mesma linha; OS/validade/observações preservados; contrato inválido recusado; save temporário + replace atômico preserva arquivo em falha |
| FP-007 | M3 | CLI end-to-end local | implementada e validada no Linux (fluxo nativo) | FP-005,FP-006 | pasta → SHA/deduplicação → extração → Excel; reprocessamento explícito, campos manuais preservados, falhas isoladas; 117 testes PASS + 1 OCR opt-in skip; runtime OCR integrado anteriormente, smoke CLI OCR/Windows pendente |
| FP-008 | M4 | Frontend desktop conforme FRONTEND_DNA | implementada / parcialmente validada em Linux, Windows CI e Windows corporativo | FP-007 | Tkinter/ttk provisório; CI Tk obrigatória PASS. Evidência corporativa visual: estados inicial e pasta vazia renderizados sem recorte evidente; mensagem vazia correta e sem falsa planilha. Escala 200%, estados parcial/erro/nome longo, foco visível qualitativo e leitor de tela continuam pendentes. |
| FP-009 | M4 | Pacote Windows portátil `onedir` | implementada / parcialmente validada no Windows CI e host corporativo | FP-008 | pacote abriu no PC corporativo real sem Python; SmartScreen de publisher desconhecido observado. Candidato corrigido `74047e2a` validado no run 36584471585: 137 PASS + 1 skip por SO, job portátil e smoke sem Python no PATH PASS; artefato `FiscalProcessor-windows-x64.zip` ID 11041063334, SHA-256 `76bef9b697c9b486e8444e151649839f77d4def499b8779fd49b1f191e39ad5f`. Reteste corporativo do candidato e prova explícita sem UAC/admin pendentes. |
| FP-010 | M5 | Gates de privacidade/performance/licenças | pendente | FP-007,FP-009 | egress bloqueado, notices empacotados, benchmark e logs mínimos verificados |
| FP-011 | M5 | Smoke em máquina corporativa autorizada | iniciado fora da ordem planejada / aceite não concluído | FP-009,FP-010 | usuário processou dois PDFs autorizados antes de FP-010 e expôs lacunas de extração; nenhuma cópia/documento real foi versionado. Essa execução não satisfaz o aceite de privacidade/egress nem valida o parser; reteste controlado após FP-010 continua necessário. |

## Observações

- O protótipo M365 é histórico separado e não satisfaz tarefas deste produto.
- Metas numéricas de performance não serão inventadas antes de FP-004/FP-010.
- FP-011 depende de políticas reais da empresa; execução sem admin é hipótese até smoke.


## Ajuste autorizado — 2026-09-28
ADR-002: FP-004 não bloqueia mais parsers/CLI/GUI/pacote. Validação representativa
será executada no PC corporativo sem Python, com pacote portátil, em FP-010/011.
