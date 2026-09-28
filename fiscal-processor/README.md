# Fiscal Processor

Processador local de notas fiscais brasileiras em PDF.

## Objetivo

```text
PDFs locais
   ↓
texto nativo ou OCR local
   ↓
NF-e / NFS-e
   ↓
parsing + validação
   ↓
Controle_Notas_Fiscais.xlsx
```

Sem SharePoint, Power Automate, LLM, OCR SaaS, telemetria ou upload de documentos.

## Segurança

A arquitetura v0.1 estabelece que documentos e dados fiscais permanecem na máquina. Fixtures versionadas devem ser sintéticas/anonimizadas.

## Estado

🟢 Arquitetura e pesquisa inicial documentadas.  
🟢 Núcleo de domínio Python implementado e testado (FP-002).  
🟡 Adapter PDFium ainda não implementado (FP-003).  
⚪ Runtime Windows sem admin ainda não validado.

Próxima tarefa: `FP-003` em `docs/TASKLIST.md`.

## Gates observados em FP-002

- `pytest`: 16 PASS
- `compileall`: PASS
- `ruff`: não revalidado neste ambiente
- `mypy`: não revalidado neste ambiente

## Documentação

- `AGENTS.md`
- `docs/PRODUCT.md`
- `docs/PRD.md`
- `docs/DESIGN.md`
- `docs/FRONTEND.md`
- `docs/DEVELOPMENT.md`
- `docs/RESEARCH-001-local-stack.md`
- `docs/RESEARCH-002-ocr-benchmark.md`
- `docs/ADR-001-local-only.md`
- `docs/TASKLIST.md`
- `docs/ROADMAP.md`
- `docs/PROJECT_STATE.md`
- `docs/SESSION_LOG.md`
