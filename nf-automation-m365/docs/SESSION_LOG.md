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

## 2026-09-24 — Parser completo Desktop preparado
- Criado `desktop/NF_Parser_Completo_Apos_Extracao.robin` para colar diretamente no designer do Power Automate Desktop.
- Entrada: `ExtractedPDFText`.
- Saída: objeto `NF` com os campos fiscais alvo e normalizações ISO/numéricas.
- Cobertura inicial: NF-e/DANFE e NFS-e, baseada nos formatos reais já observados no projeto.
- O parser sinaliza campos ausentes em vez de preencher por suposição.
- Validação estática dos padrões foi feita contra amostras representativas transcritas das NFs observadas; execução real do bloco no PAD ainda pendente.
- Ação `Atualizar item` não foi gerada porque os nomes internos das colunas fiscais do SharePoint ainda não foram confirmados.

## 2026-09-24 — Correção de compatibilidade do parser PAD
- Ao colar o parser, o designer reportou: módulo `Scripting`/ação `RunPowershellScript` não encontrado.
- A variável `ParserJson` ficou ausente como erro em cascata.
- Causa: namespace interno incorreto no bloco Robin gerado.
- Correção: `System.RunPowershellScript`.
- O acesso ao SharePoint corporativo não será conectado ao ChatGPT; nomes internos de colunas serão obtidos por artefato/export autorizado.
- Próxima validação: colar a revisão corrigida e executar novamente.

## 2026-09-24 — Robin incompatível com ação PowerShell do tenant
- V2 Robin também falhou: módulo `System` / ação `RunPowershellScript` não reconhecida no importador.
- `ParserJson` ausente foi erro em cascata.
- A documentação oficial confirma que a ação visual `Executar script do PowerShell` existe no PAD; o problema é o identificador Robin/portabilidade, não a capacidade de script em si.
- Criado `desktop/NF_Parser_Completo.ps1`.
- Criado `desktop/PAD_MANUAL_SETUP.md` com montagem manual da única ação problemática.

## 2026-09-24 — Removida dependência de clipboard
- Execução manual do parser retornou `O PDF não retornou texto`, apesar de `ExtractedPDFText` já ter sido validado anteriormente.
- Diagnóstico: `Get-Clipboard -Raw` não recebeu o texto no processo PowerShell.
- Correção: o script usa `%ExtractedPDFText%` diretamente, recurso suportado oficialmente nas scripting actions do PAD.

## 2026-09-24 — Causa da falha parcial identificada
- O parser recebeu texto e classificou corretamente o documento como `NFE`, mas todos os campos ficaram vazios.
- Causa: o arquivo `.ps1` preservava escapes do formato Robin (`\\s`, `\\d`, `\\b` etc.). Em PowerShell/regex standalone esses escapes deveriam ter uma única barra.
- Correção aplicada globalmente em `desktop/NF_Parser_Completo.ps1`: 234 ocorrências normalizadas.
- Próxima validação: reexecutar na mesma NF sem alterar as demais ações do fluxo.

## 2026-09-24 — Segundo layout: NFS-e municipal Salvador
- NF-e/DANFE anterior passou com `Status: OK` e todos os campos alvo preenchidos.
- Segunda amostra visual é uma NFS-e municipal da Prefeitura de Salvador, com estrutura diferente da NFS-e de Teresina considerada inicialmente.
- Adicionados fallbacks por seção para número, prestador/CNPJ, tomador e valor total.
- Validação runtime da nova amostra: pendente.

## 2026-09-24 — PDF sem camada textual: OCR necessário
- NFS-e Salvador continuou retornando `O PDF não retornou texto` mesmo com parser atualizado.
- Como a etapa `Extrair texto do PDF` já funcionou em outra NF e aqui retorna vazio, o documento deve ser tratado como PDF sem texto copiável / imagem.
- Definido fallback: `Extrair imagens do PDF` → Windows OCR (Português) → concatenar em `ExtractedPDFText` → reutilizar o mesmo parser.
- Guia: `desktop/PAD_OCR_FALLBACK.md`.
- Estado: implementado em documentação, runtime OCR pendente.
