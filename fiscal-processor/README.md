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
🟡 Adapter PDFium implementado e parcialmente validado (FP-003).  
🟢 Adapter Excel idempotente validado com openpyxl real (FP-006).  
⚪ Integração real com pypdfium2 ainda precisa de smoke em ambiente com o wheel instalado.  
⚪ Runtime Windows sem admin ainda não validado.

## Excel

O workbook local usa SHA-256 oculto para idempotência. Reprocessamento pode atualizar campos fiscais automáticos, mas não escreve em:
- Número da OS;
- Validade;
- Observações.

O save é preparado em arquivo temporário e substitui o XLSX apenas após gravação bem-sucedida.

## Gates observados

- FP-002: 16 testes unitários PASS
- FP-003: testes locais/doubles PASS; integração pypdfium2 real pendente
- FP-006: 5 testes reais com openpyxl 3.1.5 PASS
- `compileall`: PASS nos blocos executados
- `ruff`/`mypy`: não revalidados neste ambiente

## Próximo gate

Revalidar FP-003 com `pypdfium2==5.13.0` instalado. Só então iniciar FP-004 / FiscalOCRBench.

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
