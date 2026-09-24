# SESSION_LOG

## 2026-09-24 — Fonte real da Solution adquirida
- Confirmado: Solution `ControledenotasFiscais` v1.0.0.1, Managed=0, publisher `cnf`, fluxo `NF - Cadastro Inicial` e connection reference SharePoint.
- Defeito observado: `Get items` usava `$filter: IDdoarquivo`, sem predicado OData.
- Alteração preparada: candidate 1.1.0.0 parametrizado + correção + modo imediato.
- Não confirmado: import/execução real do candidate.
- Próxima tarefa: T-003/T-004 smoke no tenant.

## 2026-09-24 — Continuidade no GitHub
- Repositório confirmado: `LuigiAPCPereira/test`.
- Branch de trabalho: `feat/nf-automation-m365-v0.3`.
- Escopo preservado em `nf-automation-m365/`; arquivos pré-existentes do repositório não foram alterados.

## 2026-09-24 — Regressão do gatilho imediato observada no tenant
- Import do Test Candidate 0.1.0.0: confirmado.
- Ativação do fluxo imediato: falhou antes de qualquer execução.
- Erro: `recurrence` ausente/inválida no trigger `Para_um_arquivo_selecionado`.
- Causa: trigger manual serializado incorretamente como `OpenApiConnection`.
- Evidência externa consultada: definição de Solution real usa `Request + ApiConnection` para `ForASelectedFileHybridTrigger`.
- Correção: 0.1.1.0 gerada e validada estaticamente; runtime ainda pendente.
- Próxima ação: reimportar 0.1.1.0 e repetir ativação.

## 2026-09-24 — Fluxo imediato ativo, mas ausente no menu SharePoint
- 0.1.1.0: ativação confirmada no tenant.
- SharePoint `Integrar → Fluxos`: apenas fluxo interno `Solicitar liberação`; candidate ausente.
- Ambiente observado: default.
- Correção 0.1.2.0: gatilho `For a selected file` vinculado explicitamente ao site e GUID da biblioteca de teste; ações continuam parametrizadas.
- Estado: correção implementada, reimport/visibilidade pendentes.

## 2026-09-24 — Smoke real do fluxo imediato concluído
- Test Candidate 0.1.2.0 importada no ambiente corporativo.
- `NF - Processamento Imediato - Candidate` ativado com sucesso.
- Fluxo apareceu no SharePoint em `Integrar → Fluxos`.
- Primeira execução em PDF de teste criou um item em `Controle de Notas Fiscais`.
- Segunda execução sobre o mesmo PDF não criou item duplicado.
- Resultado: T-003 e T-004 validadas.
- Próxima ação: T-005, avaliar/validar engine de extração dos campos fiscais.

## 2026-09-24 — AI Builder disponível, sem capacidade
- Ação `Processar faturas` encontrada no ambiente.
- Fluxo de teste manual com entrada de arquivo foi executado.
- A ação falhou informando ausência de capacidade de Crédito do Copilot ou créditos do AI Builder no ambiente.
- Nenhum trial, compra ou mudança administrativa foi realizada.
- Consequência: AI Builder não é engine utilizável neste ambiente no estado atual.
- Próximo teste de T-005: Power Automate Desktop, extração nativa de texto de PDF.

## 2026-09-24 — Extração local de PDF validada
- Power Automate Desktop executou `Selecionar arquivo → Extrair texto do PDF → Exibir mensagem`.
- PDF digital foi lido sem AI Builder.
- Texto bruto preservou informações fiscais suficientes para parsing: número da NF, série, fornecedor, CNPJ e valor total.
- Exemplos observados: `004.241.885`, série `99`, `BAHIANA DISTRIBUIDORA DE GAS LTDA`, `46.395.687/0004-55`, `112.000,00`.
- Próxima ação: parser estruturado usando ações de texto/regex do PAD.
