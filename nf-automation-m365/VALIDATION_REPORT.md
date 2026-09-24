# VALIDATION_REPORT — Test Candidate 0.1.2.0

## Validação local
- ZIP integrity/open: PASS
- solution.xml parse: PASS
- customizations.xml parse: PASS
- workflow JSON parse: PASS
- trigger `For a selected file`: Request + ApiConnection: PASS
- trigger site/library concretos: PASS
- SHA-256 do ZIP 0.1.2.0: `8a00eb8181726f464d5a83bf3adac828c8c46967021216002704922b394e6bc2`

## Validação real no tenant
- import/update da 0.1.2.0: PASS
- ativação do fluxo imediato: PASS
- aparição em `Integrar → Fluxos`: PASS
- execução real em PDF: PASS
- criação de item na lista SharePoint: PASS
- segunda execução do mesmo PDF: PASS, sem duplicata observada

## Ainda não validado
- extração automática dos campos fiscais do PDF;
- atualização das colunas fiscais reais da lista;
- Desktop flow;
- concorrência Cloud/Desktop.

Resultado: T-003 e T-004 VALIDADAS.
