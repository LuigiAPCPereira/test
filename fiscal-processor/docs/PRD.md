# Requisitos e aceites — Fiscal Processor v0.1

- **Escopo:** POC local-only evoluindo para aplicativo Windows portátil.
- **Estado:** arquitetura aprovada para implementação; runtime ainda não implementado.

| ID | Requisito verificável | Critério de aceite observável | Estado |
| --- | --- | --- | --- |
| REQ-001 | Processar PDFs sem rede | teste de processamento passa com egress bloqueado e sem chamadas HTTP/DNS do produto | aberto |
| REQ-002 | Extrair texto nativo quando disponível | PDF sintético textual produz texto e campos esperados sem OCR | aberto |
| REQ-003 | Fazer fallback OCR local | PDF sintético rasterizado produz texto/campos sem serviço externo | aberto |
| REQ-004 | Reconhecer NF-e/DANFE e NFS-e | corpus sintético cobre ambos e retorna tipo correto ou revisão explícita | aberto |
| REQ-005 | Extrair campos fiscais alvo | número, série, data, emitente/prestadora, CNPJ, tomadora/destinatária e valor validados por fixtures | aberto |
| REQ-006 | Não inventar dados | campo ausente/ambíguo permanece vazio e gera flag de revisão | aberto |
| REQ-007 | Ser idempotente | processar o mesmo conteúdo duas vezes não cria linha duplicada | aberto |
| REQ-008 | Preservar campos manuais | reprocessamento nunca altera OS, validade ou observações existentes | aberto |
| REQ-009 | Gerar/atualizar Excel local | workbook abre e mantém contrato de colunas, tipos e campos manuais | aberto |
| REQ-010 | Falhar com segurança quando Excel estiver bloqueado | operação não corrompe arquivo e informa ação ao usuário | aberto |
| REQ-011 | Distribuir sem Python instalado | smoke do pacote Windows em máquina limpa executa sem instalação de Python | aberto |
| REQ-012 | Não exigir privilégio administrativo no caminho nominal | pacote portátil executa a partir de pasta do usuário; smoke corporativo ainda depende de política local | aberto |
| REQ-013 | Logs minimizam dados sensíveis | logs contêm estado, duração, códigos de erro e hash técnico; não contêm texto integral da NF | aberto |
| REQ-014 | UI representa estados reais | inicial, vazio, processando, parcial/revisão, sucesso e erro são distintos e acessíveis | aberto |
| REQ-015 | Performance é medida antes de otimizar | benchmark registra tempo de extração textual, OCR e lote em hardware identificado; limiar será definido após baseline | aberto |

## Falhas seguras

- PDF corrompido → marcar falha do documento; continuar lote quando seguro.
- PDF sem texto e OCR indisponível → revisão/erro explícito; não gerar campos fictícios.
- Excel aberto/bloqueado → não substituir arquivo parcialmente.
- Dependência/modelo OCR ausente → falhar fechado; não baixar silenciosamente.
- Documento duplicado → não duplicar linha.

## Itens deliberadamente abertos

- Engine OCR final: Tesseract vs RapidOCR/ONNX será decidido por benchmark local.
- Framework visual final: decisão após POC do core, preservando o contrato de frontend.
- Assinatura de código/whitelisting corporativo: depende de TI/política da empresa e não é presumida.
