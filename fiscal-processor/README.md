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
🟡 Implementação Python ainda não iniciada.  
⚪ Runtime Windows sem admin ainda não validado.

Próxima tarefa: `FP-002` em `docs/TASKLIST.md`.

## Documentação

- `AGENTS.md`
- `docs/PRODUCT.md`
- `docs/PRD.md`
- `docs/DESIGN.md`
- `docs/FRONTEND.md`
- `docs/RESEARCH-001-local-stack.md`
- `docs/ADR-001-local-only.md`
- `docs/TASKLIST.md`
- `docs/ROADMAP.md`
- `docs/PROJECT_STATE.md`
- `docs/SESSION_LOG.md`
