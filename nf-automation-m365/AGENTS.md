# AGENTS.md — Controle de Notas Fiscais

Este subprojeto segue o Agent Development Protocol v2.2 e o Engineering DNA quando essas fontes estiverem efetivamente acessíveis. Não afirmar leitura da fonte canônica quando ela não estiver disponível no ambiente atual.

Fontes locais de continuidade: `docs/PRODUCT.md`, `docs/PRD.md`, `docs/DESIGN.md`, `docs/TASKLIST.md`, `docs/ROADMAP.md`, `docs/PROJECT_STATE.md`, `docs/SESSION_LOG.md`.

Regras críticas:
- não inventar contratos de SharePoint, licenças, nomes internos de colunas ou resultados de import;
- preservar OS, validade e observações;
- tratar configuração como contrato;
- qualquer pacote gerado localmente é “implementado não validado” até smoke no tenant;
- T-IDs do TASKLIST orientam checkpoint e handoff;
- credenciais, tokens e segredos nunca entram no repositório.
