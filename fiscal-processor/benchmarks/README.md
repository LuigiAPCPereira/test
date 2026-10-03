# FiscalOCRBench — FP-004

Ferramenta de desenvolvimento para documentos **exclusivamente sintéticos**.
Nenhum componente deste diretório é importado pelo runtime do produto.

## Reproduzir

```sh
python -m pip install -e '.[dev]'
python -m pip install -r benchmarks/requirements.txt
# Preparação explícita, COM rede, fora do runtime:
python -m benchmarks.prepare_models /caminho/models --download-comparison-models
# Inferência: não faz download; arquivos ausentes/hash incorreto falham fechado.
PYTHONPATH=src:. python -m benchmarks.run --engine small --models /caminho/models --output small.json
PYTHONPATH=src:. python -m benchmarks.run --engine medium --models /caminho/models --output medium.json
# Tesseract 5 precisa estar instalado separadamente.
PYTHONPATH=src:. python -m benchmarks.run --engine tesseract --models /caminho/models --output tesseract.json
```

Cada amostra concluída gera checkpoint `.jsonl` ao lado do relatório; uma
interrupção não equivale a relatório final completo.

Executar engines **sequencialmente** em processos separados para medir latência.
O lock é o ambiente observado em Linux/Python 3.12; wheels e execução Windows não
foram validados. Não é lock final do produto. Dependências OCR são opcionais e não
foram adicionadas ao runtime em `pyproject.toml`.

## Corpus e métricas

- Três documentos com labels controlados: DANFE, NFS-e A, NFS-e com texto de 8 pt.
- 150/200/250/300 DPI × clean/JPEG35/baixo contraste/ruído seed fixa/rotação 1°.
- Configuração completa: 60 casos por engine, oito campos por caso, mais página branca negativa.
  `--dpi 150` permite rodada reduzida de 15 casos; comparar somente a interseção.
- PDF digital original também é validado pelo teste com PDFium real.
- Campos: tipo, número, série, data, CNPJ, emitente, destinatário, valor.
- Campos de distração: base tributária, CNPJ tomador e data de protocolo.
- Comparação exata; nenhuma tolerância para centavos nem para dígitos.
- Labels duplicados são ambíguos; campos ausentes permanecem None.
- `wrong_nonempty` mede campo preenchido incorretamente; `review` é **oráculo de
  benchmark**, não taxa de revisão que um produto saberia determinar sem gabarito.
- `startup_seconds`: construção da engine no processo; não mede boot nem cache frio do SO.
- RSS Linux é high-water mark do processo inteiro, incluindo rasterização; não
  confundir com tamanho incremental da engine. Child RSS é separado para Tesseract.
- Bundle incremental não medido (null); não existe bundle Windows nesta fase.

## Limites

Layouts com labels/linhas controladas não representam a diversidade fiscal real.
O scorer não é um parser de produção e pode penalizar divisão de label/valor em
linhas separadas feita pelo OCR. Não usar esse corpus sozinho para declarar
qualidade fiscal, readiness ou vencedor final. Precisamos de layouts espaciais,
mais negativos/ambiguidade e corpus de validação independente antes da escolha.

Bloqueio de rede usa Python audit hooks e tem autocheck. Não prova egress bloqueado
no código nativo/filho Tesseract; gate OS-level da FP-010 permanece pendente.

## Proveniência e licenças

- RapidOCR 3.9.2: Apache-2.0; PP-OCRv6 small/medium, fontes/hashes do
  `rapidocr/default_models.yaml` do wheel dessa versão.
- ONNX Runtime 1.24.2 CPU: MIT. OpenVINO não medido, sem necessidade comprovada.
- Tesseract 5 e tessdata_fast tag 4.1.0: Apache-2.0; por.traineddata com hash pinado.
- Small e classificador copiados do wheel; medium/por obtidos apenas no preparo.
- RapidOCR instancia classificador mesmo com uso desabilitado: seu modelo é
  validado e contado no tamanho. Nenhum font/download de visualização é usado.
- Paddle direto não incluído: o teste ainda precisa fechar small/medium/Tesseract;
  dependência adicional não resolveria os limites do corpus.
- Notices completos de redistribuição e bundle pertencem à FP-009/FP-010.

Fontes oficiais consultadas em 2026-09-28:
- https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml
- https://rapidai.github.io/RapidOCRDocs/latest/model_list/
- https://pypi.org/project/rapidocr/3.9.2/
- https://onnxruntime.ai/docs/api/python/api_summary.html
- https://tesseract-ocr.github.io/tessdoc/Data-Files.html

O corpus usa grafia sem acentos nos labels para isolar o primeiro gate de OCR.
Acentos, tabelas, documentos multipágina e campos lado a lado ainda precisam de
cobertura: não extrapolar esses resultados para NFS-e municipais reais.

O preparo valida os modelos obtidos; não efetua download dentro de inferência.
URLs upstream são fixadas em versão/tag e hashes locais são conferidos; a lista
de hashes está em engines.py e prepare_models.py. Não commitar os binários.

No Tesseract, startup_seconds mede a sondagem `--version`; cada amostra cria um
processo e carrega o modelo, custo incluído em seconds. RapidOCR mantém engine
carregada. Não comparar startup_seconds como se fossem o mesmo cold start.

## Corpus espacial v1

`spatial_corpus.py` gera seis documentos (sete páginas) com rótulos e valores
em caixas distintas: colunas trocadas, acentos, duas páginas, total ausente,
total duplicado e comprovante negativo. São 48 verificações, incluindo dez
ausências esperadas; não são 48 valores presentes.

```sh
PYTHONPATH=src:. python -m benchmarks.spatial_run --engine native --output native.json
PYTHONPATH=src:. python -m benchmarks.spatial_run --engine small --models /caminho/models --output spatial-small.json
PYTHONPATH=src:. python -m benchmarks.spatial_run --engine medium --models /caminho/models --output spatial-medium.json
PYTHONPATH=src:. python -m benchmarks.spatial_run --engine tesseract --models /caminho/models --output spatial-tesseract.json
```

Rodar sequencialmente. Default: 200 DPI. O localizador recebe somente texto e
caixas; gabarito entra depois da extração. Coordenadas são normalizadas para
pontos PDF; palavras TSV do Tesseract são agrupadas sem atravessar colunas.
O split development/evaluation é controlado pelo mesmo autor, portanto não
é validação externa independente. `review_oracle` continua sendo oráculo.
O localizador não é parser fiscal de produção. Resultados em RESEARCH-004.

Lição de reprodução: confirmar PDFium 5.13.0 antes de executar; a versão
pré-instalada no ambiente pode divergir do requisito. Não adaptar o teste
para mascarar uma divergência da dependência.

## Avaliar documentos locais autorizados

`benchmarks.local_run` aceita um manifesto externo e produz métricas sem valores
fiscais. Ver [guia de corpus local](../docs/LOCAL_CORPUS.md). Não commitar PDFs,
gabaritos ou resultados privados. O suporte a manifesto não certifica corpus
independente nem substitui a execução do gate pendente.
