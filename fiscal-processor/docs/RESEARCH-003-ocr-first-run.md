# FP-004 — benchmark inicial, 2026-09-28 UTC

**Estado: implementado / parcialmente validado. Não é seleção final nem aceite de qualidade fiscal.**

## Ambiente e procedimento
Python 3.12.14, Linux x86_64/glibc 2.39, CPU reportada AMD EPYC 9V74
(ambiente virtualizado compartilhado; não representa PC/Windows alvo).
RapidOCR 3.9.2 + ONNX Runtime 1.24.2 CPU, intra/inter threads 1; Tesseract 5
com por.traineddata tessdata_fast 4.1.0. Dependências observadas pinadas em
benchmarks/requirements.txt, hashes de modelos verificados antes de inferir.

Corpus synthetic-labels-v1: três documentos fiscais simplificados, oito campos,
quatro DPIs, cinco degradações, uma página branca negativa. Nenhuma NF real usada.
Ground truth/gerador e scorer versionados. Somente labels exatos e um candidato
por campo são aceitos; não existe busca pelo valor esperado para "ajudar" OCR.

## Comparação comum: 150 DPI

| Engine | Campos exatos | Casos com divergência | Mediana por página | Bytes dos modelos |
| --- | --- | --- | --- | --- |
| small | 120/120 | 0/15 | 1.847 s | 31,749,509 |
| medium | 120/120 | 0/15 | 8.256 s | 139,334,970 |
| tesseract | 112/120 | 6/15 | 0.299 s | 1,982,756 |

## Cobertura ampliada
- Small: 60 casos, **476/480** campos exatos; 3 casos com divergência.
- Tesseract: 60 casos, **459/480** campos exatos; 18 casos com divergência.
- Medium: 15 casos/150 DPI, **120/120** campos exatos. Rodada completa foi
  interrompida pelo custo de execução; resultados dessa tentativa descartados.
- Nenhuma engine produziu texto na página branca. Um negativo não prova ausência
  de falsos positivos em documentos desconhecidos.
- `review` é divergência detectada **com gabarito**, não a capacidade do produto
  de detectar seus próprios erros.

## Decisão por evidência
Small permanece candidato preferido: neste recorte oferece mais exatidão que
Tesseract, sem o custo do medium (que não ganhou exatidão nos 15 casos comuns).
**Não empacotar duas engines.** Não promover a engine a seleção final com este
corpus: faltam layout espacial realista e validação independente. FP-004 não
satisfaz ainda o gate de FP-005; parsers/CLI/GUI não foram antecipados.

Paddle direto e OpenVINO não incluídos: o limite atual é cobertura/aceite do
benchmark, não ausência de backends. Adicioná-los agora não resolveria esse limite.

## Performance e limites
Latências exploratórias, uma passagem, sem isolamento exclusivo de CPU.
A primeira rodada small teve breve sobreposição com tentativa medium cancelada;
não usar esses tempos para SLA ou razão precisa de aceleração. A rodada medium
reduzida e o Tesseract foram sequenciais. Medidas por amostra estão nos JSONs.
RapidOCR startup mede inicialização da engine, não cold boot/cache do SO.
No Tesseract, startup mede apenas --version; cada página inclui novo processo
e carregamento do modelo na latência. Startup entre essas engines não é equivalente.
RSS inclui rasterização/degradações do harness, e **não** mede memória incremental
do OCR. A geração de ruído aloca arrays grandes; precisa ser isolada no próximo
benchmark de memória. RSS Linux high-water observada: small 1.486 GiB, medium
1.318 GiB, Tesseract processo pai 0.871 GiB; não comparar com bundle.
Tamanho do bundle: **não medido**. Model bytes incluem classificador carregado pelo
RapidOCR mesmo com uso de orientação desabilitado. Não são tamanho do executável.

## Privacidade
Arquivos de modelos locais com SHA-256 pinado; ausência/corrupção falha antes da
construção da engine. Preparo de modelos é comando explícito separado, com rede.
Inferência executada sob Python audit hook bloqueando conexões/DNS e autocheck.
Não foi demonstrado egress OS-level de código nativo/filho: FP-010 pendente.
Nenhum texto integral fica no relatório; apenas acertos/erros de dados sintéticos.

## Gates e continuidade
52 testes PASS; ruff check e format --check PASS; mypy src PASS; compileall PASS.
Novos testes cobrem scorer exato, centavos, labels duplicados, PDF sintético real,
modelo ausente/corrompido e cleanup de handles PDF em falhas.

Próxima ação FP-004: ampliar corpus para DANFE em tabelas, múltiplas NFS-e com
campos lado a lado, acentos, páginas múltiplas e negativos; avaliar associação
espacial sem usar gabarito para selecionar texto; separar geração e RSS/inferência;
repetir candidatos em corpus independente e fixar uma engine primária por aceite.
Gates de Windows/máquina corporativa permanecem não validados.

Fontes técnicas oficiais e comandos reproduzíveis: ../benchmarks/README.md.
Implementação sobre 6b7605ff1398b5c0cfbd85ca4895d2ed631e382a.
Commit deste bloco: identificado no Git por FP-004: add offline synthetic fiscal OCR benchmark.
