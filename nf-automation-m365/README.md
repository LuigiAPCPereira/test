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
- `artifacts/NF_Automation_M365_v0.3_handoff.zip` — snapshot completo com fontes da Solution e candidates gerados.

## Segurança e operação

Não commitar credenciais, tokens ou segredos. OS, validade e observações são campos manuais e não devem ser sobrescritos pelo intake automático. Um pacote gerado localmente permanece `implementada não validada` até import e smoke no tenant.

## Próxima ação

Importar primeiro a Solution de teste isolada contida no snapshot v0.3, vincular a conexão corporativa do SharePoint e validar o fluxo `NF - Processamento Imediato - Candidate` antes de atualizar o fluxo original.
