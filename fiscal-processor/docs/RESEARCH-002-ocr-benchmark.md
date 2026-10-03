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


## Recomendação após pesquisa atualizada — 2026-09-27

### Candidato preferido para o runtime

**RapidOCR 3.9.x + PP-OCRv6 small + ONNX Runtime (CPU)**.

Esta é uma recomendação de arquitetura baseada em pesquisa, não uma validação no corpus fiscal.

Motivos:
- PP-OCRv6 foi lançado em 2026 e oferece modelo único multilíngue com suporte explícito a português.
- A variante `small` equilibra qualidade e footprint: detecção ~9,6 MB e reconhecimento ~20,4 MB nos artefatos oficiais PaddleOCR, enquanto `medium` usa ~59,4 MB + ~73,3 MB.
- Os números publicados para PP-OCRv6 colocam `small` próximo de `medium` em detecção/reconhecimento, com diferença de poucos pontos percentuais no conjunto interno, mas bundle muito menor.
- RapidOCR 3.9.2 oferece PP-OCRv6 tiny/small/medium diretamente em ONNX, com ONNX Runtime como backend e hashes SHA-256 dos modelos.
- RapidOCR e os modelos upstream PaddleOCR são Apache-2.0.
- ONNX Runtime evita o runtime PaddlePaddle completo e é apropriado para CPU local/multiplataforma.
- O pipeline fornece caixas + texto, úteis para associação espacial de labels e valores fiscais.

### Configuração inicial a testar

- PDF: pypdfium2/PDFium
- render OCR: 250–300 DPI
- OCR: RapidOCR
- versão OCR: PP-OCRv6
- model_type: small
- engine: onnxruntime
- idioma lógico: `pt` (modelo PP-OCRv6 é multilíngue unificado)
- downloads em runtime: proibidos; modelos serão vendorizados/pinados no pacote
- orientação 180°: habilitar somente se custo/benefício justificar no benchmark

### Variante de maior qualidade

**PP-OCRv6 medium** permanece candidato para:
- build "quality";
- segunda tentativa em página de baixa qualidade;
- ou substituição do `small` se o FiscalOCRBench mostrar ganho relevante em CNPJ/valor/número.

Não empacotar `small` e `medium` simultaneamente na v0.1 sem evidência, para evitar complexidade e bundle desnecessários.

### Backend

**ONNX Runtime** é o baseline por simplicidade e portabilidade.

**OpenVINO** deve ser testado opcionalmente em CPU Intel na FP-004. A documentação PaddleOCR reporta ganhos grandes de CPU com PP-OCRv6/OpenVINO, mas isso precisa ser medido na máquina-alvo antes de adicionar outra dependência ao produto.

### Por que os outros não são primeira escolha

- **Tesseract 5:** excelente baseline, leve e previsível, mas modelos tradicionais tendem a perder em documentos/layouts mais difíceis; manter no benchmark.
- **PaddleOCR 3.7 direto:** mesma família PP-OCRv6 e excelente opção técnica, porém o pacote atual traz PaddleX e dependências de rede (`requests`, `aiohttp`) no pacote base; RapidOCR oferece caminho mais estreito para o nosso runtime offline.
- **EasyOCR:** suporta português e Apache-2.0, mas depende de PyTorch/torchvision no Windows e está com release estável mais antiga; footprint de distribuição pior.
- **docTR:** Apache-2.0 e tecnicamente bom, porém PyTorch/TensorFlow e não há vantagem clara para português fiscal frente ao PP-OCRv6.
- **Surya 2:** qualidade alta, inclusive português, mas é um modelo 650M/VLM com licença de pesos condicionada para uso comercial maior; incompatível com nossa meta de runtime pequeno e não-VLM.
- **olmOCR/VLMs:** excluídos por arquitetura e privacidade/determinismo.

### Estado da decisão

- **Pesquisa:** RapidOCR + PP-OCRv6 small + ONNX Runtime é o candidato preferido.
- **Validação:** pendente de FP-004 / FiscalOCRBench.
- **Tesseract:** baseline obrigatório.
- **PP-OCRv6 medium:** challenger de qualidade.
- **OpenVINO:** challenger de backend/velocidade.
