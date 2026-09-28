# FP-004 — corpus espacial sintético v1

Data: 2026-09-28. Linux/Python 3.12; PDFium 5.13.0; RapidOCR 3.9.2,
ONNX Runtime 1.24.2; Tesseract 5 com por.traineddata pinado.

## Evidência
Seis documentos, sete páginas, 200 DPI nos três motores OCR. Execuções
sequenciais, mesmos PDFs e localizador; controle adicional com texto nativo.
48 verificações por motor: 38 valores presentes e dez ausências esperadas.

| Motor | Verificações exatas | Preenchimentos incorretos | Mediana s/documento | Total s |
| --- | --- | --- | --- | --- |
| PDFium nativo | 48/48 | 0 | 0,0012 | 0,021 |
| PP-OCRv6 small | 48/48 | 0 | 2,457 | 15,658 |
| PP-OCRv6 medium | 48/48 | 0 | 10,999 | 68,883 |
| Tesseract por | 48/48 | 0 | 0,446 | 2,815 |

Tempo inclui renderização e escrita PNG para OCR, exclui inicialização RapidOCR.
Tesseract inclui subprocesso e carga de modelo por página. Um documento tem
duas páginas; estas são medianas por documento, não por página. Host compartilhado,
uma rodada: não inferir SLA nem desempenho Windows. JSON por caso em
`benchmarks/results/spatial-*.json`.

## Cobertura e método
Colunas trocadas, acentos portugueses, valores abaixo dos rótulos, distrações,
duas páginas, total ausente, total duplicado e comprovante não fiscal.
Localizador usa texto/caixas normalizadas em pontos PDF e rótulos conhecidos;
não recebe gabarito ou coordenadas do gerador. Ambiguidade permanece None.
Gabarito só entra no scorer após extração. O caso visual foi inspecionado.

Split development/evaluation criado pelo mesmo autor: não é corpus independente
nem representativo de prefeituras. Localizador estreito de benchmark, não parser
FP-005. Ausências corretas contam nas 48 verificações; não anunciar 48 valores
extraídos. `review_oracle` depende de gabarito, não é confiança de produção.

## Decisão e limites
Small permanece candidato preferido pelo corpus degradado anterior e menor
modelo que medium. Tesseract venceu em tempo nesta rodada limpa; os três
empataram na qualidade espacial controlada. Não há evidência para empacotar
medium adicional nem seleção final de produção. FP-004 continua parcial:
próximo gate é validação com layouts independentes/anonimizados autorizados,
executados localmente, sem transmitir documentos empresariais.

Não repetir estas mesmas fixtures como se isso ampliasse representatividade.
Privacidade: somente dados gerados, preparo de modelos separado e hashes
verificados. Audit hook cobre Python; egress nativo/SO pertence a FP-010.

## Validação e reprodução
58 testes PASS; Ruff check/format, mypy src, compileall PASS. Seis testes novos
cobrem posições PDFium reais, valor observado sem lookup de resposta, ambiguidade,
colunas/páginas, marcadores conflitantes e pontuação de ausência. Comandos em
`benchmarks/README.md`.

A primeira tentativa Tesseract mostrou que `--tessdata-dir` isolado não contém
o arquivo auxiliar configs/tsv. Corrigido com `-c tessedit_create_tsv=1`; rodada
completa acima executada após correção. Não copiar configs globais implicitamente.
