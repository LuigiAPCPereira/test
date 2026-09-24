# VALIDATION_REPORT — Test Candidate 0.1.2.0

## Evidência no tenant
- 0.1.0.0: importou, mas o gatilho imediato não ativou.
- 0.1.1.0: ativou com sucesso.
- 0.1.1.0: não apareceu em `Integrar → Fluxos` da biblioteca alvo.

## Hipótese corrigida em 0.1.2.0
O gatilho manual estava vinculado a site e biblioteca por environment variables. O SharePoint precisa associar o fluxo à biblioteca correta para listá-lo no menu. Nesta revisão, apenas os parâmetros do gatilho `ForASelectedFileHybridTrigger` ficam concretos:
- site: `https://grupoultracloud.sharepoint.com/teams/Teste728`
- biblioteca: `bdcd1f39-316c-41d4-8f78-cbe6be5ac8b0`

As ações do fluxo continuam usando environment variables.

## Validação local
- ZIP integrity/open: PASS
- solution.xml parse: PASS
- customizations.xml parse: PASS
- workflow JSON parse: PASS
- trigger: Request + ApiConnection: PASS
- trigger recurrence: ausente
- trigger site/library concretos: PASS
- SHA-256: `8a00eb8181726f464d5a83bf3adac828c8c46967021216002704922b394e6bc2`

## Ainda não validado
- import/update da 0.1.2.0;
- aparição em `Integrar → Fluxos`;
- execução real;
- deduplicação real.

Resultado: IMPLEMENTADA NÃO VALIDADA.
