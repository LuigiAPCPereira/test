# Arquitetura — Fiscal Processor v0.1

## Estado

Arquitetura aceita para implementação. Componentes abaixo ainda não implicam código existente.

## Fluxo principal

```text
Pasta escolhida pelo usuário
          |
          v
Descoberta de PDFs
          |
          v
SHA-256 do conteúdo ---------> deduplicação pelo workbook
          |
          v
PDFium: texto nativo por página
          |
     texto útil?
      /       \
    sim       não
     |         |
     |         v
     |     render da página
     |         |
     |         v
     |      OCR local
     |         |
     +----+----+
          v
Documento normalizado
          |
          v
Classificação explícita
   NF-e / NFS-e / desconhecido
          |
          v
Parser determinístico
          |
          v
Normalização + validação
          |
          v
OK / REVISAR / FALHA
          |
          v
Merge no Excel local
          |
          v
Save atômico
```

## Dependency direction

```text
Presentation
    |
    v
Application / Use cases
    |
    v
Domain
    ^
    |
Adapters: PDF / OCR / Excel / Filesystem
```

O domínio não importa GUI, PDFium, OCR, openpyxl ou filesystem.

## Componentes e ownership

| Componente | Faz | Não faz |
| --- | --- | --- |
| Presentation | mostra pasta, progresso, resultados e revisão | não parseia NF, não escreve Excel diretamente |
| ProcessBatch | coordena lote, cancelamento e progresso | não conhece detalhes de PDF/OCR |
| ProcessDocument | coordena uma NF e decide fallback | não implementa engine externa |
| PDF adapter | extrai texto/posições e renderiza páginas | não decide campos fiscais |
| OCR adapter | retorna tokens/texto/qualidade local | não classifica documento |
| Classifier | identifica NF-e/NFS-e/desconhecido por evidências | não acessa filesystem |
| Fiscal parsers | produzem candidatos de campos | não gravam planilha |
| Validators | CNPJ, datas, dinheiro e invariantes | não fazem I/O |
| Excel adapter | carrega, faz merge e salva workbook | não decide regras fiscais |
| Local log | registra estado técnico mínimo | não armazena texto integral da NF |

## Estrutura proposta

```text
fiscal-processor/
├── src/fiscal_processor/
│   ├── domain/
│   │   ├── invoice.py
│   │   ├── fields.py
│   │   ├── status.py
│   │   └── validation.py
│   ├── application/
│   │   ├── process_document.py
│   │   └── process_batch.py
│   ├── adapters/
│   │   ├── pdf/pdfium.py
│   │   ├── ocr/
│   │   ├── excel/openpyxl_store.py
│   │   └── filesystem/input_folder.py
│   ├── parsers/
│   │   ├── nfe_danfe.py
│   │   ├── nfse_generic.py
│   │   └── nfse_salvador.py
│   ├── presentation/
│   └── composition.py
├── tests/
│   └── fixtures/
└── docs/
```

Não criar plugin system ou registry genérico. A lista de classificadores/parsers é explícita no composition root.

## Modelo de domínio

Resultado mínimo por documento:

- `source_sha256`
- `source_filename`
- `document_type`: NFE | NFSE | UNKNOWN
- `invoice_number`
- `series`
- `issue_date`
- `issuer_name`
- `issuer_cnpj`
- `recipient_name`
- `amount` como `Decimal`
- `extraction_mode`: NATIVE_TEXT | OCR | MIXED
- `status`: OK | REVIEW | FAILED
- `quality_flags[]`
- `parser_id`

Não expor um "confidence score" inventado. Preferir flags verificáveis como:
- `MISSING_SERIES`
- `INVALID_CNPJ`
- `AMBIGUOUS_AMOUNT`
- `OCR_LOW_QUALITY`
- `UNSUPPORTED_LAYOUT`

## PDF

### Seleção para POC

`pypdfium2` é o candidato selecionado para a POC porque cobre:
- extração de texto;
- acesso a informações posicionais;
- renderização da página inteira;
- Windows/Linux/macOS;
- licença Apache-2.0/BSD-3-Clause no wrapper, com PDFium sob licença BSD-style e avisos de terceiros a redistribuir.

PyMuPDF não é selecionado para a base da v0.1 porque sua distribuição é AGPL ou comercial, gerando atrito desnecessário para um aplicativo empresarial fechado.

### Estratégia

Fallback é por página, não apenas por documento:
1. extrair texto;
2. avaliar utilidade do texto;
3. renderizar + OCR somente se insuficiente;
4. unir evidências.

O predicado de "texto útil" será calibrado por testes; não assumir que string não vazia significa conteúdo confiável.

## OCR

Boundary real e substituível. Candidatos de benchmark:
- Tesseract 5 + `por.traineddata`;
- RapidOCR + ONNX Runtime com modelo português/multilíngue empacotado.

Regras:
- sem download de modelo em runtime;
- modelos/binaries pinados e empacotados;
- hashes/verificação de artefatos no build;
- nenhum OCR remoto.

A POC usará small provisoriamente conforme ADR-002. A validação representativa
de FP-004 ocorrerá após pacote Windows; nenhuma segunda engine será distribuída
sem evidência que justifique.

## Parsing

Estratégia híbrida determinística:
1. labels/âncoras e coordenadas quando disponíveis;
2. seções de layout;
3. regex como fallback;
4. validação semântica.

NF-e/DANFE terá parser próprio. NFS-e terá parser genérico e módulos municipais apenas quando variação real justificar.

## Excel

Arquivo de trabalho padrão: `Controle_Notas_Fiscais.xlsx`.

Colunas visíveis propostas:
- Arquivo
- Tipo
- Número da NF
- Série
- Data de emissão
- Empresa prestadora/emitente
- CNPJ
- Empresa tomadora/destinatária
- Valor
- Número da OS
- Validade
- Observações
- Situação
- Motivo da revisão

Colunas técnicas ocultas:
- `_sha256`
- `_extraction_mode`
- `_parser_id`
- `_processed_at`

Regras:
- `_sha256` é a chave de idempotência;
- duplicata não cria nova linha;
- reprocessamento explícito pode atualizar apenas campos automáticos;
- Número da OS, Validade e Observações nunca são sobrescritos;
- salvar em arquivo temporário e substituir somente após sucesso;
- se Excel bloquear o arquivo, falhar sem corromper.

`openpyxl` é o candidato da v0.1 por ler e escrever XLSX e usar licença MIT.

## Segurança e privacidade

- Sem cliente HTTP no caminho nominal.
- Sem credencial.
- Sem telemetria.
- Sem upload.
- Temporários de OCR preferencialmente em memória; quando disco for necessário, usar pasta temporária local e limpeza garantida.
- Logs: hash técnico, nome/ID do arquivo quando necessário, tempos, status e códigos de erro; nunca dump de texto fiscal.
- Teste de egress faz parte do gate.
- Limites de tamanho/páginas serão configuração validada.
- PDF corrompido não interrompe lote inteiro quando a falha estiver isolada.

## Performance

Hot path:
1. hash;
2. extração textual;
3. OCR apenas quando necessário;
4. parsing;
5. merge do workbook.

Não introduzir paralelismo antes do baseline. Se OCR dominar o lote, avaliar concorrência limitada por CPU após profiling.

Métricas de benchmark:
- tempo por PDF textual;
- tempo por página OCR;
- tempo do lote;
- pico aproximado de memória;
- tamanho do pacote;
- cold start.

Sem metas fictícias antes da medição.

## Empacotamento

Primeira entrega Windows:
- PyInstaller `onedir`;
- ZIP portátil;
- sem installer;
- sem Python no destino;
- build em runner Windows do CI;
- nenhum PDF real no CI.

`onefile` fica fora da v0.1 inicial até o `onedir` estar validado, por startup/debug e comportamento de antivírus.

## Fronteira de frontend

O contrato visual é independente do toolkit:
- uma janela principal;
- seletor de pasta;
- ação primária "Processar";
- progresso real;
- tabela de resultados/revisão;
- ação "Abrir planilha";
- estados inicial, vazio, processando, parcial, sucesso e erro distintos.

A escolha de toolkit ocorrerá após a POC do core. Não usar o frontend para ocultar estados desconhecidos ou erros.

