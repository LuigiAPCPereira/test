# AGENTS.md — Fiscal Processor

## Entrypoint

Este subprojeto segue o Agent Development Protocol v2.2 quando a fonte canônica estiver acessível, e herda `ENGINEERING_DNA.md` e `FRONTEND_DNA.md` para decisões de arquitetura e interface.

Antes de trabalho substancial:
1. confirmar branch/HEAD e estado do repositório;
2. ler `docs/PRODUCT.md`, `docs/PRD.md`, `docs/DESIGN.md`, `docs/TASKLIST.md`, `docs/ROADMAP.md` e `docs/PROJECT_STATE.md`;
3. distinguir evidência, inferência e hipótese;
4. executar um bloco funcional verificável e atualizar o checkpoint pela tarefa ID.

## Regras de produto e segurança

- Runtime de produção é **local-only**.
- PDFs, imagens, texto extraído e campos fiscais **não podem sair da máquina**.
- Não usar LLM, API de IA, SaaS OCR, telemetria, analytics ou upload implícito.
- Dependências que baixem modelos em runtime devem ser configuradas para modo offline ou não entram no pacote.
- Testes versionados usam somente fixtures sintéticas/anonimizadas.
- Logs não armazenam texto integral da NF nem valores fiscais desnecessários.
- Nenhum segredo ou credencial é requisito do produto.
- SharePoint, Power Automate e conta Microsoft não pertencem ao runtime desta arquitetura.

## Invariantes de domínio

- Campos automáticos: tipo, número NF, série, data de emissão, emitente/prestadora, CNPJ, tomadora/destinatária, valor e estado de processamento.
- Campos manuais do usuário: número da OS, validade e observações.
- O processador nunca sobrescreve campos manuais.
- Duplicidade do mesmo PDF é detectada por SHA-256 do conteúdo, independentemente do nome do arquivo.
- Ausência/ambiguidade vira estado explícito de revisão; nunca preencher por suposição.

## Arquitetura

Preferir dependências apontando para dentro:

```text
Presentation
    |
    v
Application
    |
    v
Domain
    ^
    |
Adapters
```

PDF/OCR/Excel/UI são boundaries. O domínio não importa bibliotecas de PDF, OCR, planilha ou GUI.

Evitar registries genéricos, plugin systems e DI frameworks sem necessidade concreta. O wiring vive em um composition root pequeno.

## Validação

Distinguir sempre:
- implementado;
- validado;
- não validado;
- desconhecido.

Build não prova runtime Windows. Pacote não prova execução sem privilégios. Smoke corporativo exige evidência na máquina autorizada.
