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

## 2026-09-28 — FP-005 posições e bloqueio externo de CI
- Base 24f5bd2; usuário confirmou annotation de billing/spending limit. Não há
  prova de falha de código no CI; nenhum pagamento/limite alterado.
- Contrato TextSpan, conversão PDFium e parser espacial com seção/coluna/página.
- 13 regressões novas, 96 testes PASS; Ruff/mypy/compileall PASS.
- CI mantém PR e push main, elimina duplicação push branch + PR.
- Retrospectiva: fronteiras de seção/página e candidatos ambíguos protegidos por
  testes; causa externa de CI registrada no checkpoint, sem reexecuções inúteis.
- Próximo bloco: adapter OCR small e fallback por página.

## 2026-09-29 UTC — FP-005 OCR local integrado
- Base 063bb49 recuperada após interrupção; alterações locais em andamento preservadas.
- Adapter small lazy com hashes/versões, entrada em memória, erros sanitizados.
- Ports/DTOs internos evitam application depender do adapter PDF concreto.
- Fallback por página, modo misto e propagação de flags; sem retorno parcial em erro.
- 108 testes com OCR real habilitado PASS; Ruff/mypy/compileall PASS.
- Smoke real: dois PDFs rasterizados sintéticos + branco; rede Python bloqueada.
- Retrospectiva: comportamento lazy, seleção por página e preservação de flags
  cobertos por testes. Limites da heurística e ausência de prova SO/Windows no checkpoint.
- Próxima tarefa FP-007 (lote/CLI/Excel); não repetir tentativa CI por bloqueio de cobrança.


## 2026-09-29 — FP-007 lote/CLI
- Base: 60bf61f, branch feat/fiscal-processor-local-v0.1, Draft PR #4.
- Batch sequencial com progresso, deduplicação, reprocessamento e falhas isoladas;
  CLI conecta PDF/OCR/parser/Excel. Falhas de persistência interrompem o lote.
- 117 PASS + 1 smoke OCR skip; Ruff/mypy/compileall PASS no Linux.
  Dez testes novos, incluindo PDFium/openpyxl reais. Windows/CLI OCR pendentes.
- Retrospectiva: falha ao reprocessar não deve apagar extração anterior; proteção
  instalada como teste de regressão que compara os bytes do workbook. Evidência
  histórica OCR distinguida da validação atual. Nenhuma mudança no protocolo.
- Próxima tarefa: FP-008, interface; manter CI bloqueado por cobrança explícito.


## 2026-09-29 — FP-008 interface inicial
- Base 881d121; Tkinter/ttk provisório conforme ADR-003.
- Worker/fila, read models, tabela, seleção de pasta, cancelamento entre PDFs e
  abertura de planilha. CLI reutiliza composition root extraído sem mudar opções.
- 128 testes PASS + 2 skips; Ruff/mypy/compileall PASS no Linux.
- Tk real não abriu: ambiente sem display. UI visual/a11y e Windows pendentes.
- Retrospectiva: duplicatas não autorizam inferir qualidade anterior; teste de
  read model exige travessões e mensagem de não reavaliação. Teste de cancelamento
  garante que próximo PDF não inicia após pedido. Nenhuma alteração no protocolo.
- Próximo: gates renderizados FP-008, depois empacotamento Windows FP-009.


## 2026-09-29 — gate gráfico FP-008
- Base 1294840; testes Tk separados e obrigatórios na CI; Linux usa Xvfb.
- 128 PASS + 6 skips localmente; Ruff/mypy/compileall PASS. Modo obrigatório
  comprovadamente falha sem display. Nenhum teste gráfico declarado aprovado.
- Xvfb local preparado isoladamente, mas servidor não pôde abrir sockets;
  instalação de sistema também indisponível. CI permanece bloqueada por cobrança.
- Retrospectiva: skip de display podia ocultar falta de validação na CI; guardrail
  instalado via FISCAL_REQUIRE_DISPLAY e comandos por SO. Não repetir tentativas
  neste host; próxima execução requer ambiente gráfico/runner disponível.


## 2026-09-29 — preparação reproduzível da inspeção FP-008
- HEAD recuperado: 37d7795, Draft PR #4; nenhuma alteração concorrente observada.
- Run 36562313169: jobs Linux/Windows falharam sem passos/logs, portanto nenhum
  teste gráfico foi executado; bloqueio externo da conta permanece.
- Criado `tools/visual_qa.py` fora do pacote para estados sintéticos, nomes
  longos, viewport mínimo e escala 200%, sem dados fiscais reais.
- Corrigida orientação de lotes sem linhas: não pede mais seleção inexistente;
  teste Tk de pasta vazia estendido.
- Validação desta fatia: sintaxe do harness conferida isoladamente. Gates do
  repositório e renderização continuam pendentes; FP-008 não foi promovida.
- Próximo: executar harness + suíte Tk em display real e registrar evidência.
