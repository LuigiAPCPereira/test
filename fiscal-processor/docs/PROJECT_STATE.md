# PROJECT_STATE — 2026-09-29 UTC

## Ref observada e escopo
- Repositório: LuigiAPCPereira/test
- Branch: feat/fiscal-processor-local-v0.1; Draft PR #4; sem merge.
- HEAD inicial recuperado: 05d247e470931a8c0a38bb030c0fa4a19d3822e2.
- Commits publicados: 1de8841 (FP-003), 6b7605f (FP-006), f08cef7 (FP-004 inicial).
- Snapshot dos 32 arquivos do PR recuperado pelo plugin GitHub. Clone indisponível por autenticação; não há alegação de checkout Git local completo.
- Escopo: Fiscal Processor local-only, separado do PR #3/M365.

## Fontes
AGENTS.md do subprojeto lido na ref exata; AGENTS.md raiz retornou 404.
Protocolo 2.2 e DNAs dos anexos consultados. Índice Notion retornou STAGING,
mas o usuário corrigiu explicitamente em 2026-09-27: estado atual COMPLETE;
Notion desatualizado. COMPLETE é informação do usuário; equivalência integral
entre cópias não foi certificada nesta sessão. Não se trata de nova adoção.

## FP-003 — validada no Linux
pypdfium2 5.13.0 instalado e executado com Python 3.12 Linux x86_64.
44 testes PASS, incluindo integração real de texto, caixas, render em cinco
DPIs, página sem texto, PDF inválido, buffer independente após close e limites.
Limites configuráveis: 500 páginas e 40 milhões de pixels; DPI inteiro 1–600.
Dimensionamento usa a mesma ordem de operações float do PDFium: ceil(points * scale).
Ruff check/format, mypy src e compileall PASS. FP-002 também teve gates revalidados.
FP-006 mantém seis testes reais PASS, incluindo texto externo como literal (sem fórmula).

## Limites de evidência
Não há prova de ausência de todos os vazamentos nativos; limites de pixels não
são sandbox nem timeout de PDF malicioso. Windows, máquina corporativa,
OCR e desempenho do produto completo não validados.

## FP-004 — implementada / parcialmente validada
Benchmark local com corpus sintético, degradações, scorer exato, hashes pinados,
checkpoint por amostra e três engines executadas (135 amostras ao todo).
Small 476/480 campos (60 casos); medium 120/120 (15 casos/150 DPI);
Tesseract 459/480 (60 casos). Comparação comum/limites em RESEARCH-003.
52 testes PASS + ruff check/format/mypy/compileall PASS no conjunto final.
Small permanece candidato, sem seleção final nem runtime OCR do produto.

## FP-004 — ampliação espacial
Corpus espacial executado: seis documentos/sete páginas por motor a 200 DPI;
small, medium e Tesseract 48/48 verificações cada; nativo também 48/48.
Inclui dez ausências esperadas. Relatório RESEARCH-004 e JSON versionados.
58 testes PASS; Ruff check/format, mypy e compileall PASS.

## FP-004 — avaliador local por manifesto
Implementado `benchmarks.local_run`: schema restrito, caminhos contidos, gabarito
separado da extração, relatórios sem valores/caminhos, saída exclusiva e checkpoint.
69 testes PASS; gates estáticos PASS. Smoke nativo e Tesseract sintéticos 48/48 cada.
Guia operacional em LOCAL_CORPUS.md. Isto habilita a coleta de evidência externa,
mas não equivale a corpus independente validado.

## Decisão atual — ADR-002
Usuário autorizou small provisório e testes representativos após pacote Windows:
PC corporativo sem Python; não possui corpus equivalente no PC pessoal.
Foto de NFS-e fornecida como referência visual; nenhum dado real versionado.
FP-004 parcial deixa de bloquear implementação, sem declarar validação concluída.

## FP-005 — primeiro parser determinístico
`parsers.parse_invoice` recebe linhas em ordem de leitura e metadados; não importa
PDF/OCR nem filesystem. DANFE com labels explícitos e NFS-e com contexto de
prestador/tomador. Número/série combinados, data/hora, CNPJ com dígitos verificadores,
valor monetário estrito; ausência/duplicidade/invalidez gera REVIEW e campo vazio.
83 testes PASS no Linux, incluindo PDFium real → parser.
A integração espacial posterior abaixo amplia esta primeira versão. OCR integrado
e layouts municipais em geral ainda não validados; foto não processada pela engine.

## CI
Workflow `.github/workflows/fiscal-processor-ci.yml`: PR/push/manual, Python 3.12,
Ubuntu 24.04 e Windows 2022; Ruff, mypy, pytest, compileall e build wheel.
Actions fixadas em SHA, permissão contents:read, sem secrets/deploy/documentos reais.
Run 36432485526 falhou antes de iniciar jobs. Usuário confirmou a annotation:
pagamentos recentes falharam ou limite de gastos precisa de ajuste. Causa externa
à execução do código; não corrigida e nenhuma configuração de cobrança alterada.
Não repetir runs até resolver a conta. Windows ainda não validado.
Push restrito a main; PR verifica branch de trabalho sem execução duplicada.
Wheel não é pacote portátil Windows.

## FP-005 — integração espacial
`TextSpan` é evidência neutra em pontos PDF com origem superior esquerda.
`PdfiumAdapter.extract_spans` converte coordenadas nativas; `parse_spans` associa
rótulo/valor na mesma página/coluna e resolve nomes/CNPJ por seção. Não atravessa
cabeçalhos nem herda seção de outra página; múltiplos candidatos geram revisão.
96 testes locais PASS (13 novos); seis PDFs sintéticos exercitam o parser real.
Limites explícitos: valores até 22 pontos abaixo, alinhamento até oito pontos,
labels inteiros; nomes quebrados e tabelas complexas podem exigir revisão.

## FP-005 — OCR small e fallback
Adapter RapidSmallAdapter implementado; RapidOCR 3.9.2/ORT 1.24.2, modelos locais
validados por SHA-256 antes de importar/inicializar a engine. Inicialização lazy;
PDF textual não exige modelos. Rasters enviados em memória BGR; sem download
no caminho de inferência nem gravação de imagens temporárias.
Contratos PDF/raster movidos ao domínio e preservados via exports do adapter.
Application extract_evidence seleciona texto/OCR por página e retorna modo
NATIVE_TEXT/OCR/MIXED; parse_evidence preserva flags de revisão. Falha de OCR
propaga erro, não sucesso parcial.
108 testes PASS com smoke OCR real habilitado; Ruff/mypy/compileall PASS.
Dois PDFs rasterizados sintéticos + página branca, com socket.connect e DNS
Python bloqueados. Isso não comprova bloqueio de rede nativa/SO nem Windows.
Heurística inicial: >=40 caracteres alfanuméricos, >=95% imprimíveis sem U+FFFD.
Pode rejeitar páginas curtas úteis ou aceitar camada textual ruim: calibrar com
corpus corporativo após pacote; não alegar qualidade fiscal geral. OCR_LOW_QUALITY
marca saída vazia; ainda não há limiar de confiança calibrado por campo.

## FP-007 — lote e CLI
Base remota conferida: 60bf61fd7ba69ad1a748a052f4e3ad242d1640a7, Draft PR #4.
Implementados application.batch, CLI e entrypoint python -m fiscal_processor.
Descoberta não recursiva, SHA-256, skip por conteúdo e reprocessamento explícito.
Cada upsert mantém contrato manual e save atômico. Falha de extração não cria
linha com modo fiscal inventado nem sobrescreve resultado anterior: aparece no
resultado do lote/saída sanitizada. Falha do workbook interrompe lote; commits
por documento anteriores permanecem. Ctrl+C propaga e preserva o que foi salvo.
Hash verificado antes/depois da extração detecta mudanças comuns, mas não é
snapshot imutável nem proteção contra escritor concorrente. Um escritor por
workbook; sem otimização de releitura XLSX antes de baseline de desempenho.
117 testes PASS + 1 skip OCR opt-in neste ambiente Linux; 10 novos testes cobrem
fluxo real PDF→Excel, duplicatas, manuais, cancelamento, entrada alterada,
PDF inválido, modelos não configurados e workbook inválido/falha de gravação.
Ruff check/format, mypy (21 arquivos) e compileall PASS.
OCR real do bloco anterior não reexecutado; CLI com OCR e Windows ainda não
validados. Guia operacional/códigos de saída no README.

## FP-008 — primeira interface desktop
Base conferida: 881d1212232212d5f19d90a932a737fb5447b664, Draft PR #4.
Tkinter/ttk provisório, ADR-003; pasta/processamento/progresso/tabela e abertura
local da planilha. Composition root compartilhado com CLI; worker sem widgets,
fila consumida via after na thread principal. Cancelamento no batch entre
PDFs, após gravação; fechamento em execução solicita cancelamento sem matar worker.
DocumentResult inclui extração somente após save, para read model da tabela;
duplicatas não inventam campos anteriores. 128 PASS + 2 skips no Linux:
Tk sem display e OCR sem modelos. Ruff/mypy/compileall PASS.
Não houve inspeção renderizada: tentativa Tk falhou por ausência de DISPLAY.
Ver limites completos em FRONTEND.md; FP-008 parcial, Windows não validado.

## FP-008 — gate gráfico preparado
Base conferida: 1294840d0d6615345b247d14603e98de7e3ad3a1.
CI agora exige FISCAL_REQUIRE_DISPLAY=1 e usa Xvfb no Linux. Cinco testes reais
Tk preparados: teclado, fluxo real, vazio, cancelamento/fechamento e falha parcial.
Suíte local: 128 PASS + 6 skips; Ruff/mypy/compileall PASS. Modo obrigatório
executado sem display falhou como esperado (não skip), comprovando o bloqueio.
Tentativa apt falhou por permissões; Xvfb extraído isoladamente também falhou
por não conseguir criar sockets locais. Não repetir provisionamento neste host.
Não houve janela renderizada ou CI executada; FP-008 continua parcial.

## FP-008 — harness de QA visual sintético
Adicionado `tools/visual_qa.py`, fora do wheel/runtime, para abrir estados
determinísticos initial/selected/processing/empty/success/partial/error/cancelled/long.
Aceita escala Tk e geometria para inspeção a 200% e viewport mínimo. Todos os
dados são sintéticos; estados com planilha criam XLSX temporário local. Isto
reduz a dependência de documentos reais para revisão visual, mas não cria
evidência renderizada neste ambiente.

Correção de UX associada: lotes sem nenhuma linha concluída não orientam mais
a selecionar um item inexistente; mostram `Não há itens concluídos para detalhar.`.
O teste Tk de pasta vazia foi estendido para proteger a mensagem. O novo script
teve sintaxe Python conferida isoladamente antes do commit; suíte/ruff/mypy e
renderização da revisão ainda precisam de ambiente capaz de executar a árvore.

## Próxima ação
FP-008: em display real, executar `python tools/visual_qa.py partial` e
`python tools/visual_qa.py long --scale 2.0 --geometry 760x540`; validar
teclado/foco, escala, nomes longos, estados, scroll e cancelamento, além da suíte
Tk obrigatória. Confirmar escolha provisória após evidência visual/acessível,
antes de FP-009 pacote Windows. CLI OCR end-to-end permanece pendente de ambiente
com modelos. CI segue bloqueado antes das etapas; não repetir runs manuais até
resolver a conta. Smoke corporativo somente após pacote sem Python.
