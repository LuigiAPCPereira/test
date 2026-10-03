# Produto — Fiscal Processor Local

## Identidade

- **Nome de trabalho:** Fiscal Processor
- **Propósito:** reduzir digitação manual no controle de notas fiscais brasileiras recebidas em PDF.
- **Usuário principal:** colaborador que recebe PDFs de NF-e/DANFE e NFS-e e precisa consolidar os dados em uma planilha Excel.
- **Jornada principal:** selecionar uma pasta de PDFs → processar localmente → revisar exceções → abrir/entregar a planilha gerada.

## Escopo atual

O produto processa localmente PDFs e produz/atualiza um arquivo `.xlsx` com:
- tipo do documento;
- número da NF;
- série;
- data de emissão;
- empresa emitente/prestadora;
- CNPJ;
- empresa tomadora/destinatária;
- valor;
- situação de processamento;
- motivo de revisão quando aplicável;
- número da OS, validade e observações como campos manuais preservados.

## Restrições centrais

- Zero dependência de SharePoint, Power Automate ou login corporativo para o runtime.
- Zero envio de documentos ou dados fiscais a serviços externos.
- Sem LLM e sem OCR em nuvem.
- OCR, quando necessário, roda localmente.
- O aplicativo final deve poder ser distribuído para Windows sem exigir Python instalado.
- Objetivo inicial de distribuição: pacote portátil `onedir`/ZIP, sem instalador e sem privilégios administrativos.
- Desenvolvimento deve funcionar em Linux; CI pode produzir artefato Windows sem incluir documentos reais.

## Fora do escopo da v0.1

- Integração ERP.
- E-mail automático.
- SharePoint/OneDrive.
- Sincronização em nuvem.
- Alteração dos PDFs originais.
- Inferência generativa/LLM.
- Auto-preenchimento de número da OS, validade ou observações.
- Serviço em background/Windows Service.
- Atualização automática do aplicativo.

## Verdade operacional

- O Excel é o artefato operacional entregue ao usuário.
- Campos automáticos pertencem ao processador.
- Campos manuais pertencem ao usuário e nunca são sobrescritos.
- O histórico do protótipo Microsoft 365 permanece separado e não é dependência desta arquitetura.
