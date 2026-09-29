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
🟢 Adapter PDFium validado com biblioteca real no Linux (FP-003).  
🟢 Adapter Excel idempotente validado com openpyxl real (FP-006).  
🟢 pypdfium2 5.13.0: texto, caixas, render, limites e lifecycle testados.  
⚪ Runtime Windows sem admin ainda não validado.

## Excel

O workbook local usa SHA-256 oculto para idempotência. Reprocessamento pode atualizar campos fiscais automáticos, mas não escreve em:
- Número da OS;
- Validade;
- Observações.

O save é preparado em arquivo temporário e substitui o XLSX apenas após gravação bem-sucedida.

## Gates observados

- FP-002: 16 testes unitários PASS
- FP-003: integração real PASS; suíte final: 52 testes PASS
- FP-006: 6 testes reais com openpyxl 3.1.5 PASS
- `compileall`: PASS nos blocos executados
- `ruff check`, `ruff format --check`, `mypy src`: PASS

## Próximo gate

FP-004 / FiscalOCRBench implementado e executado com small, medium e Tesseract.
[Resultados e limitações](docs/RESEARCH-003-ocr-first-run.md). Validação independente e escolha final da engine ocorrerão após pacote Windows
(ADR-002); small provisório permite avançar nos parsers. Corpus espacial: 48/48 verificações
por motor, incluindo ausências esperadas ([relatório](docs/RESEARCH-004-ocr-spatial.md)).
Parsers e CLI disponíveis; validação representativa continua pendente.

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


Avaliação local com corpus autorizado: [guia](docs/LOCAL_CORPUS.md).
O avaliador é ferramenta de desenvolvimento; a CLI do produto está descrita abaixo.

Decisão atual: [small provisório e teste corporativo após pacote Windows](docs/ADR-002-provisional-ocr.md).

## Parser e CI

`fiscal_processor.parsers.parse_invoice` implementa a primeira fatia de FP-005:
labels explícitos DANFE e seções NFS-e. Recebe linhas em ordem de leitura; não
remonta tabelas achatadas. 83 testes locais PASS, incluindo PDFium→parser.
Workflow Fiscal Processor CI verifica Linux/Windows em PR/push e pode ser
acionado manualmente quando disponível na branch padrão. Build wheel é teste
de empacotamento Python, não o executável portátil final.

`parse_spans` agora associa labels/valores por posição e contexto de seção, com
`PdfiumAdapter.extract_spans` como entrada nativa. 96 testes locais PASS.
CI hospedado está bloqueado por faturamento/limite de gastos, conforme mensagem
informada pelo titular; execução Windows ainda não validada.

## OCR local integrado

O extra `ocr` instala RapidOCR 3.9.2, ONNX Runtime 1.24.2 e Pillow 12.3.0.
Preparar modelos em etapa separada com `python -m benchmarks.prepare_models /pasta/models`.
`RapidSmallAdapter` verifica hashes antes de carregar e não baixa modelos em execução.
`extract_evidence` seleciona texto nativo ou OCR por página; `parse_evidence`
preserva modo e flags no resultado fiscal. A CLI abaixo integra esse fluxo ao Excel.

Teste opcional de integração real (somente fixtures sintéticas, modelos já locais):

```sh
python -m pip install -e '.[dev,ocr]'
python -m benchmarks.prepare_models /pasta/models
FISCAL_OCR_MODELS=/pasta/models python -m pytest -ra
```

Sem a variável, o smoke OCR é marcado como skip, os demais testes permanecem ativos.
108 testes PASS com OCR habilitado no Linux. Heurística de texto útil e precisão
real ainda exigem avaliação no pacote Windows; bloqueio de rede Python no teste
não substitui o gate de egress no SO.


## CLI local (FP-007)

Para desenvolvimento, após instalar o pacote:

```sh
python -m fiscal_processor /pasta/pdfs --output /pasta/Controle_Notas_Fiscais.xlsx
python -m fiscal_processor /pasta/pdfs --output /pasta/Controle_Notas_Fiscais.xlsx --models /pasta/models
```

Também disponível pelo comando `fiscal-processor`. OCR requer o extra `ocr` e
modelos preparados previamente (seção anterior); não há download na execução.
PDFs textuais funcionam sem configurar modelos. Isto ainda exige Python no
ambiente de desenvolvimento; não é o pacote Windows destinado ao usuário.

- Descoberta não recursiva de arquivos `.pdf`/`.PDF`, em ordem pelo nome;
  links simbólicos de arquivos são ignorados.
- Conteúdo já registrado no Excel é ignorado por SHA-256. Use `--reprocess`
  para atualizar campos automáticos; OS, validade e observações são preservados.
- Progresso informa índice/total, estado e código sanitizado, sem nome/caminho
  ou valores fiscais. O índice corresponde à ordem de descoberta.
- Cada documento extraído é salvo atomicamente. Um erro de extração é informado
  na saída e não cria linha fiscal incompleta nem apaga uma linha existente.
  Outros documentos continuam. Erro de leitura/gravação do workbook interrompe
  o lote; registros previamente salvos continuam válidos.
- Não execute dois processos sobre a mesma planilha. Feche-a no Excel antes de
  processar. Cancelamento por Ctrl+C preserva gravações já concluídas.
- Pasta vazia não cria/altera planilha. `--dpi` aceita 72–300 (padrão 200).
- Códigos de saída: **0** concluído sem novas falhas/revisões (ou vazio), **1**
  há revisão/falha de documento, **2** falha do lote/configuração, **130** cancelado.
  `SKIPPED` significa apenas já registrado, não comprova qualidade da linha anterior.

Validação deste bloco: 117 testes PASS, um smoke OCR opcional não executado no
ambiente atual; Ruff, mypy e compileall PASS no Linux. O smoke OCR real anterior
permanece evidência do bloco FP-005, não uma nova execução. Windows e corpus
corporativo ainda não validados.
