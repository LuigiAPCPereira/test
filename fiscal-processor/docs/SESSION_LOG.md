# SESSION_LOG — Fiscal Processor

## 2026-09-27 — Pivot do protótipo M365 para produto local-only

### Evidência recuperada
- Protótipo Power Automate demonstrou extração correta em NF-e textual.
- Outro PDF/NFS-e retornou texto vazio e expôs a necessidade de rasterização/OCR.
- AI Builder não possuía capacidade no tenant testado.
- Usuário decidiu não depender de SharePoint/conta corporativa e exige que dados fiscais não sejam enviados a LLM/serviço externo.

### Decisão
Criar produto separado em Python, local-only, com saída Excel e distribuição Windows portátil.

### Pesquisa
- PyMuPDF: AGPL/comercial; não selecionado como base da v0.1.
- pypdfium2/PDFium: licenças permissivas e APIs para texto/render; selecionado para POC.
- Tesseract: Apache-2.0, português e operação local.
- RapidOCR: Apache-2.0, offline, modelos PP-OCRv6 com português; benchmark necessário.
- openpyxl: MIT e suporta leitura/escrita de XLSX; selecionado para POC.
- PyInstaller: gera bundle standalone, não é cross-compiler; `onedir` escolhido inicialmente.
- GUI: decisão adiada; contrato de Frontend DNA documentado antes do framework.

## 2026-09-27 — FP-002 bootstrap Python

### Implementado
- `pyproject.toml` com pacote src-layout e dependências dev separadas.
- Domínio sem dependências externas.
- Enums explícitos e ownership separado entre extração automática e campos manuais.
- Validador de CNPJ, datas e BRL.

### Validação
- `pytest`: 16 testes, PASS.
- `compileall`: PASS.
- `ruff`/`mypy`: não revalidados neste ambiente.

## 2026-09-27 — FP-003 adapter PDFium

### Implementado
- `pypdfium2==5.13.0` pinado.
- Texto, text objects/bounding boxes e renderização por DPI implementados.

### Validação observada
- suíte local com doubles: PASS;
- integração real do wheel: pendente;
- GitHub Actions não obteve runner/steps e foi removido como sinal não confiável.

### Estado
FP-003 permanece **implementada / parcialmente validada**.

## 2026-09-27 — FP-006 adapter Excel

### Implementado
- `openpyxl==3.1.5` pinado.
- Adapter `OpenpyxlInvoiceStore` com upsert por SHA-256.
- Campos manuais são fora do mapa de escrita automática.
- Colunas técnicas ficam ocultas.
- Save atômico usa arquivo temporário no mesmo diretório e `os.replace`.
- Contrato de cabeçalho divergente falha fechado.

### Validação real
Foram executados 5 testes com a biblioteca openpyxl instalada:
1. criação do workbook e ocultação das colunas técnicas;
2. mesma SHA atualiza a mesma linha;
3. reprocessamento preserva OS, validade e observações;
4. SHA diferente cria nova linha;
5. falha simulada no replace preserva o XLSX anterior e limpa temporário.

Resultado: **5/5 PASS**.  
`compileall`: **PASS**.

### Evidência Git
- `d2e829987c407b48ef28ba5f45ff30389e283c36`


## 2026-09-28 — FP-003 integração real e limites
- Base observada: 05d247e470931a8c0a38bb030c0fa4a19d3822e2, PR #4 Draft.
- Wheel pypdfium2 5.13.0 instalado; baseline 29 testes PASS.
- Acrescentados testes reais de DPI, página vazia, limites e buffer após close.
- Achado: ceil(points * (dpi / 72)) pode diferir um pixel de ceil(points * dpi / 72).
  Preflight e testes corrigidos para corresponder ao PDFium real.
- Limites configuráveis evitam rasterizações acima do orçamento e documentos extensos.
- 44 testes PASS; ruff/mypy/compileall PASS após correção das pendências de baseline.
- Protocolo: usuário informou COMPLETE; índice Notion STAGING está desatualizado.
- Próxima tarefa FP-004; runtime Windows e memória nativa de longa duração não validados.
- Commit: identificado no histórico pela mensagem FP-003: validate real PDFium integration and bound rendering.

## 2026-09-28 — FP-006 texto externo no Excel
- Teste real reproduziu fórmula involuntária em nome de arquivo/emitente/número iniciado com `=`.
- Writer agora força strings automáticas como texto XLSX, mantendo valor literal.
- Também fecha workbook quando validação de cabeçalho lança erro.
- Teste de regressão PASS junto às invariantes existentes; nenhum campo manual alterado.
- Commit: FP-006: keep extracted text literal in Excel cells.

## 2026-09-28 — FP-004 benchmark sintético executado
- Harness implementado: corpus reproduzível, degradações, scorer exato, modelos
  pinados/hash verificado, preparo separado e bloqueio Python de rede na inferência.
- Small: 60 casos/476 de 480 campos; medium: 15 casos/120 de 120;
  Tesseract por: 60 casos/459 de 480. Nenhum falso positivo na página branca.
- Modelo medium completo interrompido; relatório compara apenas interseção150DPI.
- Evidência/limitações e dados por amostra em RESEARCH-003 e benchmarks/results/.
- 52 testes e gates estáticos PASS. Runtime Windows/corporativo não validado.
- FP-004 parcial; preferência small reforçada, escolha final depende corpus espacial
  e validação independente. Não iniciar FP-005 como se esse gate estivesse completo.
- Commit: FP-004: add offline synthetic fiscal OCR benchmark.

### Retomada e revisão antes da publicação
HEAD remoto 6b7605f confirmado sem mudança concorrente. Arquivos e resultados
preservados; dependências dev precisaram reinstalação após reinício do ambiente.
52 testes novamente PASS (1,12 s), ruff check/format, mypy e compileall PASS.
Benchmarks OCR não repetidos: resultados originais preservados em JSON.
Revisão esclareceu que startup Tesseract é sondagem de versão, diferente do
carregamento residente RapidOCR; latência por página Tesseract inclui subprocesso.
Curator Pass: lições específicas registradas no README do benchmark (checkpoint,
execução sequencial, métricas comparáveis); sem alteração no plugin/protocolo.

## 2026-09-28 — FP-004 corpus espacial
- HEAD f08cef7 recuperado; branch/PR Draft preservados.
- Seis documentos/sete páginas sintéticas; small, medium, Tesseract e nativo
  48/48 verificações cada, das quais dez são ausências esperadas.
- Extração por caixas/rótulos sem gabarito; negativos, ambiguidade e acentos.
- TSV Tesseract configurado explicitamente para pasta isolada de modelos.
- 58 testes e gates Ruff/mypy/compileall PASS; relatório RESEARCH-004.
- Curator: versões preinstaladas podem divergir; confirmar pin PDFium.
  Corpus do mesmo autor não substitui validação independente.
- Próximo gate FP-004: layouts independentes autorizados; FP-005 pendente.
- Commit: FP-004: validate spatial OCR corpus across three local engines.

## 2026-09-28 — FP-004 avaliação local por manifesto
- Base remota 2c05609 confirmada; Draft PR #4 preservado.
- Avaliador local reutiliza extração por caixas; relatório exporta somente métricas.
- PDFs corrompidos contam no denominador, próximos documentos continuam.
- Schema/caminhos contidos e saída exclusiva protegem fontes/evidências.
- 69 testes PASS, Ruff/mypy/compileall PASS; smoke CLI nativo e Tesseract 48/48 cada, sintéticos.
- Retrospectiva: privacidade do relatório e preservação de evidência transformadas
  em testes determinísticos; guia LOCAL_CORPUS concentra o próximo procedimento.
- FP-004 continua parcial: falta executar corpus independente autorizado.
- Commit: FP-004: add private local corpus evaluation with sanitized reports.

## 2026-09-28 — ajuste de sequência autorizado
Usuário esclareceu PC corporativo sem Python e ausência de notas equivalentes
no PC pessoal; aceitou small provisório. ADR-002 remove dependência da validação
real para iniciar FP-005. Teste representativo transferido para pacote Windows
com runtime/modelos incluídos. Foto orienta somente estrutura de fixture sintética.
Mudança documental; não altera código nem evidência dos 69 testes anteriores.
Retrospectiva: gate de validação deve estar acessível ao usuário no ambiente alvo;
registrada a sequência corrigida no plano, sem acrescentar novo bloqueio.

## 2026-09-28 — FP-005 parser e CI
- Base ed6e8af; parser puro labelled-v1 com contexto de partes e revisão explícita.
- 14 testes novos; 83 testes locais PASS, Ruff/mypy/compileall PASS.
- Workflow Linux/Windows com permissions mínimas e actions fixadas por SHA.
- Teste subprocesso usa os.pathsep; symlink só é skip se Windows negar privilégio.
- Limite: recebe linhas ordenadas, não remonta tabelas; OCR não integrado.
- Próximo: consultar CI publicado e integrar evidências PDF/OCR ao parser.
- Retrospectiva: total líquido/base não devem substituir total fiscal; regressão
  instalada em teste determinístico, fixture inteiramente sintética.
