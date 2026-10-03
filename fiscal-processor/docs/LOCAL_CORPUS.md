# FP-004 — avaliação de corpus local

Ferramenta de desenvolvimento: `python -m benchmarks.local_run`. Não é a CLI
final do produto e não completa a seleção de OCR por si só.

## Preparar o corpus

Em pasta local autorizada, fora do repositório e de pastas sincronizadas, guardar
os PDFs e `manifest.json`. O gabarito é sensível como o próprio documento e deve
permanecer nessa máquina. Não anexar documentos empresariais ao chat/PR.

Estrutura do manifesto (valores ilustrativos sintéticos):

```json
{
  "version": 1,
  "cases": [
    {
      "pdf": "nota-01.pdf",
      "expected": {
        "type": "NFE",
        "number": "00123456",
        "series": "009",
        "date": "28/09/2026",
        "cnpj": "12.345.678/0001-95",
        "issuer": "OFICINA SÃO JOSÉ LTDA",
        "recipient": "COMÉRCIO FICTÍCIO SA",
        "amount": "112.000,00"
      }
    }
  ]
}
```

São obrigatórias as oito chaves. Usar `null` para ausência/ambiguidade esperada;
um documento não fiscal usa oito `null`. Strings são comparadas exatamente,
inclusive acentos, zeros e pontuação. Não ajustar o gabarito para aceitar o OCR.
Manifesto limitado a 1 MB e 1–200 documentos. Caminhos relativos, contidos na
pasta do manifesto; symlinks para fora e entradas repetidas são recusados.
Limites de páginas/pixels do adapter PDFium continuam aplicados.

## Executar

Instalar dependências e preparar modelos conforme `benchmarks/README.md` em
etapa separada. Criar previamente uma pasta local para os resultados.

```sh
python -m benchmarks.local_run --manifest /pasta/local/manifest.json --engine native --output /pasta/resultados/native.json
python -m benchmarks.local_run --manifest /pasta/local/manifest.json --engine small --models /pasta/modelos --output /pasta/resultados/small.json
python -m benchmarks.local_run --manifest /pasta/local/manifest.json --engine medium --models /pasta/modelos --output /pasta/resultados/medium.json
python -m benchmarks.local_run --manifest /pasta/local/manifest.json --engine tesseract --models /pasta/modelos --output /pasta/resultados/tesseract.json
```

Executar sequencialmente, mesmo manifesto imutável, mesmo DPI (default 200),
mesma máquina. Não reutilizar nomes de saída: arquivos existentes são preservados.
Native usa texto PDF; os demais rasterizam todas as páginas, mesmo se houver texto.

Saída JSON e checkpoint JSONL contêm índices ordinais, booleans por campo,
contagens, códigos fixos de falha e tempos; não contêm caminhos, nomes dos PDFs,
texto extraído nem valores do gabarito. Relacionar o índice ao manifesto somente
localmente. Falha de extração conta no denominador de oito verificações por caso.
`complete` significa término do lote, não sucesso de todos os documentos.
Exit code 0: lote concluído sem falhas de extração (pode haver divergências);
1: pelo menos uma extração falhou; 2: preparação/execução não concluída.
Um JSON vazio/interrompido não é relatório completo; consultar JSONL preservado.

Temporários rasterizados ficam em subpasta da pasta de resultados, removida no
encerramento normal, inclusive após falha por documento. Encerramento forçado do
processo/SO pode deixar temporários; inspecionar e limpar localmente nesse caso.

## Interpretar sem extrapolar

- Avalia OCR **e** localizador espacial estreito existente. Label desconhecido,
  tabela diferente ou texto fragmentado pode falhar mesmo com OCR correto.
- Não escolhe automaticamente a engine nem certifica independência do corpus.
- Evitar ajustar o localizador no conjunto reservado à avaliação. Mudanças de
  regras exigem outro conjunto de avaliação e registro da revisão testada.
- O audit hook bloqueia rede Python. Não comprova ausência de egress em código
  nativo/subprocessos; bloqueio pelo SO continua sendo gate FP-010.
- Antes de compartilhar métricas, revisar autorização e relatório. Esta ferramenta
  não envia nada; também não transforma documentos reais em dados públicos.

## Evidência desta implementação

69 testes PASS no Linux, incluindo PDFium real, erro por documento, divergência,
relatório sem valores, schema/caminhos e preservação de evidência existente.
Smoke CLI nativo e Tesseract: seis documentos sintéticos, 48/48 verificações cada. Corpus externo
independente ainda não foi fornecido/executado; nenhum documento empresarial usado.
