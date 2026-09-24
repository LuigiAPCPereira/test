# Requisitos e aceites — v0.3

- REQ-001: PDF novo na pasta de entrada cria no máximo um registro por identificador. Aceite: repetir o mesmo evento não cria segundo item.
- REQ-002: referências de site, biblioteca, pasta, lista e situação inicial são configuração transportável. Aceite: aparecem como variáveis de ambiente da Solution.
- REQ-003: usuário pode processar uma NF selecionada sem aguardar o polling. Aceite: fluxo “NF - Processamento Imediato” aparece na Solution e pode ser habilitado/testado.
- REQ-004: OS, validade e observações nunca são sobrescritas pelo intake. Aceite: fluxos de intake não escrevem nesses campos.
- REQ-005: extração fiscal automática deve recuperar data de emissão, emitente e valor antes de produção. Estado: aberto; engine de extração ainda não validado/licenciado.
- REQ-006: Desktop deve poder enriquecer o mesmo registro sem duplicar. Estado: planejado.
