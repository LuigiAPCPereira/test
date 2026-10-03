# ADR-001 — Núcleo local-only em Python

- **Status:** aceito para v0.1
- **Data:** 2026-09-27

## Contexto

O protótipo anterior usou Power Automate/SharePoint. Testes reais mostraram que PDF textual pode ser extraído localmente, enquanto alguns PDFs exigem OCR. O usuário também precisa desenvolver fora do Windows e não quer que documentos fiscais saiam da máquina.

## Decisão

Construir um produto separado, local-only, com núcleo Python.

O runtime:
- lê PDFs do filesystem;
- extrai texto localmente;
- usa OCR local apenas quando necessário;
- classifica e parseia NF-e/NFS-e deterministicamente;
- valida e normaliza campos;
- atualiza Excel local;
- não usa SharePoint, Power Automate, LLM, OCR SaaS, analytics ou telemetria.

A distribuição Windows inicial será portátil, preferindo `onedir`/ZIP antes de `onefile`.

## Consequências

### Positivas
- privacidade forte por arquitetura;
- desenvolvimento possível em Linux;
- testes automatizados sem tenant Microsoft;
- menor vendor lock-in;
- parser e regras fiscais tornam-se código testável;
- build Windows pode ocorrer em CI sem documentos reais.

### Custos
- OCR, parsing e empacotamento passam a ser nossa responsabilidade;
- executável não assinado pode ser bloqueado por política corporativa;
- NFS-e varia por município e exigirá parsers/evidências incrementais.

## Não decidido neste ADR

- engine OCR final;
- toolkit de GUI final;
- assinatura de código;
- regras futuras de movimentação de arquivos.

Esses pontos exigem benchmark ou evidência externa antes da decisão.
