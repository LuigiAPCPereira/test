# ADR-001 — Processamento híbrido Cloud + Desktop

- Estado: aceita
- Autoridade: decisão do usuário nesta conversa.
- Decisão: manter processamento automático na nuvem e adicionar caminhos imediatos (arquivo selecionado e Desktop), todos convergindo para a mesma lista SharePoint.
- Motivo: automação em nuvem é conveniente, mas o gatilho periódico pode atrasar; Desktop oferece resposta imediata.
- Consequência: idempotência e configuração compartilhada são obrigatórias para evitar duplicatas e divergência.
