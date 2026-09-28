# Pesquisa técnica — benchmark OCR fiscal

**Data:** 2026-09-27  
**Status:** plano de avaliação; nenhuma engine promovida para produção ainda.

## Fontes novas avaliadas

### olmOCR-bench

O benchmark do Allen Institute contém 1.403 PDFs e 7.010 testes unitários. Em vez de depender apenas de edit distance/CER, ele verifica fatos simples e auditáveis, como:
- presença/ausência de trechos;
- ordem natural de leitura;
- relações entre células de tabelas;
- fórmulas;
- headers/footers.

O benchmark é útil como **metodologia** porque transforma OCR em propriedades pass/fail verificáveis.

Limitações para este produto:
- dataset marcado como inglês;
- forte peso em matemática, documentos históricos, multi-coluna e tabelas;
- não cobre especificamente NF-e/NFS-e brasileira, CNPJ, valores monetários brasileiros ou layouts municipais;
- rankings não devem ser usados diretamente para escolher o runtime fiscal.

O modelo olmOCR em si não entra como candidato de runtime: é baseado em VLM de bilhões de parâmetros e exige GPU, além de contrariar o requisito do produto de não usar LLM/VLM sobre documentos fiscais.

### Artigo da Unstract

O artigo é útil como panorama de ferramentas, especialmente por separar OCR tradicional de OCR baseado em modelos multimodais.

Pontos aproveitáveis:
- Tesseract: leve, maduro, Apache-2.0, bom ponto de partida, mas pior em layout complexo;
- PaddleOCR: melhor suporte a layouts e multilíngue que Tesseract;
- Surya/docTR/EasyOCR: alternativas relevantes para documentos complexos.

Cautela:
- a fonte é de um fornecedor que promove produto próprio;
- alguns detalhes já estão atrás das versões oficiais atuais (o artigo descreve PP-OCRv4, enquanto a documentação oficial atual oferece PP-OCRv5 e PP-OCRv6);
- decisões de arquitetura devem usar documentação oficial e benchmark próprio.

## Candidatos

### 1. Tesseract 5
**Papel:** candidato runtime.

Prós:
- Apache-2.0;
- totalmente offline;
- português disponível;
- footprint relativamente baixo;
- distribuição conhecida.

Riscos:
- layout complexo;
- necessidade de pré-processamento;
- integração/empacotamento do binário e traineddata no Windows.

### 2. RapidOCR + ONNX Runtime + PP-OCR
**Papel:** candidato runtime prioritário.

A documentação atual do RapidOCR oferece PP-OCRv5 e PP-OCRv6 via ONNX Runtime. A família latina inclui português.

Prós:
- Apache-2.0 para código e modelos upstream declarados;
- ONNX Runtime é adequado a CPU local;
- modelos móveis/tiny/small favorecem distribuição;
- português suportado;
- não exige PaddlePaddle completo no runtime.

Riscos:
- bundle maior que Tesseract;
- modelos precisam ser pinados e empacotados para impedir download em runtime;
- medir cold start e memória.

### 3. PaddleOCR direto
**Papel:** baseline técnico, não primeira escolha de distribuição.

Motivo:
- é a fonte dos modelos usados por RapidOCR;
- oferece português e modelos atuais PP-OCRv5/v6;
- permite verificar se conversão ONNX perde qualidade.

Risco de produto:
- runtime PaddlePaddle e implantação Windows são mais pesados/complexos do que o caminho ONNX.

### 4. Surya
**Papel:** research-only na v0.1.

Apesar de forte em layout e 90+ idiomas, a distribuição consultada usa GPL-3.0-or-later e PyTorch, o que cria peso técnico e de licenciamento desnecessário para nosso aplicativo empresarial fechado.

### 5. olmOCR e outros VLM OCR
**Papel:** excluídos do runtime.

Motivos:
- requisito de produto: sem LLM/VLM nos documentos fiscais;
- maior consumo de hardware;
- risco de alucinação/contextualização;
- nossa necessidade é extração auditável de campos exatos, não reconstrução generativa de Markdown.

## FiscalOCRBench — benchmark próprio

Vamos adaptar o princípio de "unit tests de documento" do olmOCR-bench.

Cada fixture sintética/anonimizada terá assertions como:

### Texto exato
- CNPJ esperado aparece corretamente.
- Número da NF aparece corretamente.
- Série aparece corretamente.
- Data aparece corretamente.
- Valor preserva todos os dígitos e separadores relevantes.

### Estrutura
- emitente não é confundido com tomador;
- valor total não é confundido com base de cálculo/imposto;
- label e valor permanecem associados;
- ordem de leitura não mistura colunas críticas.

### Robustez visual
Gerar versões controladas:
- PDF digital;
- raster 150/200/300 DPI;
- compressão JPEG;
- rotação pequena;
- baixo contraste;
- ruído leve;
- escala reduzida;
- layout NF-e;
- diferentes layouts NFS-e.

### Métricas

Não usar uma única "accuracy" agregada.

Medir separadamente:
- exact-field accuracy;
- CNPJ exact match;
- valor exact match;
- data exact match;
- número/série exact match;
- document classification;
- false-positive field extraction;
- taxa de REVIEW;
- tempo por página;
- cold start;
- pico de memória;
- tamanho do bundle.

Para este domínio, erro de um dígito em CNPJ, número ou valor é falha completa do campo, mesmo que CER global pareça bom.

## Gate FP-004

Uma engine só vence se:
1. operar offline;
2. usar português;
3. passar pelo corpus fiscal;
4. não exigir privilégio administrativo no runtime nominal;
5. tiver licença compatível;
6. puder ser empacotada sem download silencioso;
7. apresentar trade-off aceitável de acurácia, latência, memória e bundle.

## Fontes

- olmOCR-bench dataset: https://huggingface.co/datasets/allenai/olmOCR-bench
- olmOCR-bench methodology: https://github.com/allenai/olmocr/blob/main/olmocr/bench/README.md
- Unstract OCR overview: https://unstract.com/blog/best-opensource-ocr-tools/
- PaddleOCR multilingual PP-OCRv5: https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/algorithm/PP-OCRv5/PP-OCRv5_multi_languages.en.md
- RapidOCR model list: https://rapidai.github.io/RapidOCRDocs/main/model_list/
- RapidOCR license/model provenance: https://github.com/RapidAI/RapidOCR
