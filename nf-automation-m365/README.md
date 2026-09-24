# NF Automation M365

Automação híbrida para controle de notas fiscais em SharePoint/Power Automate.

## Estado

- Cloud automático: existente no tenant; candidate parametrizado preparado.
- Cloud imediato: candidate implementado, ainda não validado no tenant.
- Desktop: planejado, ainda não implementado.
- Extração fiscal: pendente de validação de engine/licença e de amostras reais autorizadas.

## Estrutura

- `docs/` — produto, requisitos, arquitetura, TASKLIST, roadmap, checkpoint, histórico e decisão híbrida.
- `deployment-settings.template.json` — valores de ambiente e referência de conexão; não contém credencial.
- `PATCH_SUMMARY.md` — diferenças preparadas em relação à Solution recebida.
- `VALIDATION_REPORT.md` — validação local do candidate.
- `solution/test-candidate/` — fonte Git-native da Solution isolada de teste.
- `dist/ControledenotasFiscais_TestCandidate_0_1_0_0.zip` — ZIP já pronto para importar no Power Automate; não exige Python no PC corporativo.
- `scripts/package_test_candidate.py` — alternativa para recriar o ZIP a partir da fonte versionada.

## Empacotamento

Na raiz de `nf-automation-m365/`:

```bash
python scripts/package_test_candidate.py
```

Isso gera `dist/ControledenotasFiscais_TestCandidate_0_1_0_0.zip`.

## Segurança e operação

Não commitar credenciais, tokens ou segredos. OS, validade e observações são campos manuais e não devem ser sobrescritos pelo intake automático. Um pacote gerado localmente permanece `implementada não validada` até import e smoke no tenant.

## Próxima ação

Gerar/importar primeiro a Solution de teste isolada, vincular a conexão corporativa do SharePoint e validar o fluxo `NF - Processamento Imediato - Candidate` antes de atualizar o fluxo original.
